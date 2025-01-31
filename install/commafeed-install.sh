#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y rsync
msg_ok "Installed Dependencies"

msg_info "Installing Azul Zulu"
wget -qO /etc/apt/trusted.gpg.d/zulu-repo.asc "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xB1998361219BD9C9"
wget -q https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-3_all.deb
$STD dpkg -i zulu-repo_1.0.0-3_all.deb
$STD apt-get update
$STD apt-get -y install zulu17-jdk
msg_ok "Installed Azul Zulu"

RELEASE=$(curl -sL https://api.github.com/repos/Athou/commafeed/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
msg_info "Installing CommaFeed ${RELEASE}"
mkdir /opt/commafeed
wget -q https://github.com/Athou/commafeed/releases/download/${RELEASE}/commafeed-${RELEASE}-h2-jvm.zip
unzip -q commafeed-${RELEASE}-h2-jvm.zip
mv commafeed-${RELEASE}-h2/* /opt/commafeed/
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed CommaFeed ${RELEASE}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/commafeed.service
[Unit]
Description=CommaFeed Service
After=network.target

[Service]
ExecStart=java -jar quarkus-run.jar
WorkingDirectory=/opt/commafeed/
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now commafeed.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf commafeed-${RELEASE}-h2  commafeed-${RELEASE}-h2-jvm.zip  zulu-repo_1.0.0-3_all.deb
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
