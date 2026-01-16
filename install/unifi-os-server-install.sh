#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ui.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

if [[ "${CTTYPE:-1}" != "0" ]]; then
  msg_error "UniFi OS Server requires a privileged LXC container."
  msg_error "Recreate the container with unprivileged=0."
  exit 1
fi

if [[ ! -e /dev/net/tun ]]; then
  msg_error "Missing /dev/net/tun in container."
  msg_error "Enable TUN/TAP (var_tun=yes) or add /dev/net/tun passthrough."
  exit 1
fi

msg_info "Installing dependencies"
$STD apt install -y \
  podman \
  uidmap \
  slirp4netns
msg_ok "Installed dependencies"

msg_info "Installing sysctl wrapper (ignore non-critical errors)"
cat <<'EOF' >/usr/local/sbin/sysctl
#!/bin/sh
/usr/sbin/sysctl "$@" || true
exit 0
EOF
chmod +x /usr/local/sbin/sysctl
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
msg_ok "Sysctl wrapper installed"

msg_info "Fetching latest UniFi OS Server"
API_URL="https://fw-update.ui.com/api/firmware-latest"
TEMP_JSON="$(mktemp)"
if ! curl -fsSL "$API_URL" -o "$TEMP_JSON"; then
  rm -f "$TEMP_JSON"
  msg_error "Failed to fetch data from Ubiquiti API"
  exit 1
fi
LATEST=$(jq -r '
  ._embedded.firmware
  | map(select(.product == "unifi-os-server"))
  | map(select(.platform == "linux-x64"))
  | sort_by(.version_major, .version_minor, .version_patch)
  | last
' "$TEMP_JSON")
UOS_VERSION=$(echo "$LATEST" | jq -r '.version' | sed 's/^v//')
UOS_URL=$(echo "$LATEST" | jq -r '._links.data.href')
rm -f "$TEMP_JSON"
if [[ -z "$UOS_URL" || -z "$UOS_VERSION" || "$UOS_URL" == "null" ]]; then
  msg_error "Failed to parse UniFi OS Server version or download URL"
  exit 1
fi
msg_ok "Found UniFi OS Server ${UOS_VERSION}"

msg_info "Downloading UniFi OS Server installer"
mkdir -p /usr/local/sbin
curl -fsSL "$UOS_URL" -o /usr/local/sbin/unifi-os-server.bin
chmod +x /usr/local/sbin/unifi-os-server.bin
msg_ok "Downloaded UniFi OS Server installer"

msg_info "Installing UniFi OS Server (this takes a few minutes)"
$STD /usr/local/sbin/unifi-os-server.bin <<<"y"
msg_ok "UniFi OS Server installed"

motd_ssh
customize
cleanup_lxc
