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
$STD apt-get install -y gpg
msg_ok "Installed Dependencies"

msg_info "Installing Mosquitto MQTT Broker"
source /etc/os-release
curl -fsSL http://repo.mosquitto.org/debian/mosquitto-repo.gpg.key >/usr/share/keyrings/mosquitto-repo.gpg.key
chmod go+r /usr/share/keyrings/mosquitto-repo.gpg.key
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mosquitto-repo.gpg.key] http://repo.mosquitto.org/debian ${VERSION_CODENAME} main" >/etc/apt/sources.list.d/mosquitto.list
$STD apt-get update
$STD apt-get -y install mosquitto
$STD apt-get -y install mosquitto-clients
cat <<EOF >/etc/mosquitto/conf.d/default.conf
allow_anonymous false
persistence true
password_file /etc/mosquitto/passwd
listener 1883
EOF
msg_ok "Installed Mosquitto MQTT Broker"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
