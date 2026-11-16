#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Kaedon Cleland-Host (dracentis)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://mattermost.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

confirm_external_installer "https://mattermost.com/" "https://deb.packages.mattermost.com/repo-setup.sh"

PG_VERSION="16" setup_postgresql

PG_DB_NAME="mattermost" PG_DB_USER="mmuser" setup_postgresql_db

msg_info "Installing Mattermost"
curl -fsSL -o /usr/share/keyrings/mattermost-archive-keyring.gpg https://deb.packages.mattermost.com/pubkey.gpg
sh -c 'curl -fsSL https://deb.packages.mattermost.com/repo-setup.sh | sudo bash -s mattermost' >/dev/null
apt_update_safe
$STD apt install -y mattermost
$STD install -C -m 600 -o mattermost -g mattermost /opt/mattermost/config/config.defaults.json /opt/mattermost/config/config.json
sed -i -e "/DataSource/c\   \"DataSource\": \"postgres://mmuser:$PG_DB_PASS@localhost:5432/mattermost?sslmode=disable&connect_timeout=10\"," \
  -e "/SiteURL/c\   \"SiteURL\": \"http://$LOCAL_IP:8065\"," /opt/mattermost/config/config.json
systemctl enable -q --now mattermost
msg_ok "Installed Mattermost"

motd_ssh
customize
cleanup_lxc
