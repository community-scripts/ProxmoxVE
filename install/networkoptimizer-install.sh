#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Ozark-Connect/NetworkOptimizer

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
echo "iperf3 iperf3/start_daemon boolean false" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive $STD apt install -y \
  git \
  sshpass \
  iperf3
setup_deb822_repo \
  "microsoft" \
  "https://packages.microsoft.com/keys/microsoft-2025.asc" \
  "https://packages.microsoft.com/debian/13/prod/" \
  "trixie"
$STD apt install -y dotnet-sdk-10.0
msg_ok "Installed Dependencies"


fetch_and_deploy_gh_release "networkoptimizer" "Ozark-Connect/NetworkOptimizer" "tarball"
GO_VERSION="$(grep -m1 '^go ' /opt/networkoptimizer/src/uwnspeedtest/go.mod | awk '{print $2}')" setup_go

msg_info "Building NetworkOptimizer"
RID="linux-x64"
[[ "$(dpkg --print-architecture)" == "arm64" ]] && RID="linux-arm64"
cd /opt/networkoptimizer
export MinVerVersionOverride="$(cat ~/.networkoptimizer)"
export MSBUILDDISABLENODEREUSE=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SYSTEM_NET_DISABLEIPV6=1
$STD dotnet publish src/NetworkOptimizer.Web -c Release -r "$RID" --self-contained -o /opt/networkoptimizer/publish
chmod +x /opt/networkoptimizer/publish/NetworkOptimizer.Web
msg_ok "Built NetworkOptimizer"

msg_info "Building Speed Test Binaries"
mkdir -p /opt/networkoptimizer/publish/tools
cd /opt/networkoptimizer/src/uwnspeedtest
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 $STD go build -trimpath -ldflags "-s -w" -o /opt/networkoptimizer/publish/tools/uwnspeedtest-linux-arm64 .
[[ "$(arch_resolve)" != "arm64" ]] && CGO_ENABLED=0 GOOS=linux GOARCH="$(arch_resolve)" $STD go build -trimpath -ldflags "-s -w" -o "/opt/networkoptimizer/publish/tools/uwnspeedtest-linux-$(arch_resolve)" .
msg_ok "Built Speed Test Binaries"

msg_info "Configuring NetworkOptimizer"
cat <<EOF >/opt/networkoptimizer/networkoptimizer.env
ASPNETCORE_URLS=http://*:8042
HOST_IP=${LOCAL_IP}
Iperf3Server__Enabled=true
EOF
msg_ok "Configured NetworkOptimizer"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/networkoptimizer.service
[Unit]
Description=NetworkOptimizer
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/networkoptimizer/publish
EnvironmentFile=/opt/networkoptimizer/networkoptimizer.env
ExecStart=/opt/networkoptimizer/publish/NetworkOptimizer.Web
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now networkoptimizer
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
