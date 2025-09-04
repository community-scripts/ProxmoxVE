#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    _   __     __  ____        __
   / | / /__  / /_/ __ \____ _/ /_____ _
  /  |/ / _ \/ __/ / / / __ `/ __/ __ `/
 / /|  /  __/ /_/ /_/ / /_/ / /_/ /_/ /
/_/ |_/\___/\__/_____/\__,_/\__/\__,_/

EOF
}

YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
silent() { "$@" >/dev/null 2>&1; }
set -e
header_info
echo "Loading..."
function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

function msg_error() { echo -e "${RD}✗ $1${CL}"; }

# This function checks the version of Proxmox Virtual Environment (PVE) and exits if the version is not supported.
# Supported: Proxmox VE 8.0.x – 8.9.x and 9.0 (NOT 9.1+)
pve_check() {
  local PVE_VER
  PVE_VER="$(pveversion | awk -F'/' '{print $2}' | awk -F'-' '{print $1}')"

  # Check for Proxmox VE 8.x: allow 8.0–8.9
  if [[ "$PVE_VER" =~ ^8\.([0-9]+) ]]; then
    local MINOR="${BASH_REMATCH[1]}"
    if ((MINOR < 0 || MINOR > 9)); then
      msg_error "This version of Proxmox VE is not supported."
      msg_error "Supported: Proxmox VE version 8.0 – 8.9"
      exit 1
    fi
    return 0
  fi

  # Check for Proxmox VE 9.x: allow ONLY 9.0
  if [[ "$PVE_VER" =~ ^9\.([0-9]+) ]]; then
    local MINOR="${BASH_REMATCH[1]}"
    if ((MINOR != 0)); then
      msg_error "This version of Proxmox VE is not yet supported."
      msg_error "Supported: Proxmox VE version 9.0"
      exit 1
    fi
    return 0
  fi

  # All other unsupported versions
  msg_error "This version of Proxmox VE is not supported."
  msg_error "Supported versions: Proxmox VE 8.0 – 8.x or 9.0"
  exit 1
}

detect_codename() {
  source /etc/os-release
  if [[ "$ID" != "debian" ]]; then
    msg_error "Unsupported base OS: $ID (only Proxmox VE / Debian supported)."
    exit 1
  fi
  CODENAME="${VERSION_CODENAME:-}"
  if [[ -z "$CODENAME" ]]; then
    msg_error "Could not detect Debian codename."
    exit 1
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
  header_info
  while true; do
    read -p "Are you sure you want to install NetData on Proxmox VE host. Proceed(y/n)? " yn
    case $yn in
    [Yy]*) break ;;
    [Nn]*) exit ;;
    *) echo "Please answer yes or no." ;;
    esac
  done

  read -r -p "Verbose mode? <y/N> " prompt
  [[ ${prompt,,} =~ ^(y|yes)$ ]] && STD="" || STD="silent"

  CODENAME=$(detect_codename)
  REPO_URL="https://repo.netdata.cloud/repos/repoconfig/debian/${CODENAME}/"

  msg_info "Setting up repository"
  $STD apt-get install -y debian-keyring
  PKG=$(get_latest_repo_pkg "$REPO_URL")
  if [[ -z "$PKG" ]]; then
    msg_error "Could not find netdata-repo package for Debian $CODENAME"
    exit 1
  fi
  curl -fsSL "${REPO_URL}${PKG}" -o "$PKG"
  $STD dpkg -i "$PKG"
  rm -f "$PKG"
  msg_ok "Set up repository"

  msg_info "Installing Netdata"
  $STD apt-get update
  $STD apt-get install -y netdata
  msg_ok "Installed Netdata"
  msg_ok "Completed Successfully!\n"
  echo -e "\n Netdata should be reachable at${BL} http://$(hostname -I | awk '{print $1}'):19999 ${CL}\n"
}

uninstall() {
  header_info
  read -r -p "Verbose mode? <y/N> " prompt
  [[ ${prompt,,} =~ ^(y|yes)$ ]] && STD="" || STD="silent"

  msg_info "Uninstalling Netdata"
  systemctl stop netdata || true
  rm -rf /var/log/netdata /var/lib/netdata /var/cache/netdata /etc/netdata/go.d
  rm -rf /etc/apt/trusted.gpg.d/netdata-archive-keyring.gpg /etc/apt/sources.list.d/netdata.list
  $STD apt-get remove --purge -y netdata netdata-repo
  systemctl daemon-reload
  $STD apt autoremove -y
  $STD userdel netdata || true
  msg_ok "Uninstalled Netdata"
  msg_ok "Completed Successfully!\n"
}

header_info
pve_check

OPTIONS=(Install "Install NetData on Proxmox VE"
  Uninstall "Uninstall NetData from Proxmox VE")

CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "NetData" \
  --menu "Select an option:" 10 58 2 "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

case $CHOICE in
"Install") install ;;
"Uninstall") uninstall ;;
*)
  echo "Exiting..."
  exit 0
  ;;
esac
