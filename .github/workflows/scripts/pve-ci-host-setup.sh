#!/usr/bin/env bash
# One-time setup of the Proxmox test host behind pr-script-test.yml.
# Safe to re-run. Run as root on the test host (a disposable PVE, never a
# production node: it builds pull request code as root).
#
#   pve-ci-host-setup.sh                       host only
#   pve-ci-host-setup.sh <owner/repo> <token>  host + a runner for that repo
#
# The token is a runner *registration* token (valid one hour):
#   gh api -X POST repos/<owner/repo>/actions/runners/registration-token --jq .token

set -euo pipefail

RUNNER_VERSION="${RUNNER_VERSION:-2.338.2}"
SERVE_ROOT=/srv/ci
SERVE_PORT=18080
UPLINK="${UPLINK:-vmbr0}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq jq curl python3 dnsmasq iptables chromium fonts-dejavu fonts-noto-color-emoji >/dev/null

# Screenshots of the app under test are taken as this user, never as root.
id ci-shot &>/dev/null || useradd --system --create-home --shell /usr/sbin/nologin ci-shot

# The page Chromium renders is served by code under test, and a redirect or an
# <img> could point it at this host (the PVE UI on :8006) or the lab network;
# the screenshot would then publish that on the PR. So ci-shot may reach the
# test containers, DNS and the public internet (apps load fonts and scripts
# from CDNs), and nothing private.
cat >/usr/local/sbin/ci-shot-firewall <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
uid=$(id -u ci-shot)
for fw in iptables ip6tables; do
  $fw -w -N CI_SHOT 2>/dev/null || $fw -w -F CI_SHOT
  $fw -w -C OUTPUT -m owner --uid-owner "$uid" -j CI_SHOT 2>/dev/null ||
    $fw -w -I OUTPUT -m owner --uid-owner "$uid" -j CI_SHOT
done
iptables -w -A CI_SHOT -d 10.99.0.1 -j REJECT
iptables -w -A CI_SHOT -d 10.99.0.0/24 -j ACCEPT
for ns in $(awk '/^nameserver/ && $2 !~ /:/ {print $2}' /etc/resolv.conf); do
  iptables -w -A CI_SHOT -d "$ns" -p udp --dport 53 -j ACCEPT
  iptables -w -A CI_SHOT -d "$ns" -p tcp --dport 53 -j ACCEPT
done
for net in 0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/3; do
  iptables -w -A CI_SHOT -d "$net" -j REJECT
done
for net in ::1/128 fc00::/7 fe80::/10 ff00::/8; do
  ip6tables -w -A CI_SHOT -d "$net" -j REJECT
done
EOF
chmod +x /usr/local/sbin/ci-shot-firewall
cat >/etc/systemd/system/ci-shot-firewall.service <<'EOF'
[Unit]
Description=Keep the screenshot browser away from this host and the lab network
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/ci-shot-firewall

[Install]
WantedBy=multi-user.target
EOF

# Containers get their own NATed bridge instead of the lab network: no DHCP
# lease surprises (a lab lease once handed a container the host's own address),
# and an app listening on 8080 can never be confused with this host.
cat >/etc/network/interfaces.d/ci-nat <<EOF
auto vmbr1
iface vmbr1 inet static
	address 10.99.0.1/24
	bridge-ports none
	bridge-stp off
	bridge-fd 0
	post-up sysctl -qw net.ipv4.ip_forward=1
	post-up iptables -t nat -C POSTROUTING -s 10.99.0.0/24 -o ${UPLINK} -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s 10.99.0.0/24 -o ${UPLINK} -j MASQUERADE
	post-down iptables -t nat -D POSTROUTING -s 10.99.0.0/24 -o ${UPLINK} -j MASQUERADE || true
EOF
ifreload -a
cat >/etc/dnsmasq.d/ci.conf <<'EOF'
interface=vmbr1
bind-interfaces
except-interface=lo
dhcp-range=10.99.0.100,10.99.0.250,255.255.255.0,2h
dhcp-option=option:router,10.99.0.1
dhcp-option=option:dns-server,10.99.0.1
no-resolv
EOF
# Upstream = whatever this host resolves with. Debian's dnsmasq would otherwise
# ask resolvconf, which has nothing to offer on a PVE host.
awk '/^nameserver/ {print "server=" $2}' /etc/resolv.conf >>/etc/dnsmasq.d/ci.conf
systemctl enable dnsmasq >/dev/null
systemctl restart dnsmasq

