#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://netbird.io/ | Github: https://github.com/netbirdio/netbird

APP="add-netbird-lxc"
APP_TYPE="addon"

if ! command -v curl &>/dev/null; then
  printf "\r\e[2K%b" '\033[93m Setup Source \033[m' >&2
  if [[ -f /etc/alpine-release ]]; then
    apk update >/dev/null 2>&1
    apk add --no-cache curl >/dev/null 2>&1
  else
    apt-get update >/dev/null 2>&1
    apt-get install -y curl >/dev/null 2>&1
  fi
fi
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "add-netbird-lxc" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

header_info
require_pve_host

while true; do
  read -r -p "This will add NetBird to an existing LXC Container ONLY. Proceed(y/n)? " yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) exit 0 ;;
  *) echo "Please answer yes or no." ;;
  esac
done

echo -e "Loading container list..."

NODE=$(hostname)
MSG_MAX_LENGTH=0
while read -r line; do
  TAG=$(echo "$line" | awk '{print $1}')
  ITEM=$(echo "$line" | awk '{print substr($0,36)}')
  OFFSET=2
  if [[ $((${#ITEM} + $OFFSET)) -gt ${MSG_MAX_LENGTH:-} ]]; then
    MSG_MAX_LENGTH=$((${#ITEM} + $OFFSET))
  fi
  CTID_MENU+=("$TAG" "$ITEM " "OFF")
done < <(pct list | awk 'NR>1')

while [ -z "${CTID:+x}" ]; do
  CTID=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Containers on $NODE" --radiolist \
    "\nSelect a container to add NetBird to:\n" \
    16 $(($MSG_MAX_LENGTH + 23)) 6 \
    "${CTID_MENU[@]}" 3>&1 1>&2 2>&3)
done

LXC_STATUS=$(pct status "$CTID" | awk '{print $2}')
if [[ "$LXC_STATUS" != "running" ]]; then
  msg_info "Container $CTID is not running. Starting it now..."
  pct start "$CTID"
  while [[ "$(pct status "$CTID" | awk '{print $2}')" != "running" ]]; do
    msg_info "Waiting for the container to start..."
    sleep 2
  done
  msg_ok "Container $CTID is now running."
fi

DISTRO=$(pct exec "$CTID" -- cat /etc/os-release | grep -w "ID" | cut -d'=' -f2 | tr -d '"')
if [[ "$DISTRO" != "debian" && "$DISTRO" != "ubuntu" ]]; then
  msg_error "This script only supports Debian or Ubuntu LXC containers. Detected: $DISTRO. Aborting..."
  exit 238
fi

CTID_CONFIG_PATH="/etc/pve/lxc/${CTID}.conf"
cat <<EOF >>"$CTID_CONFIG_PATH"
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
EOF

msg_info "Installing NetBird"
pct exec "$CTID" -- bash -c '
set -e
if ! command -v curl &>/dev/null; then
  apt-get update -qq
  apt-get install -y curl >/dev/null
fi
apt-get install -y ca-certificates gpg &>/dev/null

# Reuse the shared repository helper instead of hand-rolling the sources entry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
load_functions

# Drop the legacy keyring from the pre-deb822 layout
rm -f /usr/share/keyrings/netbird-archive-keyring.gpg

setup_deb822_repo \
  "netbird" \
  "https://pkgs.netbird.io/debian/public.key" \
  "https://pkgs.netbird.io/debian" \
  "stable" \
  "main"

apt-get install -y netbird-ui &>/dev/null
if systemctl list-unit-files docker.service &>/dev/null; then
  mkdir -p /etc/systemd/system/netbird.service.d
  cat <<OVERRIDE >/etc/systemd/system/netbird.service.d/after-docker.conf
[Unit]
After=docker.service
Wants=docker.service
OVERRIDE
  systemctl daemon-reload
fi
'
msg_ok "Installed NetBird."
echo -e "${YW}Reboot ${CTID} LXC${CL} to apply the changes, then run 'netbird up' in the LXC console"
