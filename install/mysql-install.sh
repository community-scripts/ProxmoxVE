#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.mysql.com/products/community | https://www.phpmyadmin.net

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  lsb-release
msg_ok "Installed Dependencies"

RELEASE_REPO="mysql-8.0"
RELEASE_AUTH="mysql_native_password"
read -r -p "${TAB3}Would you like to install the MySQL 8.4 LTS release instead of MySQL 8.0 (bug fix track; EOL April-2026)? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  RELEASE_REPO="mysql-8.4-lts"
  RELEASE_AUTH="caching_sha2_password"
fi

msg_info "Installing MySQL"
curl -fsSL https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 | gpg --dearmor -o /usr/share/keyrings/mysql.gpg
if [ "$(lsb_release -si)" = "Debian" ]; then
  cat <<EOF >/etc/apt/sources.list.d/mysql.sources
Types: deb
URIs: http://repo.mysql.com/apt/debian
Suites: $(lsb_release -sc)
Components: ${RELEASE_REPO}
Signed-By: /usr/share/keyrings/mysql.gpg
EOF
else
  cat <<EOF >/etc/apt/sources.list.d/mysql.sources
Types: deb
URIs: http://repo.mysql.com/apt/ubuntu
Suites: $(lsb_release -sc)
Components: ${RELEASE_REPO}
Signed-By: /usr/share/keyrings/mysql.gpg
EOF
fi
$STD apt update
export DEBIAN_FRONTEND=noninteractive
$STD apt install -y \
  mysql-community-client \
  mysql-community-server
msg_ok "Installed MySQL"

msg_info "Configure MySQL Server"
ADMIN_PASS="$(openssl rand -base64 18 | cut -c1-13)"
$STD mysql -uroot -p"$ADMIN_PASS" -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH $RELEASE_AUTH BY '$ADMIN_PASS'; FLUSH PRIVILEGES;"
echo "" >~/mysql.creds
echo -e "MySQL user: root" >>~/mysql.creds
echo -e "MySQL password: $ADMIN_PASS" >>~/mysql.creds
msg_ok "MySQL Server configured"

read -r -p "${TAB3}Would you like to add PhpMyAdmin? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/phpmyadmin.sh)"
fi

msg_info "Start Service"
systemctl enable -q --now mysql
msg_ok "Service started"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
