#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sysadminsmedia/homebox

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
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
  mc
msg_ok "Installed Dependencies"

msg_info "Installing Homebox"
RELEASE=$(curl -s https://api.github.com/repos/sysadminsmedia/homebox/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -qO- https://github.com/sysadminsmedia/homebox/releases/download/${RELEASE}/homebox_Linux_x86_64.tar.gz | tar -xzf - -C /opt
chmod +x /opt/homebox
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Homebox"

msg_info "Creating Blank ENV File"
touch /opt/.env
msg_info "Created Blank ENV File"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/homebox.service
[Unit]
Description=Start Homebox Service
After=network.target

[Service]
WorkingDirectory=/opt
ExecStart=/opt/homebox \\
  --mode/\$HBOX_MODE \\
  --web-port/\$HBOX_WEB_PORT \\
  --web-host/\$HBOX_WEB_HOST \\
  --web-max-upload-size/\$HBOX_WEB_MAX_UPLOAD_SIZE \\
  --storage-data/\$HBOX_STORAGE_DATA \\
  --storage-sqlite-url/\$HBOX_STORAGE_SQLITE_URL \\
  --log-level/\$HBOX_LOG_LEVEL \\
  --log-format/\$HBOX_LOG_FORMAT \\
  --mailer-host/\$HBOX_MAILER_HOST \\
  --mailer-port/\$HBOX_MAILER_PORT \\
  --mailer-username/\$HBOX_MAILER_USERNAME \\
  --mailer-password/\$HBOX_MAILER_PASSWORD \\
  --mailer-from/\$HBOX_MAILER_FROM \\
  --swagger-host/\$HBOX_SWAGGER_HOST \\
  --swagger-scheme/\$HBOX_SWAGGER_SCHEME \\
  --demo/\$HBOX_DEMO \\
  --debug-enabled/\$HBOX_DEBUG_ENABLED \\
  --debug-port/\$HBOX_DEBUG_PORT \\
  --options-allow-registration/\$HBOX_OPTIONS_ALLOW_REGISTRATION \\
  --options-auto-increment-asset-id/\$HBOX_OPTIONS_AUTO_INCREMENT_ASSET_ID \\
  --options-currency-config/\$HBOX_OPTIONS_CURRENCY_CONFIG
EnvironmentFile=/opt/.env
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now homebox.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
