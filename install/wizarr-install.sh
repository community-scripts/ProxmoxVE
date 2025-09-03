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
$STD apt-get install -y sqlite3
msg_ok "Installed Dependencies"

setup_uv
NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "wizarr" "wizarrrr/wizarr"

msg_info "Configure ${APPLICATION}"
cd /opt/wizarr
$STD /usr/local/bin/uv lock
$STD /usr/local/bin/uv sync --locked
$STD /usr/local/bin/uv run pybabel compile -d app/translations
$STD npm --prefix app/static install
$STD npm --prefix app/static run build:css
mkdir -p ./.cache
$STD /usr/local/bin/uv run flask db upgrade
msg_ok "Configure ${APPLICATION}"

msg_info "Creating env, start script and service"
LOCAL_IP="$(hostname -I | awk '{print $1}')"
cat <<EOF >/opt/wizarr/.env
APP_URL=http://${LOCAL_IP}
DISABLE_BUILTIN_AUTH=false
LOG_LEVEL=INFO
EOF

cat <<EOF >/opt/wizarr/start.sh
#!/usr/bin/env bash

uv run gunicorn \
    --config gunicorn.conf.py \
    --preload \
    --workers 4 \
    --bind 0.0.0.0:5690 \
    --umask 007 \
    run:app
EOF
chmod u+x /opt/wizarr/start.sh

cat <<EOF >/etc/systemd/system/wizarr.service
[Unit]
Description=${APPLICATION} Service
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
msg_ok "Created env, start script and service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
