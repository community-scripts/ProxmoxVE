#!/usr/bin/env bash
# Installs ci-vm-controller.sh on the hypervisor (prox1): the script, the
# token reader, a systemd unit per CI VM, and each VM's config. Run as root
# on prox1 from a directory that also holds ci-vm-controller.sh:
#
#   scp ci-controller-setup.sh ci-vm-controller.sh root@prox1:/root/ci-controller/
#   ssh root@prox1 'cd /root/ci-controller && bash ci-controller-setup.sh'
#
# It does not start anything: a VM goes into service with
#   systemctl enable --now ci-vm-controller@<vmid>
# once it has a 'clean' snapshot without any runner registered (see
# docs/guides/pr-script-testing.md, "Single-use hosts").
#
# The token (/etc/ci-controller/token) is put there by hand: a fine-grained
# token for the two repositories with Administration: read and write only.

set -euo pipefail
cd "$(dirname "$0")"
[[ -f ci-vm-controller.sh ]] || { echo "ci-vm-controller.sh missing next to this script" >&2; exit 1; }
command -v jq >/dev/null || DEBIAN_FRONTEND=noninteractive apt-get install -y -qq jq >/dev/null

install -m 755 ci-vm-controller.sh /usr/local/sbin/ci-vm-controller.sh
install -d -m 700 /etc/ci-controller

cat >/usr/local/sbin/ci-gh-token <<'EOF'
#!/bin/sh
# Prints the token ci-vm-controller.sh uses (Administration: write on the CI
# repositories). Swap this for a GitHub App token later without touching
# the controller.
exec cat /etc/ci-controller/token
EOF
chmod 755 /usr/local/sbin/ci-gh-token

cat >/etc/systemd/system/ci-vm-controller@.service <<'EOF'
[Unit]
Description=Single-use CI runner host, VM %i
After=network-online.target pve-cluster.service pvedaemon.service
Wants=network-online.target
# A missing token is a setup error, not something to retry every 30 s.
ConditionPathExists=/etc/ci-controller/token

[Service]
ExecStart=/usr/local/sbin/ci-vm-controller.sh %i
Restart=always
RestartSec=30
# Stopping the controller leaves the VM as it is; the next start resets it,
# which also ends a job that may still be running there.
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF

# One repository per host: see ci-vm-controller.sh.
conf() { # conf <vmid> <ip> <name> <label> <repo>
  cat >"/etc/ci-controller/$1.conf" <<EOF
VM_IP=$2
HOST_NAME=$3
LABEL=$4
REPOS=$5
EOF
}
conf 200 10.201.146.232 pve-ci     proxmox-test community-scripts/DevScripts
conf 201 10.201.146.231 pve-ci-2   proxmox-test community-scripts/ProxmoxVE
conf 202 10.201.146.233 incus-ci   incus-test   community-scripts/DevScripts
conf 203 10.201.146.234 incus-ci-2 incus-test   community-scripts/ProxmoxVE

systemctl daemon-reload
echo "Installed. Token: $([[ -s /etc/ci-controller/token ]] && echo present || echo 'MISSING (/etc/ci-controller/token)')"
