#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.proxmox.com/en/proxmox-backup-server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

export DEBIAN_FRONTEND=noninteractive
export IFUPDOWN2_NO_IFRELOAD=1
if [[ "$(arch_resolve)" == "arm64" ]]; then
  msg_info "Installing Proxmox Backup Server (unofficial arm64 build)"
  PBS_TMP="$(mktemp -d)"
  github_api_call "https://api.github.com/repos/wofferl/proxmox-backup-arm64/releases/latest" "$PBS_TMP/release.json"
  cd "$PBS_TMP"
  for url in $(jq -r '.assets[].browser_download_url
    | select(endswith(".deb"))
    | select(test("dbgsym|client-static|file-restore") | not)' release.json); do
    curl_with_retry "$url" "$(basename "$url")"
  done
  $STD apt install -y ./*.deb
  rm -rf "$PBS_TMP"
else
  msg_info "Installing Proxmox Backup Server"
  setup_deb822_repo \
    "proxmox-backup-server" \
    "https://enterprise.proxmox.com/debian/proxmox-archive-keyring-trixie.gpg" \
    "http://download.proxmox.com/debian/pbs" \
    "trixie" \
    "pbs-no-subscription"
  $STD apt install -y proxmox-backup-server
fi
msg_ok "Installed Proxmox Backup Server"

motd_ssh
customize
cleanup_lxc
