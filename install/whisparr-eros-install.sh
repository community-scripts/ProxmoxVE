#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: angusmaul
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Whisparr/Whisparr-Eros

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y sqlite3 libicu-dev
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "whisparr-eros" "Whisparr/Whisparr-Eros" "prebuild" "latest" "/opt/Whisparr-Eros" "Whisparr.eros.*.linux-$(arch_resolve "x64" "arm64").tar.gz"

msg_info "Configuring Whisparr-Eros"
rm -rf /opt/Whisparr-Eros/Whisparr.Update
chmod +x /opt/Whisparr-Eros/Whisparr
mkdir -p /var/lib/whisparr-eros/
chmod 775 /var/lib/whisparr-eros/ /opt/Whisparr-Eros/
msg_ok "Configured Whisparr-Eros"

msg_info "Creating Service"
WHISPARR_PASS=$(random_password 20)
cat <<EOF >/etc/systemd/system/whisparr-eros.service
[Unit]
Description=Whisparr-Eros Daemon
After=syslog.target network.target

[Service]
UMask=0002
Type=simple
Environment=WHISPARR__AUTH__INITIALPASSWORD=${WHISPARR_PASS}
ExecStart=/opt/Whisparr-Eros/Whisparr -nobrowser -data=/var/lib/whisparr-eros/
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now whisparr-eros
for _ in {1..60}; do
  grep -qs "created 'whisparr' with the configured password" /var/lib/whisparr-eros/logs/whisparr.txt && break
  sleep 2
done
sed -i '/WHISPARR__AUTH__INITIALPASSWORD/d' /etc/systemd/system/whisparr-eros.service
systemctl daemon-reload
cat <<EOF >~/whisparr-eros.creds
Whisparr-Eros Credentials
Username: whisparr
Password: ${WHISPARR_PASS}
EOF
chmod 600 ~/whisparr-eros.creds
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
