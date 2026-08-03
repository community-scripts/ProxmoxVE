#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.netdata.cloud/ | Github: https://github.com/netdata/netdata

APP="Netdata"
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
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "netdata" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

detect_codename() {
  source /etc/os-release
  if [[ "$ID" != "debian" ]]; then
    msg_error "Unsupported base OS: $ID (only Proxmox VE / Debian supported)."
    exit 238
  fi
  CODENAME="${VERSION_CODENAME:-}"
  if [[ -z "$CODENAME" ]]; then
    msg_error "Could not detect Debian codename."
    exit 238
  fi
  echo "$CODENAME"
}

get_latest_repo_pkg() {
  local REPO_URL=$1
  curl -fsSL "$REPO_URL" |
    grep -oP 'netdata-repo_[^"]+all\.deb' |
    sort -V |
    tail -n1
}

install() {
  while true; do
    read -r -p "Are you sure you want to install ${APP} on Proxmox VE host. Proceed(y/n)? " yn
    case $yn in
    [Yy]*) break ;;
    [Nn]*) exit ;;
    *) echo "Please answer yes or no." ;;
    esac
  done

  CODENAME=$(detect_codename)
  REPO_URL="https://repo.netdata.cloud/repos/repoconfig/debian/${CODENAME}/"

  msg_info "Setting up repository"
  $STD apt install -y debian-keyring
  PKG=$(get_latest_repo_pkg "$REPO_URL")
  if [[ -z "$PKG" ]]; then
    msg_error "Could not find netdata-repo package for Debian $CODENAME"
    exit 237
  fi
  TMP_DEB=$(mktemp --suffix=.deb)
  curl -fsSL "${REPO_URL}${PKG}" -o "$TMP_DEB"
  $STD dpkg -i "$TMP_DEB"
  rm -f "$TMP_DEB"
  msg_ok "Set up repository"

  msg_info "Installing ${APP}"
  $STD apt update
  $STD apt install -y netdata
  msg_ok "Installed ${APP}"
  msg_ok "Completed successfully!\n"
  get_lxc_ip
  echo -e "\n${APP} should be reachable at${BL} http://${LOCAL_IP}:19999 ${CL}\n"
}

uninstall() {
  msg_info "Uninstalling ${APP}"
  systemctl stop netdata || true
  rm -rf /var/log/netdata /var/lib/netdata /var/cache/netdata /etc/netdata/go.d
  rm -rf /etc/apt/trusted.gpg.d/netdata-archive-keyring.gpg /etc/apt/sources.list.d/netdata.list
  $STD apt remove --purge -y netdata netdata-repo
  systemctl daemon-reload
  $STD apt autoremove -y
  $STD userdel netdata || true
  msg_ok "Uninstalled ${APP}"
  msg_ok "Completed successfully!\n"
}

header_info
require_pve_host

OPTIONS=(Install "Install ${APP} on Proxmox VE"
  Uninstall "Uninstall ${APP} from Proxmox VE")

CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "${APP}" \
  --menu "Select an option:" 10 58 2 "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

case $CHOICE in
"Install") install ;;
"Uninstall") uninstall ;;
*)
  echo "Exiting..."
  exit 0
  ;;
esac