# A PVE ISO install writes /etc/timezone; a cloud-image install does not, and
# the engine's pct_timezone aborts without it.
[[ -s /etc/timezone ]] || {
  timedatectl set-timezone Europe/Vienna
  echo Europe/Vienna >/etc/timezone
}

# Containers live on the root filesystem; there is no LVM in a cloud-image PVE.
pvesm set local --content iso,vztmpl,backup,rootdir,images

# Templates are fetched once here rather than on every first build.
pveam update >/dev/null
for t in $(pveam available --section system | awk '/_amd64\./ && /debian-13-standard|alpine-3\.2[0-9]-default|ubuntu-24\.04-standard/ {print $2}'); do
  pveam list local | grep -q "$t" || pveam download local "$t" >/dev/null
done

# The rewritten PR trees, served to the engine and to the containers.
mkdir -p "$SERVE_ROOT"
cat >/etc/systemd/system/ci-serve.service <<EOF
[Unit]
Description=Serve pull request trees to script builds
After=network-online.target

[Service]
ExecStart=/usr/bin/python3 -m http.server ${SERVE_PORT} --bind 10.99.0.1 --directory ${SERVE_ROOT}
DynamicUser=yes
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Leftovers of a job that was killed before its cleanup trap ran.
cat >/usr/local/sbin/ci-sweep <<'EOF'
#!/usr/bin/env bash
# Destroy CI containers (9000-9099) that no running job holds, and stale trees.
for id in $(pct list | awk 'NR>1 && $1>=9000 && $1<=9099 {print $1}'); do
  [[ -e "/run/ci-jobs/$id" ]] && continue
  pct stop "$id" --skiplock 1 &>/dev/null || true
  pct destroy "$id" --purge 1 --force 1 &>/dev/null && echo "swept CT $id"
done
find /srv/ci -mindepth 1 -maxdepth 1 -type d -mmin +180 -exec rm -rf {} +
# Engine logs that a killed job never got to remove.
find /tmp -maxdepth 1 -type f \( -name 'create-lxc-*.log' -o -name 'pct_create_*.log' \
  -o -regex '/tmp/.*-9[0-9][0-9][0-9]-[0-9a-f]+\.log' \) -mmin +180 -delete
find /var/log/community-scripts -type f -mtime +2 -delete 2>/dev/null
find /opt/actions-runner/*/_diag -type f -mtime +14 -delete 2>/dev/null
true
EOF
chmod +x /usr/local/sbin/ci-sweep
cat >/etc/systemd/system/ci-sweep.service <<'EOF'
[Unit]
Description=Remove leftover CI containers

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/ci-sweep
EOF
cat >/etc/systemd/system/ci-sweep.timer <<'EOF'
[Unit]
Description=Remove leftover CI containers every 3 hours

[Timer]
OnCalendar=0/3:30
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now ci-serve.service ci-sweep.timer ci-shot-firewall.service >/dev/null
systemctl restart ci-serve.service ci-shot-firewall.service

# --- Runner (one per repository) ----------------------------------------------
if [[ $# -eq 2 ]]; then
  repo="$1"
  token="$2"
  [[ "$repo" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || { echo "bad repo" >&2; exit 2; }
  dir="/opt/actions-runner/${repo#*/}"
  mkdir -p "$dir"
  cd "$dir"
  if [[ ! -x ./config.sh ]]; then
    curl -fsSL "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" | tar -xz
    ./bin/installdependencies.sh >/dev/null
  fi
  # A registered runner is reconfigured from scratch: stop and remove the old
  # registration (the token works for removal too).
  if [[ -f .runner ]]; then
    ./svc.sh stop >/dev/null 2>&1 || true
    ./svc.sh uninstall >/dev/null 2>&1 || true
    RUNNER_ALLOW_RUNASROOT=1 ./config.sh remove --token "$token" >/dev/null 2>&1 || true
  fi
  # Root, because pct needs it; the host is disposable by design.
  # --no-default-labels: without it the runner also answers to `self-hosted`,
  # and any other workflow with `runs-on: self-hosted` (and its secrets) could
  # land on this host.
  RUNNER_ALLOW_RUNASROOT=1 ./config.sh --unattended --replace --no-default-labels \
    --url "https://github.com/${repo}" --token "$token" \
    --name "pve-ci-${repo#*/}" --labels proxmox-test --work _work
  ./svc.sh install root >/dev/null
  ./svc.sh start >/dev/null
  echo "runner for ${repo} registered"
fi

echo "test host ready: ${SERVE_ROOT} on :${SERVE_PORT}, sweeper every 3h"
