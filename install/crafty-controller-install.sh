#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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

msg_info "Setting up TemurinJDK"
setup_java
$STD apt install -y temurin-{8,11,17,21,25}-jre
$STD update-alternatives --set java /usr/lib/jvm/temurin-25-jre-$(arch_resolve)/bin/java
msg_ok "Installed TemurinJDK"

msg_info "Setup Python3"
$STD apt install -y \
  python3-dev \
  python3-pip \
  python3-venv
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
msg_ok "Setup Python3"

useradd crafty -m -s /bin/bash
mkdir -p /opt/crafty-controller/crafty /opt/crafty-controller/server
fetch_and_deploy_gl_release "Crafty-Controller" "crafty-controller/crafty-4" "tarball" "latest" "/opt/crafty-controller/crafty/crafty-4"

msg_info "Installing Crafty-Controller dependencies (Patience)"
cd /opt/crafty-controller/crafty
python3 -m venv .venv
chown -R crafty:crafty /opt/crafty-controller/
$STD sudo -u crafty bash -c '
    source /opt/crafty-controller/crafty/.venv/bin/activate
    cd /opt/crafty-controller/crafty/crafty-4
    pip3 install --no-cache-dir -r requirements.txt
'
msg_ok "Installed Crafty-Controller dependencies"

msg_info "Setting up service"
cat <<EOF >/etc/systemd/system/crafty-controller.service
[Unit]
Description=Crafty 4
After=network.target

[Service]
Type=simple
User=crafty
WorkingDirectory=/opt/crafty-controller/crafty/crafty-4
Environment=PATH=/usr/lib/jvm/temurin-25-jre-$(arch_resolve)/bin:/opt/crafty-controller/crafty/.venv/bin:$PATH
ExecStart=/opt/crafty-controller/crafty/.venv/bin/python3 main.py -d
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
$STD systemctl enable -q --now crafty-controller
CREDS_FILE="/opt/crafty-controller/crafty/crafty-4/app/config/default-creds.txt"
for i in $(seq 1 30); do
  [[ -f "$CREDS_FILE" ]] && break
  sleep 2
done
if [[ -f "$CREDS_FILE" ]]; then
  cat <<EOF >~/crafty-controller.creds
Crafty-Controller-Credentials
Username: $(grep -oP '(?<="username": ")[^"]*' "$CREDS_FILE")
Password: $(grep -oP '(?<="password": ")[^"]*' "$CREDS_FILE")
EOF
fi
msg_ok "Service started"
motd_ssh
customize
cleanup_lxc
