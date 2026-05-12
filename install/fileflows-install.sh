#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: kkroboth
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://fileflows.com/

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
  pciutils \
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

$STD ln -svf /usr/bin/ffmpeg /usr/local/bin/ffmpeg
$STD ln -svf /usr/bin/ffprobe /usr/local/bin/ffprobe
$STD rm -rf /opt/fileflows/Server/runtimes/win-*

read -r -p "${TAB3}Do you want to install FileFlows Server or Node? (S/N): " install_server

if [[ "$install_server" =~ ^[Ss]$ ]]; then
  msg_info "Installing FileFlows Server"
  cd /opt/fileflows/Server
  $STD dotnet FileFlows.Server.dll --systemd install --root true
  systemctl enable -q --now fileflows
  msg_ok "Installed FileFlows Server"
else
  msg_info "Installing FileFlows Node"
  cd /opt/fileflows/Node
  $STD dotnet FileFlows.Node.dll
  $STD dotnet FileFlows.Node.dll --systemd install --root true
  systemctl enable -q --now fileflows-node
  msg_ok "Installed FileFlows Node"
fi

motd_ssh
customize
cleanup_lxc
