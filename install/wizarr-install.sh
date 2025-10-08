#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wizarrrr/wizarr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y sqlite3
msg_ok "Installed Dependencies"

setup_uv
NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "wizarr" "wizarrrr/wizarr"

msg_info "Configure Wizarr"
cd /opt/wizarr || exit
$STD /usr/local/bin/uv sync --frozen
$STD /usr/local/bin/uv run --frozen pybabel compile -d app/translations
$STD npm --prefix app/static install
$STD npm --prefix app/static run build:css
mkdir -p ./.cache
$STD /usr/local/bin/uv run --frozen flask db upgrade

LOCAL_IP="$(hostname -I | awk '{print $1}')"
cat <<EOF >/opt/wizarr/.env
APP_URL=http://${LOCAL_IP}
DISABLE_BUILTIN_AUTH=false
LOG_LEVEL=INFO
EOF

cat <<EOF >/opt/wizarr/start.sh
#!/usr/bin/env bash

uv run --frozen gunicorn \
    --config gunicorn.conf.py \
    --preload \
    --workers 4 \
    --bind 0.0.0.0:5690 \
    --umask 007 \
    run:app
EOF
chmod u+x /opt/wizarr/start.sh
msg_ok "Configure Wizarr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wizarr.service
[Unit]
Description=Wizarr Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/wizarr
EnvironmentFile=/opt/wizarr/.env
ExecStart=/opt/wizarr/start.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wizarr
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
