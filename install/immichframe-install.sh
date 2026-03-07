#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Thiago Canozzo Lahr (tclahr)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/immichFrame/ImmichFrame

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
setup_deb822_repo \
  "microsoft" \
  "https://packages.microsoft.com/keys/microsoft-2025.asc" \
  "https://packages.microsoft.com/debian/13/prod/" \
  "trixie" \
  "main"
$STD apt-get install -y \
  libicu-dev \
  libssl-dev \
  gettext-base \
  dotnet-sdk-8.0 \
  aspnetcore-runtime-8.0
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "immichframe" "immichFrame/ImmichFrame" "tarball" "latest" "/tmp/immichframe"

msg_info "Building Application"
mkdir -p /opt/immichframe
cd /tmp/immichframe
$STD dotnet publish ImmichFrame.WebApi/ImmichFrame.WebApi.csproj \
  --configuration Release \
  --runtime linux-x64 \
  --self-contained false \
  --output /opt/immichframe
cd /tmp/immichframe/immichFrame.Web
$STD npm ci
$STD npm run build
cp -r build/* /opt/immichframe/wwwroot
msg_ok "Application Built"

msg_info "Removing Build Dependencies"
$STD apt-get remove -y dotnet-sdk-8.0
$STD apt-get autoremove -y
rm -rf /tmp/immichframe
msg_ok "Removed Build Dependencies"

msg_info "Configuring ImmichFrame"
mkdir -p /opt/immichframe/Config
curl -fsSL "https://raw.githubusercontent.com/immichFrame/ImmichFrame/main/docker/Settings.example.yml" \
  -o /opt/immichframe/Config/Settings.yml
msg_ok "Configured ImmichFrame"

msg_info "Creating immichframe User"
useradd -r -s /sbin/nologin -d /opt/immichframe -M immichframe 2>/dev/null
chown -R immichframe:immichframe /opt/immichframe
msg_ok "User immichframe Created"

msg_info "Creating Service"
cat <<'EOF' >/etc/systemd/system/immichframe.service
[Unit]
Description=ImmichFrame Digital Photo Frame
After=network.target

[Service]
Type=simple
User=immichframe
Group=immichframe

WorkingDirectory=/opt/immichframe
ExecStart=/usr/bin/dotnet /opt/immichframe/ImmichFrame.WebApi.dll

Environment=ASPNETCORE_URLS=http://0.0.0.0:8080
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_CONTENTROOT=/opt/immichframe

Restart=always
RestartSec=5

StandardOutput=journal
StandardError=journal
SyslogIdentifier=immichframe

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now immichframe
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
