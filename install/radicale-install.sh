#!/usr/bin/env bash

#Copyright (c) 2021-2025 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y apache2-utils python3-pip python3.11-venv
msg_ok "Installed Dependencies"

msg_info "Setting up Radicale"
sleep 2
python3 -m venv /opt/radicale
source /opt/radicale/bin/activate
python3 -m pip install --upgrade https://github.com/Kozea/Radicale/archive/master.tar.gz
msg_ok "Setup Radicale"
msg_ok "Setting up admin user password:"
sleep 2
htpasswd -c -5 /opt/radicale/users admin

msg_info "Setup Service"

cat <<EOF >/opt/radicale/start.sh
#!/usr/bin/env bash
source /opt/radicale/bin/activate
python3 -m radicale --storage-filesystem-folder=/var/lib/radicale/collections --hosts 0.0.0.0:5232 --auth-type htpasswd --auth-htpasswd-filename /opt/radicale/users --auth-htpasswd-encryption sha512
EOF

chmod +x /opt/radicale/start.sh

cat <<EOF >/etc/systemd/system/radicale.service
Description=A simple CalDAV (calendar) and CardDAV (contact) server
After=network.target
Requires=network.target

[Service]
ExecStart=/opt/radicale/start.sh
Restart=on-failure
# User=radicale
# Deny other users access to the calendar data
# UMask=0027

[Install]
WantedBy=multi-user.target
EOF
msg_ok "Created Service"
systemctl start radicale

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"