#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: SystemIdleProcess
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/caronc/apprise-api

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  nginx \
  git
msg_ok "Installed Dependencies" 

PYTHON_VERSION="3.12" setup_uv
fetch_and_deploy_gh_release "apprise" "caronc/apprise-api" "tarball"

msg_info "Setup Apprise-API"
cd /opt/apprise
cp ./requirements.txt /etc/requirements.txt
$STD uv pip install -r requirements.txt gunicorn supervisor --system
cp -fr apprise_api/static /usr/share/nginx/html/s/
mv apprise_api/ webapp
touch /etc/nginx/server-override.conf
touch /etc/nginx/location-override.conf
mkdir -p /config/store /attach /plugin /tmp/apprise /opt/apprise/logs
chmod 1777 /tmp/apprise && chmod 777 /config /config/store /attach /plugin /opt/apprise/logs
sed -i \
  -e '/[[]program:nginx]/,/^[[]/ s|stdout_logfile=/dev/stdout|stdout_logfile=/opt/apprise/logs/nginx.log|' \
  -e '/[[]program:nginx]/,/^[[]/ s|stderr_logfile=/dev/stderr|stderr_logfile=/opt/apprise/logs/nginx_error.log|' \
  -e '/[[]program:gunicorn]/,/^[[]/ s|stdout_logfile=/dev/stdout|stdout_logfile=/opt/apprise/logs/gunicorn.log|' \
  -e '/[[]program:gunicorn]/,/^[[]/ s|stderr_logfile=/dev/stderr|stderr_logfile=/opt/apprise/logs/gunicorn_error.log|' \
  -e '/[[]supervisord]/,/^[[]/ s|logfile=/dev/null|logfile=/opt/apprise/logs/supervisor.log|' \
  -e 's|_maxbytes=0|_maxbytes=10485760|g' \
  /opt/apprise/webapp/etc/supervisord.conf
msg_ok "Setup Apprise-API"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/apprise-api.service
[Unit]
Description=Apprise-API Service
After=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/apprise
ExecStart=/opt/apprise/webapp/supervisord-startup
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now apprise-api
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
