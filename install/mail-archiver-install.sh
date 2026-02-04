#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/s1t5/mail-archiver

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
$STD apt install -y \
  dotnet-sdk-10.0 \
  aspnetcore-runtime-8.0
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="mailarchiver_db" PG_DB_USER="mailarchiver" setup_postgresql_db
fetch_and_deploy_gh_release "mail-archiver" "s1t5/mail-archiver" "tarball"

msg_info "Setting up Mail-Archiver"
mv /opt/mail-archiver /opt/mail-archiver-build
cd /opt/mail-archiver-build
$STD dotnet restore
$STD dotnet publish -c Release -o /opt/mail-archiver
cp /opt/mail-archiver-build/appsettings.json /opt/mail-archiver/appsettings.json
sed -i "s|\"DefaultConnection\": \"[^\"]*\"|\"DefaultConnection\": \"Host=localhost;Database=mailarchiver_db;Username=mailarchiver;Password=$PG_DB_PASS\"|" /opt/mail-archiver/appsettings.json
rm -rf /opt/mail-archiver-build

cat <<EOF >/opt/mail-archiver/.env
ASPNETCORE_URLS=http://+:5000
ASPNETCORE_ENVIRONMENT=Production
TZ=UTC
EOF
msg_ok "Setup Mail-Archiver"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/mail-archiver.service
[Unit]
Description=Mail-Archiver Service
After=network.target

[Service]
EnvironmentFile=/opt/mail-archiver/.env
WorkingDirectory=/opt/mail-archiver
ExecStart=/usr/bin/dotnet MailArchiver.dll
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now mail-archiver
msg_info "Created Service"

motd_ssh
customize
cleanup_lxc
