#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/StarFleetCPTN/GoMFT

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    curl \
    sudo \
    mc \
    sqlite3 \
    rclone \
    tzdata \
    ca-certificates
msg_ok "Installed Dependencies"

msg_info "Setting up Golang"
set +o pipefail
temp_file=$(mktemp)
golang_tarball=$(curl -s https://go.dev/dl/ | grep -oP 'go[\d\.]+\.linux-amd64\.tar\.gz' | head -n 1)
wget -q https://golang.org/dl/"$golang_tarball" -O "$temp_file"
tar -C /usr/local -xzf "$temp_file"
ln -sf /usr/local/go/bin/go /usr/local/bin/go
set -o pipefail
msg_ok "Setup Golang"

msg_info "Setup ${APPLICATION}"
temp_file2=$(mktemp)
RELEASE=$(curl -s https://api.github.com/repos/StarFleetCPTN/GoMFT/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/StarFleetCPTN/GoMFT/archive/refs/tags/v${RELEASE}.tar.gz" -O $temp_file2
tar -xzf $temp_file2
mv GoMFT-${RELEASE}/ /opt/gomft
cd /opt/gomft
$STD go install github.com/a-h/templ/cmd/templ@latest
wget -q "https://github.com/StarFleetCPTN/GoMFT/releases/download/v${RELEASE}/gomft-v${RELEASE}-linux-amd64" -O gomft
$STD $HOME/go/bin/templ generate
chmod +x gomft
JWT_SECRET_KEY=$(openssl rand -base64 24 | tr -d '/+=')

cat <<EOF >/opt/gomft/.env
SERVER_ADDRESS=:8080
DATA_DIR=/opt/gomft/data/gomft
BACKUP_DIR=/opt/gomft/data/gomft/backups
JWT_SECRET=$JWT_SECRET_KEY
BASE_URL=http://localhost:8080

# Email configuration
EMAIL_ENABLED=false
EMAIL_HOST=smtp.example.com
EMAIL_PORT=587
EMAIL_FROM_EMAIL=gomft@example.com
EMAIL_FROM_NAME=GoMFT
EMAIL_REPLY_TO=
EMAIL_ENABLE_TLS=true
EMAIL_REQUIRE_AUTH=true
EMAIL_USERNAME=smtp_username
EMAIL_PASSWORD=smtp_password
EOF

echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Setup ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/gomft.service
[Unit]
Description=GoMFT Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/gomft
ExecStart=/opt/gomft/./gomft
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now gomft
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f $temp_file $temp_file2
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize
