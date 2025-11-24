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

LOCAL_IP="$(hostname -I | awk '{print $1}')"
VERSION="$(sed 's/^20/v&/' ~/.wizarr)"
cat <<EOF >/opt/wizarr/.env
FLASK_ENV=production
GUNICORN_WORKERS=4
APP_URL=http://${LOCAL_IP}
DISABLE_BUILTIN_AUTH=false
LOG_LEVEL=INFO
APP_VERSION=${VERSION}
EOF

cat <<EOF >/opt/wizarr/start.sh
#!/usr/bin/env bash

uv run --frozen gunicorn \
    --config gunicorn.conf.py \
    --preload \
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
msg_ok "Created Service"

msg_info "Running DB upgrade"
export FLASK_SKIP_SCHEDULER=true
$STD /usr/local/bin/uv run --frozen flask db upgrade
msg_ok "DB upgrade complete"

systemctl enable -q --now wizarr

motd_ssh
customize
cleanup_lxc
