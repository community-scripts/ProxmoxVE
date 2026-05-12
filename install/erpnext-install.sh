#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/frappe/erpnext

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  build-essential \
  python3-dev \
  libffi-dev \
  libssl-dev \
  redis-server \
  nginx \
  supervisor \
  fail2ban \
  xvfb \
  libfontconfig1 \
  libxrender1 \
  fontconfig \
  libjpeg-dev \
  libmariadb-dev \
  python3-pip
msg_ok "Installed Dependencies"

NODE_VERSION="24" NODE_MODULE="yarn" setup_nodejs
UV_PYTHON="3.13" setup_uv
setup_mariadb

msg_info "Configuring MariaDB for ERPNext"
cat <<EOF >/etc/mysql/mariadb.conf.d/50-erpnext.cnf
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

[client]
default-character-set=utf8mb4
EOF
$STD systemctl restart mariadb
msg_ok "Configured MariaDB for ERPNext"

msg_info "Installing wkhtmltopdf"
WKHTMLTOPDF_URL="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb"
$STD curl -fsSL -o /tmp/wkhtmltox.deb "$WKHTMLTOPDF_URL"
$STD apt install -y /tmp/wkhtmltox.deb
rm -f /tmp/wkhtmltox.deb
msg_ok "Installed wkhtmltopdf"

msg_info "Installing Frappe Bench"
useradd -m -s /bin/bash frappe
chown frappe:frappe /opt
echo "frappe ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/frappe
$STD sudo -u frappe bash -c 'export PATH="$HOME/.local/bin:$PATH"; uv tool install frappe-bench'
msg_ok "Installed Frappe Bench"

msg_info "Initializing Frappe Bench"
ADMIN_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
DB_ROOT_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}'; FLUSH PRIVILEGES;"
$STD sudo -u frappe bash -c 'export PATH="$HOME/.local/bin:$PATH"; cd /opt && bench init --frappe-branch version-15 frappe-bench'
$STD sudo -u frappe bash -c 'export PATH="$HOME/.local/bin:$PATH"; cd /opt/frappe-bench && bench get-app erpnext --branch version-15'

msg_info "Starting Redis Services for Site Setup"
$STD sudo -u frappe bash -c 'redis-server /opt/frappe-bench/config/redis_queue.conf --daemonize yes'
$STD sudo -u frappe bash -c 'redis-server /opt/frappe-bench/config/redis_cache.conf --daemonize yes'
sleep 3
msg_ok "Started Redis Services for Site Setup"

$STD sudo -u frappe bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\"; cd /opt/frappe-bench && bench new-site site1.local --db-root-username root --db-root-password \"$DB_ROOT_PASS\" --admin-password \"$ADMIN_PASS\" --install-app erpnext --set-default"
msg_ok "Initialized Frappe Bench"

msg_info "Configuring ERPNext"
cat <<EOF >/opt/frappe-bench/.env
ADMIN_PASSWORD=${ADMIN_PASS}
DB_ROOT_PASSWORD=${DB_ROOT_PASS}
SITE_NAME=site1.local
EOF
{
  echo "ERPNext Credentials"
  echo "=================="
  echo "Admin Username: Administrator"
  echo "Admin Password: ${ADMIN_PASS}"
  echo "DB Root Password: ${DB_ROOT_PASS}"
  echo "Site Name: site1.local"
} >~/erpnext.creds
$STD systemctl enable --now redis-server
msg_ok "Configured ERPNext"

msg_info "Setting up Production"
BENCH_PY="/home/frappe/.local/share/uv/tools/frappe-bench/bin/python"
$STD sudo -u frappe bash -c "curl -fsSL https://bootstrap.pypa.io/get-pip.py | \"${BENCH_PY}\""
$STD sudo -u frappe bash -c 'export PATH="$HOME/.local/bin:$PATH"; uv tool install ansible'
ln -sf /home/frappe/.local/bin/ansible* /usr/local/bin/
$STD bash -c 'export PATH="/home/frappe/.local/bin:$PATH"; cd /opt/frappe-bench && bench setup production frappe --yes'
ln -sf /opt/frappe-bench/config/supervisor.conf /etc/supervisor/conf.d/frappe-bench.conf
$STD supervisorctl reread
$STD supervisorctl update
$STD systemctl enable --now supervisor
msg_ok "Set up Production"

motd_ssh
customize
cleanup_lxc
