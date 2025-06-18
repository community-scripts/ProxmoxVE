#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.craftycontrol.com/pages/getting-started/installation/linux/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y \
  git \
  sed \
  lsb-release \
  apt-transport-https \
  coreutils \
  software-properties-common
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv

msg_info "Setting up TemurinJDK"
mkdir -p /etc/apt/keyrings
curl -fsSL "https://packages.adoptium.net/artifactory/api/gpg/key/public" | tee /etc/apt/keyrings/adoptium.asc
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
$STD apt-get update
$STD apt-get install -y temurin-{8,11,17,21}-jre
sudo update-alternatives --set java /usr/lib/jvm/temurin-21-jre-amd64/bin/java
msg_ok "Installed TemurinJDK"

msg_info "Installing Craty-Controller (Patience)"
useradd crafty -m -s /bin/bash
cd /opt
mkdir -p /opt/crafty-controller/crafty /opt/crafty-controller/server
RELEASE=$(curl -fsSL "https://gitlab.com/api/v4/projects/20430749/releases" | grep -o '"tag_name":"v[^\"]*"' | head -n 1 | sed 's/"tag_name":"v//;s/"//')
echo "${RELEASE}" >"/opt/crafty-controller_version.txt"
curl -fsSL "https://gitlab.com/crafty-controller/crafty-4/-/archive/v${RELEASE}/crafty-4-v${RELEASE}.zip" -o "crafty-4-v${RELEASE}.zip"
$STD unzip crafty-4-v${RELEASE}.zip
cp -a crafty-4-v${RELEASE}/. /opt/crafty-controller/crafty/crafty-4/
rm -rf crafty-4-v${RELEASE}

cd /opt/crafty-controller/crafty
$STD uv venv /opt/crafty-controller/crafty/.venv
chown -R crafty:crafty /opt/crafty-controller/
$STD sudo -u crafty bash -c '
    cd /opt/crafty-controller/crafty/crafty-4
    uv pip install --no-cache-dir -r requirements.txt
'
msg_ok "Installed Craft-Controller and dependencies"

msg_info "Setting up Crafty-Controller service"
cat >/etc/systemd/system/crafty-controller.service <<'EOF'
[Unit]
Description=Crafty 4
After=network.target

[Service]
Type=simple
User=crafty
WorkingDirectory=/opt/crafty-controller/crafty/crafty-4
Environment=PATH=/usr/lib/jvm/temurin-21-jre-amd64/bin:/opt/crafty-controller/crafty/.venv/bin:$PATH
ExecStart=/opt/crafty-controller/crafty/.venv/bin/python3 main.py -d
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
$STD systemctl enable -q --now crafty-controller
sleep 10
{
  echo "Crafty-Controller-Credentials"
  echo "Username: $(grep -oP '(?<="username": \")[^\"]*' /opt/crafty-controller/crafty/crafty-4/app/config/default-creds.txt)"
  echo "Password: $(grep -oP '(?<="password": \")[^\"]*' /opt/crafty-controller/crafty/crafty-4/app/config/default-creds.txt)"
} >>~/crafty-controller.creds
msg_ok "Crafty-Controller service started"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/crafty-4-v${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
