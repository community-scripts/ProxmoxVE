#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.cloudflare.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Cloudflared"
setup_deb822_repo \
  "cloudflared" \
  "https://pkg.cloudflare.com/cloudflare-main.gpg" \
  "https://pkg.cloudflare.com/cloudflared/" \
  "any" \
  "main"
$STD apt install -y cloudflared
msg_ok "Installed Cloudflared"

motd_ssh
customize
cleanup_lxc
