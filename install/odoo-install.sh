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

fetch_and_deploy_gh_release "wkhtmltopdf" "wkhtmltopdf/packaging" "binary" "latest" "" "wkhtmltox_*.bookworm_$(arch_resolve).deb"

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
msg_ok "Setup Odoo $RELEASE"

PG_DB_NAME="odoo" PG_DB_USER="odoo_usr" PG_DB_GRANT_SUPERUSER="true" setup_postgresql_db

msg_info "Configuring Odoo"
sed -i \
  -e "s|^;*db_host *=.*|db_host = localhost|" \
  -e "s|^;*db_port *=.*|db_port = 5432|" \
  -e "s|^;*db_user *=.*|db_user = odoo_usr|" \
  -e "s|^;*db_password *=.*|db_password = $PG_DB_PASS|" \
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
