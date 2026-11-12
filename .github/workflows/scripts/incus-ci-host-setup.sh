#!/usr/bin/env bash
# One-time setup of an Incus test host behind pr-script-test.yml: the same
# ct/ scripts as on Proxmox, built through community-scripts/core's Incus
# backend. Safe to re-run. Run as root on a disposable Debian 13 machine (it
# builds pull request code as root).
#
#   incus-ci-host-setup.sh                       host only
#   incus-ci-host-setup.sh <owner/repo> <token>  host + a runner for that repo
#   incus-ci-host-setup.sh <owner/repo> jit      host + runner software only, for
#                                                ci-vm-controller.sh (single-use host)
#
# The token is a runner *registration* token (valid one hour):
#   gh api -X POST repos/<owner/repo>/actions/runners/registration-token --jq .token

set -euo pipefail

RUNNER_VERSION="${RUNNER_VERSION:-2.338.2}"
SERVE_ROOT=/srv/ci
SERVE_PORT=18080
NET_ADDR=10.98.0.1
NET_CIDR=10.98.0.0/24

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq incus jq curl python3 iptables chromium fonts-dejavu fonts-noto-color-emoji >/dev/null

# Containers get a NATed bridge of their own (Incus runs DHCP and DNS on it)
# and a plain directory pool on the root disk.
if ! incus storage show default &>/dev/null; then
  incus admin init --preseed <<EOF
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
fi

# Screenshots of the app under test are taken as this user, never as root.
id ci-shot &>/dev/null || useradd --system --create-home --shell /usr/sbin/nologin ci-shot

# Same rules as on the Proxmox hosts: the screenshot browser may reach the
# test containers, DNS and the public internet, nothing private, and not this
# host's own address on the container network (the PR tree server).
cat >/usr/local/sbin/ci-shot-firewall <<EOF
#!/usr/bin/env bash
set -euo pipefail
uid=\$(id -u ci-shot)
for fw in iptables ip6tables; do
  \$fw -w -N CI_SHOT 2>/dev/null || \$fw -w -F CI_SHOT
  \$fw -w -C OUTPUT -m owner --uid-owner "\$uid" -j CI_SHOT 2>/dev/null ||
    \$fw -w -I OUTPUT -m owner --uid-owner "\$uid" -j CI_SHOT
done
iptables -w -A CI_SHOT -d ${NET_ADDR} -j REJECT
iptables -w -A CI_SHOT -d ${NET_CIDR} -j ACCEPT
# systemd-resolved's stub; it forwards to the lab resolver itself.
iptables -w -A CI_SHOT -d 127.0.0.53 -p udp --dport 53 -j ACCEPT
iptables -w -A CI_SHOT -d 127.0.0.53 -p tcp --dport 53 -j ACCEPT
for ns in \$(awk '/^nameserver/ && \$2 !~ /:/ {print \$2}' /etc/resolv.conf /run/systemd/resolve/resolv.conf 2>/dev/null); do
  iptables -w -A CI_SHOT -d "\$ns" -p udp --dport 53 -j ACCEPT
  iptables -w -A CI_SHOT -d "\$ns" -p tcp --dport 53 -j ACCEPT
done
for net in 0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/3; do
  iptables -w -A CI_SHOT -d "\$net" -j REJECT
done
for net in ::1/128 fc00::/7 fe80::/10 ff00::/8; do
  ip6tables -w -A CI_SHOT -d "\$net" -j REJECT
done
EOF
chmod +x /usr/local/sbin/ci-shot-firewall
cat >/etc/systemd/system/ci-shot-firewall.service <<'EOF'
[Unit]
Description=Keep the screenshot browser away from this host and the lab network
After=network-online.target incus.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/ci-shot-firewall

[Install]
WantedBy=multi-user.target
EOF

[[ -s /etc/timezone ]] || {
  timedatectl set-timezone Europe/Vienna
  echo Europe/Vienna >/etc/timezone
}

# The rewritten PR trees, served to the engine and to the containers. Waits
# for incusbr0, which only exists once Incus is up.
mkdir -p "$SERVE_ROOT"
cat >/etc/systemd/system/ci-serve.service <<EOF
[Unit]
Description=Serve pull request trees to script builds
After=incus.service network-online.target
Wants=incus.service

[Service]
ExecStartPre=/bin/sh -c 'for i in \$(seq 1 60); do ip -4 addr show dev incusbr0 | grep -q ${NET_ADDR} && exit 0; incus network list >/dev/null 2>&1; sleep 1; done; exit 1'
ExecStart=/usr/bin/python3 -m http.server ${SERVE_PORT} --bind ${NET_ADDR} --directory ${SERVE_ROOT}
DynamicUser=yes
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Leftovers of a job that was killed before its cleanup trap ran.
cat >/usr/local/sbin/ci-sweep <<'EOF'
#!/usr/bin/env bash
# Delete CI containers (ci-9000 .. ci-9099) that no running job holds, and stale trees.
# A job holds its guest with /run/ci-jobs/<id>. A job killed outright (runner
# restart, timeout) never removes it, so a lock older than any job can run
# (90 minutes) holds nothing.
held() { [[ -e "/run/ci-jobs/$1" && -z "$(find "/run/ci-jobs/$1" -mmin +180)" ]]; }
for name in $(incus list -c n -f csv 2>/dev/null | grep -E '^ci-9[0-9]{3}$'); do
  held "$name" && continue
  incus delete "$name" --force &>/dev/null && echo "swept $name"
done
find /run/ci-jobs -maxdepth 1 -type f ! -name ".*" -mmin +180 -delete 2>/dev/null
find /srv/ci -mindepth 1 -maxdepth 1 -type d -mmin +180 -exec rm -rf {} +
find /usr/local/community-scripts/logs /var/log/community-scripts -type f -mtime +2 -delete 2>/dev/null
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
  # `jit`: a single-use host. ci-vm-controller.sh on the hypervisor registers
  # a fresh runner for every job and resets the VM afterwards, so only the
  # runner software goes on it, and the 'clean' snapshot is taken after this.
  if [[ "$token" == jit ]]; then
    echo "runner software for ${repo} installed; ci-vm-controller.sh registers a runner per job"
    exit 0
  fi
  if [[ -f .runner ]]; then
    ./svc.sh stop >/dev/null 2>&1 || true
    ./svc.sh uninstall >/dev/null 2>&1 || true
    RUNNER_ALLOW_RUNASROOT=1 ./config.sh remove --token "$token" >/dev/null 2>&1 || true
  fi
  # Only `incus-test`: see pve-ci-host-setup.sh for why there are no default labels.
  RUNNER_ALLOW_RUNASROOT=1 ./config.sh --unattended --replace --no-default-labels \
    --url "https://github.com/${repo}" --token "$token" \
    --name "$(hostname -s)-${repo#*/}" --labels incus-test --work _work
  ./svc.sh install root >/dev/null
  ./svc.sh start >/dev/null
  echo "runner for ${repo} registered"
fi

echo "incus test host ready: ${SERVE_ROOT} on ${NET_ADDR}:${SERVE_PORT}, sweeper every 3h"
