#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT |  https://github.com/tteck/Proxmox/raw/main/LICENSE
# Source: https://github.com/odoo/odoo

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

ensure_lxml_html_clean() {
  ensure_dependencies python3-lxml
  if apt-cache show python3-lxml-html-clean &>/dev/null; then
    ensure_dependencies python3-lxml-html-clean
  else
    curl -fsSL "http://archive.ubuntu.com/ubuntu/pool/universe/l/lxml-html-clean/python3-lxml-html-clean_0.1.1-1_all.deb" -o /opt/python3-lxml-html-clean.deb
    $STD dpkg -i /opt/python3-lxml-html-clean.deb
    $STD apt-get install -f -y
    rm -f /opt/python3-lxml-html-clean.deb
  fi
  if ! python3 -c "import lxml_html_clean; from lxml.html import clean" 2>/dev/null; then
    msg_error "lxml.html.clean is not available (python3-lxml-html-clean required)"
    exit 1
  fi
}

msg_info "Installing Dependencies"
$STD apt install -y wkhtmltopdf
ensure_lxml_html_clean
msg_ok "Installed Dependencies"

PG_VERSION="18" setup_postgresql

RELEASE=$(curl -fsSL https://nightly.odoo.com/ | grep -oE 'href="[0-9]+\.[0-9]+/nightly"' | head -n1 | cut -d'"' -f2 | cut -d/ -f1)
LATEST_VERSION=$(curl -fsSL "https://nightly.odoo.com/${RELEASE}/nightly/deb/" |
  grep -oP "odoo_${RELEASE}\.\d+_all\.deb" |
  sed -E "s/odoo_(${RELEASE}\.[0-9]+)_all\.deb/\1/" |
  sort -V |
  tail -n1)

msg_info "Setup Odoo $RELEASE"
curl -fsSL https://nightly.odoo.com/${RELEASE}/nightly/deb/odoo_${RELEASE}.latest_all.deb -o /opt/odoo.deb
$STD apt install -y /opt/odoo.deb
ensure_lxml_html_clean
msg_ok "Setup Odoo $RELEASE"

msg_info "Setup PostgreSQL Database"
DB_NAME="odoo"
DB_USER="odoo_usr"
DB_PASS="$(openssl rand -base64 18 | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
$STD sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
$STD sudo -u postgres psql -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"
$STD sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"
{
  echo "Odoo-Credentials"
  echo -e "Odoo Database User: $DB_USER"
  echo -e "Odoo Database Password: $DB_PASS"
  echo -e "Odoo Database Name: $DB_NAME"
} >>~/odoo.creds
msg_ok "Setup PostgreSQL"

msg_info "Configuring Odoo"
sed -i \
  -e "s|^;*db_host *=.*|db_host = localhost|" \
  -e "s|^;*db_port *=.*|db_port = 5432|" \
  -e "s|^;*db_user *=.*|db_user = $DB_USER|" \
  -e "s|^;*db_password *=.*|db_password = $DB_PASS|" \
  /etc/odoo/odoo.conf
$STD sudo -u odoo odoo -c /etc/odoo/odoo.conf -d odoo -i base --stop-after-init
rm -f /opt/odoo.deb
echo "${LATEST_VERSION}" >/opt/${APPLICATION}_version.txt
msg_ok "Configured Odoo"

msg_info "Restarting Odoo"
systemctl restart odoo
msg_ok "Restarted Odoo"

motd_ssh
customize
cleanup_lxc
