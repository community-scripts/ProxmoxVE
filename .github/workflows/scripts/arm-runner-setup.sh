#!/usr/bin/env bash
# Turns a GitHub-hosted arm64 runner (ubuntu-24.04-arm) into a throwaway Incus
# test host for pve-run-script.sh (PLATFORM=incus): the same layout as
# incus-ci-host-setup.sh, minus what a VM that lives for one job does not need
# (services, sweeper, runner registration). Run with sudo.
#
# The runner is a fresh VM per job and is discarded afterwards; nothing here
# has to be undone.

set -euo pipefail

NET_ADDR=10.98.0.1
NET_CIDR=10.98.0.0/24
SERVE_ROOT=/srv/ci
SERVE_PORT=18080
start=$(date +%s)

# --- Incus ----------------------------------------------------------------------
# Ubuntu 24.04's own incus is 6.0.0, which lacks `-f csv,noheader`; the engine
# then finds no storage pool. Zabbly (the Incus maintainers' packages) has the
# current 6.0 LTS, as Debian 13 does.
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.zabbly.com/key.asc -o /etc/apt/keyrings/zabbly.asc
# The key Zabbly publishes in its install instructions, not whatever the
# server returns today.
gpg --show-keys --with-colons /etc/apt/keyrings/zabbly.asc 2>/dev/null |
  awk -F: '/^fpr/ {print $10; exit}' | grep -qx 4EFC590696CB15B87C73A3AD82CC8797C838DCFD ||
  { echo "::error::unexpected Zabbly signing key"; exit 1; }
# Only the Incus packages may come from there; everything else stays Ubuntu's.
printf '%s\n' 'Package: *' 'Pin: origin pkgs.zabbly.com' 'Pin-Priority: 1' '' \
  'Package: incus* liblxc* lxcfs* qemu* edk2*' 'Pin: origin pkgs.zabbly.com' 'Pin-Priority: 600' \
  >/etc/apt/preferences.d/zabbly
printf '%s\n' 'Enabled: yes' 'Types: deb' 'URIs: https://pkgs.zabbly.com/incus/lts-6.0' \
  "Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")" 'Components: main' \
  "Architectures: $(dpkg --print-architecture)" 'Signed-By: /etc/apt/keyrings/zabbly.asc' \
  >/etc/apt/sources.list.d/zabbly-incus-lts-6.0.sources
# Each slow step has its own limit, so a hang names itself in the log instead
# of holding the PR report until the job times out.
step() { local t=$1; shift; timeout "$t" "$@" || { echo "::error::'$*' failed or hung (limit ${t})"; return 1; }; }
# What the runner's network looks like when apt can't get through.
netdiag() {
  echo "::group::Network on this runner"
  resolvectl status 2>&1 | grep -E 'DNS Servers|Current DNS|resolv.conf mode' || cat /etc/resolv.conf
  local h
  for h in ports.ubuntu.com pkgs.zabbly.com github.com; do
    echo "$h -> $(timeout 10 getent ahostsv4 "$h" | awk '{print $1; exit}')"
    timeout 15 curl -s -o /dev/null -w "  http %{http_code} in %{time_total}s\n" "http://$h/" || echo "  no answer"
  done
  echo "::endgroup::"
}
# The runner's resolver (Azure's 168.63.129.16) stopped resolving the arm64
# mirror on 2026-11-11 while every other name worked. Then the name is
# looked up over DNS-over-HTTPS and pinned in /etc/hosts for this job.
for h in ports.ubuntu.com; do
  timeout 10 getent ahostsv4 "$h" >/dev/null && continue
  ip=$(curl -fsS --max-time 10 -H 'accept: application/dns-json' "https://1.1.1.1/dns-query?name=$h&type=A" |
    jq -r '[.Answer[]? | select(.type == 1) | .data][0] // empty')
  if [[ "$ip" =~ ^[0-9]+(\.[0-9]+){3}$ ]]; then
    echo "$ip $h" >>/etc/hosts
    echo "::warning::the runner's DNS can't resolve $h; using $ip from 1.1.1.1"
  fi
done
step 5m apt-get -o Acquire::Retries=3 -o Acquire::http::Timeout=30 update -qq || { netdiag; exit 1; }
DEBIAN_FRONTEND=noninteractive step 10m apt-get install -y -qq incus jq >/dev/null

# Docker on the runner sets the FORWARD policy to DROP, which cuts the Incus
# containers off from the internet.
iptables -P FORWARD ACCEPT

step 2m incus admin init --preseed <<EOF
networks:
- name: incusbr0
  type: bridge
  config:
    ipv4.address: ${NET_ADDR}/24
    ipv4.nat: "true"
    ipv6.address: none
storage_pools:
- name: default
  driver: dir
profiles:
- name: default
  devices:
    root:
      path: /
      pool: default
      type: disk
    eth0:
      name: eth0
      network: incusbr0
      type: nic
EOF

# The PR tree server the harness expects (a service on the lab hosts).
mkdir -p "$SERVE_ROOT"
nohup python3 -m http.server "$SERVE_PORT" --bind "$NET_ADDR" --directory "$SERVE_ROOT" >/tmp/ci-serve.log 2>&1 &
echo "Incus $(incus --version) ready after $(($(date +%s) - start))s"

