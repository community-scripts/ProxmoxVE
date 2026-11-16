#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bugsink/bugsink

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PYTHON_VERSION="3.12" setup_uv

msg_info "Installing Bugsink"
BUGSINK_VERSION="${var_appversion:-$(get_latest_github_release "bugsink/bugsink")}"
$STD uv venv --python 3.12 /opt/bugsink/.venv
$STD uv pip install --python /opt/bugsink/.venv/bin/python "bugsink==${BUGSINK_VERSION}"
cat <<EOF >~/.bugsink
${BUGSINK_VERSION}
EOF
msg_ok "Installed Bugsink"

msg_info "Configuring Bugsink"
ADMIN_EMAIL="${var_admin_email:-admin@localhost}"
ADMIN_PASS="${var_admin_pass:-$(random_password)}"
mkdir -p /opt/bugsink_data
cd /opt/bugsink_data
$STD /opt/bugsink/.venv/bin/bugsink-create-conf --template=singleserver --host="${LOCAL_IP}" --base-dir=/opt/bugsink_data
sed -i \
  -e "s|\"BASE_URL\": \"https://${LOCAL_IP}\"|\"BASE_URL\": \"http://${LOCAL_IP}:8000\"|" \
  -e 's|^SESSION_COOKIE_SECURE = True|SESSION_COOKIE_SECURE = False|' \
  -e 's|^CSRF_COOKIE_SECURE = True|CSRF_COOKIE_SECURE = False|' \
  -e 's|^USE_X_REAL_IP = True|USE_X_REAL_IP = False|' \
  /opt/bugsink_data/bugsink_conf.py
$STD /opt/bugsink/.venv/bin/bugsink-manage migrate
$STD /opt/bugsink/.venv/bin/bugsink-manage migrate snappea --database=snappea
DJANGO_SUPERUSER_PASSWORD="$ADMIN_PASS" $STD /opt/bugsink/.venv/bin/bugsink-manage createsuperuser --noinput --username "$ADMIN_EMAIL" --email "$ADMIN_EMAIL"
cat <<EOF >/opt/bugsink_data/.env
BUGSINK_ADMIN_EMAIL=${ADMIN_EMAIL}
BUGSINK_ADMIN_PASSWORD=${ADMIN_PASS}
EOF
chmod 600 /opt/bugsink_data/.env /opt/bugsink_data/bugsink_conf.py
msg_ok "Configured Bugsink"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/bugsink.service
[Unit]
Description=Bugsink
After=network.target

[Service]
Type=notify
WorkingDirectory=/opt/bugsink_data
Environment=PYTHONUNBUFFERED=1
ExecStart=/opt/bugsink/.venv/bin/gunicorn --bind=0.0.0.0:8000 --workers=4 --max-requests=1000 --max-requests-jitter=100 --access-logfile - bugsink.wsgi
Restart=always

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/bugsink-snappea.service
[Unit]
Description=Bugsink Snappea
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/bugsink_data
Environment=PYTHONUNBUFFERED=1
ExecStart=/opt/bugsink/.venv/bin/bugsink-runsnappea
Restart=always
RuntimeMaxSec=1d

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now bugsink bugsink-snappea
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
