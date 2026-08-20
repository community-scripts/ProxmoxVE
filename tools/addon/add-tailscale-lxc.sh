#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tailscale.com/ | Github: https://github.com/tailscale/tailscale

APP="add-tailscale-lxc"
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
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "add-tailscale-lxc" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

header_info
require_pve_host

while true; do
  read -rp "This will add Tailscale to an existing LXC Container ONLY. Proceed (y/n)? " yn
  case "$yn" in
  [Yy]*) break ;;
  [Nn]*) exit 0 ;;
  *) echo "Please answer yes or no." ;;
  esac
done

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

stop_spinner
CTID=""
while [[ -z "${CTID}" ]]; do
  CTID=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Containers on $NODE" --radiolist \
    "\nSelect a container to add Tailscale to:\n" \
    16 $((MSG_MAX_LENGTH + 23)) 6 \
    "${CTID_MENU[@]}" 3>&1 1>&2 2>&3) || exit 0
done

CTID_CONFIG_PATH="/etc/pve/lxc/${CTID}.conf"

# Skip if already configured
grep -q "lxc.cgroup2.devices.allow: c 10:200 rwm" "$CTID_CONFIG_PATH" || echo "lxc.cgroup2.devices.allow: c 10:200 rwm" >>"$CTID_CONFIG_PATH"
grep -q "lxc.mount.entry: /dev/net/tun" "$CTID_CONFIG_PATH" || echo "lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file" >>"$CTID_CONFIG_PATH"

msg_info "Installing Tailscale in CT $CTID"

pct exec "$CTID" -- bash -c '
set -e

# Detect OS inside container
if [ -f /etc/alpine-release ]; then
  # ── Alpine Linux ──
  echo "[INFO] Alpine Linux detected, installing Tailscale via apk..."

  # Enable community repo if not already enabled
  if ! grep -q "^[^#].*community" /etc/apk/repositories 2>/dev/null; then
    ALPINE_VERSION=$(cat /etc/alpine-release | cut -d. -f1,2)
    echo "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community" >> /etc/apk/repositories
  fi

  apk update
  apk add --no-cache tailscale

  # Enable and start Tailscale service
  rc-update add tailscale default 2>/dev/null || true
  rc-service tailscale start 2>/dev/null || true

else
  # ── Debian / Ubuntu ──
  export DEBIAN_FRONTEND=noninteractive

  # Source os-release properly (handles quoted values)
  . /etc/os-release

  # Fallback if DNS is poisoned or blocked
  ORIG_RESOLV="/etc/resolv.conf"
  BACKUP_RESOLV="/tmp/resolv.conf.backup"

  # Check DNS resolution using multiple methods (dig may not be installed)
  dns_check_failed=true
  if command -v dig >/dev/null 2>&1; then
    if dig +short pkgs.tailscale.com 2>/dev/null | grep -qvE "^127\.|^0\.0\.0\.0$|^$"; then
      dns_check_failed=false
    fi
  elif command -v host >/dev/null 2>&1; then
    if host pkgs.tailscale.com 2>/dev/null | grep -q "has address"; then
      dns_check_failed=false
    fi
  elif command -v nslookup >/dev/null 2>&1; then
    if nslookup pkgs.tailscale.com 2>/dev/null | grep -q "Address:"; then
      dns_check_failed=false
    fi
  elif command -v getent >/dev/null 2>&1; then
    if getent hosts pkgs.tailscale.com >/dev/null 2>&1; then
      dns_check_failed=false
    fi
  else
    # No DNS tools available, try curl directly and assume DNS works
    dns_check_failed=false
  fi

  if $dns_check_failed; then
    echo "[INFO] DNS resolution for pkgs.tailscale.com failed (blocked or redirected)."
    echo "[INFO] Temporarily overriding /etc/resolv.conf with Cloudflare DNS (1.1.1.1)"
    cp "$ORIG_RESOLV" "$BACKUP_RESOLV"
    echo "nameserver 1.1.1.1" >"$ORIG_RESOLV"
  fi

  if ! command -v curl >/dev/null 2>&1; then
    echo "[INFO] curl not found, installing..."
    apt-get update -qq
    apt-get install -y curl >/dev/null
  fi

  # Reuse the shared repository helper instead of hand-rolling the sources entry
  source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
  source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
  load_functions

  # Drop the legacy keyring from the pre-deb822 layout
  rm -f /usr/share/keyrings/tailscale-archive-keyring.gpg

  setup_deb822_repo \
    "tailscale" \
    "https://pkgs.tailscale.com/stable/${ID}/${VERSION_CODENAME}.noarmor.gpg" \
    "https://pkgs.tailscale.com/stable/${ID}" \
    "${VERSION_CODENAME}" \
    "main"

  apt-get install -y tailscale >/dev/null

  if [ -f /tmp/resolv.conf.backup ]; then
    echo "[INFO] Restoring original /etc/resolv.conf"
    mv /tmp/resolv.conf.backup /etc/resolv.conf
  fi
fi
'

TAGS=$(awk -F': ' '/^tags:/ {print $2}' "$CTID_CONFIG_PATH")
TAGS="${TAGS:+$TAGS; }tailscale"
pct set "$CTID" -tags "$TAGS"

msg_ok "Tailscale installed on CT $CTID"
echo -e "${YW}Reboot the container${CL}, then run 'tailscale up' inside the container to activate."
