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
if [[ "$(arch_resolve)" == "arm64" ]]; then
  # packages.microsoft.com only ships amd64 debs for Debian; use dotnet-install on arm64
  curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
  $STD bash /tmp/dotnet-install.sh --channel 10.0 --runtime aspnetcore --install-dir /usr/lib/dotnet10
  ln -sf /usr/lib/dotnet10/dotnet /usr/bin/dotnet
  rm -f /tmp/dotnet-install.sh
else
  setup_deb822_repo \
    "microsoft" \
    "https://packages.microsoft.com/keys/microsoft-2025.asc" \
    "https://packages.microsoft.com/debian/13/prod/" \
    "trixie"
  $STD apt install -y aspnetcore-runtime-10.0
fi
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
  read -r -p "${TAB3}Enter FileFlows Server URL (e.g. http://192.168.1.10:19200): " server_url
  while [[ -z "${server_url// /}" ]]; do
    read -r -p "${TAB3}Enter FileFlows Server URL (e.g. http://192.168.1.10:19200): " server_url
  done
  cd /opt/fileflows/Node
  $STD dotnet FileFlows.Node.dll --server "$server_url" --systemd install --root true
  systemctl enable -q --now fileflows-node
  msg_ok "Installed FileFlows Node"
fi

motd_ssh
customize
cleanup_lxc
