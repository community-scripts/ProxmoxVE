#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

set -Eeuo pipefail
trap 'echo -e "\n[ERROR] in line $LINENO: exit code $?"' ERR

function header_info() {
  clear
  cat <<"EOF"
  ______      _ __                __
 /_  __/___ _(_) /_____________ _/ /__
  / / / __ `/ / / ___/ ___/ __ `/ / _ \
 / / / /_/ / / (__  ) /__/ /_/ / /  __/
/_/  \__,_/_/_/____/\___/\__,_/_/\___/

EOF
}

function msg_info() { echo -e " \e[1;36m➤\e[0m $1"; }
function msg_ok() { echo -e " \e[1;32m✔\e[0m $1"; }
function msg_error() { echo -e " \e[1;31m✖\e[0m $1"; }

header_info

if ! command -v pveversion &>/dev/null; then
  msg_error "This script must be run on the Proxmox VE host (not inside an LXC container)"
  exit 1
fi

while true; do
  read -rp "This will add Tailscale to an existing LXC Container ONLY. Proceed (y/n)? " yn
  case "$yn" in
  [Yy]*) break ;;
  [Nn]*) exit 0 ;;
  *) echo "Please answer yes or no." ;;
  esac
done

header_info
msg_info "Loading container list..."

NODE=$(hostname)
MSG_MAX_LENGTH=0
CTID_MENU=()

while read -r line; do
  TAG=$(echo "$line" | awk '{print $1}')
  ITEM=$(echo "$line" | awk '{print substr($0,36)}')
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=$((${#ITEM} + OFFSET))
  CTID_MENU+=("$TAG" "$ITEM" "OFF")
done < <(pct list | awk 'NR>1')

CTID=""
while [[ -z "${CTID}" ]]; do
  CTID=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Containers on $NODE" --radiolist \
    "\nSelect a container to add Tailscale to:\n" \
    16 $((MSG_MAX_LENGTH + 23)) 6 \
    "${CTID_MENU[@]}" 3>&1 1>&2 2>&3) || exit 1
done

CTID_CONFIG_PATH="/etc/pve/lxc/${CTID}.conf"

# Skip if already configured
grep -q "lxc.cgroup2.devices.allow: c 10:200 rwm" "$CTID_CONFIG_PATH" || echo "lxc.cgroup2.devices.allow: c 10:200 rwm" >>"$CTID_CONFIG_PATH"
grep -q "lxc.mount.entry: /dev/net/tun" "$CTID_CONFIG_PATH" || echo "lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file" >>"$CTID_CONFIG_PATH"

header_info
msg_info "Installing Tailscale in CT $CTID"

pct exec "$CTID" -- bash -c '
set -e
export DEBIAN_FRONTEND=noninteractive

ID=$(grep "^ID=" /etc/os-release | cut -d"=" -f2)
VER=$(grep "^VERSION_CODENAME=" /etc/os-release | cut -d"=" -f2)

# fallback if DNS is poisoned or blocked
ORIG_RESOLV="/etc/resolv.conf"
BACKUP_RESOLV="/tmp/resolv.conf.backup"

if ! dig +short pkgs.tailscale.com | grep -qvE "^127\.|^0\.0\.0\.0$"; then
  echo "[INFO] DNS resolution for pkgs.tailscale.com failed (blocked or redirected)."
  echo "[INFO] Temporarily overriding /etc/resolv.conf with Cloudflare DNS (1.1.1.1)"
  cp "$ORIG_RESOLV" "$BACKUP_RESOLV"
  echo "nameserver 1.1.1.1" >"$ORIG_RESOLV"
fi

if ! command -v curl &>/dev/null; then
  echo "[INFO] curl not found, installing..."
  apt-get update -qq
  apt-get install -y curl >/dev/null
fi

curl -fsSL https://pkgs.tailscale.com/stable/${ID}/${VER}.noarmor.gpg \
  | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/${ID} ${VER} main" \
  >/etc/apt/sources.list.d/tailscale.list

apt-get update -qq
apt-get install -y tailscale >/dev/null

if [[ -f /tmp/resolv.conf.backup ]]; then
  echo "[INFO] Restoring original /etc/resolv.conf"
  mv /tmp/resolv.conf.backup /etc/resolv.conf
fi
'

TAGS=$(awk -F': ' '/^tags:/ {print $2}' "$CTID_CONFIG_PATH")
TAGS="${TAGS:+$TAGS; }tailscale"
pct set "$CTID" -tags "$TAGS"

msg_ok "Tailscale installed on CT $CTID"
msg_info "Reboot the container, then run 'tailscale up' inside the container to activate."
