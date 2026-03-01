#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: kkroboth
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://fileflows.com/

# Import Functions und Setup
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  ffmpeg \
  imagemagick
msg_ok "Installed Dependencies"

setup_hwaccel

msg_info "Installing ASP.NET Core Runtime"
setup_deb822_repo \
  "microsoft" \
  "https://packages.microsoft.com/keys/microsoft-2025.asc" \
  "https://packages.microsoft.com/debian/13/prod/" \
  "trixie"
$STD apt install -y aspnetcore-runtime-8.0
msg_ok "Installed ASP.NET Core Runtime"

fetch_and_deploy_from_url "https://fileflows.com/downloads/zip" "/opt/fileflows"

msg_info "Setup FileFlows"
$STD ln -svf /usr/bin/ffmpeg /usr/local/bin/ffmpeg
$STD ln -svf /usr/bin/ffprobe /usr/local/bin/ffprobe
cd /opt/fileflows/Server
dotnet FileFlows.Server.dll --systemd install --root true
systemctl enable -q --now fileflows
msg_ok "Setup FileFlows"

motd_ssh
customize
cleanup_lxc