# --- Screenshots ----------------------------------------------------------------
# Optional: without them the build is still tested. The harness takes one only
# when `chromium` exists, the user ci-shot exists and the CI_SHOT chain keeps
# that user off private addresses (here: the cloud metadata service at
# 169.254.169.254 and the runner itself).
shots() {
  useradd --system --create-home --shell /usr/sbin/nologin ci-shot
  # Ubuntu's apt chromium is a snap wrapper; Playwright ships a plain arm64
  # build. Started directly with --screenshot, that build crashes on this
  # runner (sandbox or not), so `chromium` here is a stand-in that takes the
  # harness's arguments and drives the browser through Playwright instead.
  mkdir -p /opt/pw
  (cd /opt/pw && step 5m npm install --silent --no-audit --no-fund playwright-core@1.49.1 >/dev/null) || return 1
  PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers DEBIAN_FRONTEND=noninteractive \
    step 10m /opt/pw/node_modules/.bin/playwright-core install --with-deps chromium >/dev/null || return 1
  chmod -R a+rX /opt/pw /opt/pw-browsers
  cat >/opt/pw/shot.js <<'EOF'
// node shot.js <url> <out.png> <width> <height>
const { chromium } = require('/opt/pw/node_modules/playwright-core');
(async () => {
  const [url, out, w, h] = process.argv.slice(2);
  const browser = await chromium.launch({ chromiumSandbox: true });
  try {
    const page = await browser.newPage({ viewport: { width: Number(w), height: Number(h) }, ignoreHTTPSErrors: true });
    await page.goto(url, { waitUntil: 'load', timeout: 30000 }).catch(() => {});
    await page.waitForTimeout(5000);
    await page.screenshot({ path: out });
  } finally {
    await browser.close();
  }
})().catch(e => { console.error(e.message); process.exit(1); });
EOF
  cat >/usr/local/bin/chromium <<'EOF'
#!/usr/bin/env bash
# Stand-in for `chromium --headless ... --screenshot=<file> --window-size=W,H <url>`
# on the ARM runner (see arm-runner-setup.sh). Other flags are ignored.
url="" out="" w=1280 h=800
for a in "$@"; do
  case "$a" in
  --version) echo "Chromium (Playwright $(node -p "require('/opt/pw/node_modules/playwright-core/package.json').version"))"; exit 0 ;;
  --screenshot=*) out="${a#*=}" ;;
  --window-size=*) s="${a#*=}"; w="${s%,*}"; h="${s#*,}" ;;
  -*) ;;
  *) url="$a" ;;
  esac
done
[[ -n "$url" && -n "$out" ]] || { echo "usage: chromium --screenshot=<file> <url>" >&2; exit 2; }
PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers exec node /opt/pw/shot.js "$url" "$out" "$w" "$h"
EOF
  chmod 755 /usr/local/bin/chromium
  # Ubuntu 24.04 forbids unprivileged user namespaces through AppArmor, and
  # Chromium's sandbox needs them. The sandbox stays on; the restriction goes,
  # on a VM that exists for this one job.
  sysctl -qw kernel.apparmor_restrict_unprivileged_userns=0 2>/dev/null || true

  local uid fw net ns
  uid=$(id -u ci-shot)
  for fw in iptables ip6tables; do
    $fw -w -N CI_SHOT
    $fw -w -I OUTPUT -m owner --uid-owner "$uid" -j CI_SHOT
  done
  iptables -w -A CI_SHOT -d "$NET_ADDR" -j REJECT
  iptables -w -A CI_SHOT -d "$NET_CIDR" -j ACCEPT
  for ns in 127.0.0.53 $(awk '/^nameserver/ && $2 !~ /:/ {print $2}' /run/systemd/resolve/resolv.conf 2>/dev/null); do
    iptables -w -A CI_SHOT -d "$ns" -p udp --dport 53 -j ACCEPT
    iptables -w -A CI_SHOT -d "$ns" -p tcp --dport 53 -j ACCEPT
  done
  for net in 0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/3; do
    iptables -w -A CI_SHOT -d "$net" -j REJECT
  done
  for net in ::1/128 fc00::/7 fe80::/10 ff00::/8; do
    ip6tables -w -A CI_SHOT -d "$net" -j REJECT
  done

  # The same call the harness makes, on a page that needs no network.
  local dir
  dir=$(mktemp -d)
  chown ci-shot "$dir"
  # HOME: runuser keeps root's, which ci-shot cannot write (the harness does the same).
  runuser -u ci-shot -- env HOME="$dir" timeout 60 chromium --headless=new --disable-gpu --hide-scrollbars \
    --no-first-run --window-size=320,200 --user-data-dir="$dir/profile" \
    --screenshot="$dir/shot.png" 'data:text/html,<h1>ci</h1>' &>"$dir/chromium.log" || true
  if [[ ! -s "$dir/shot.png" ]]; then
    echo "Chromium could not take a test screenshot:"
    head -n 15 "$dir/chromium.log"
    echo "userns: $(sysctl -n kernel.apparmor_restrict_unprivileged_userns 2>&1)"
    rm -rf -- "$dir"
    return 1
  fi
  rm -rf -- "$dir"
  echo "$(chromium --version) ready for screenshots"
}
shots || echo "::warning::no screenshots on this ARM run (the build is still tested)"
echo "Runner ready after $(($(date +%s) - start))s"
