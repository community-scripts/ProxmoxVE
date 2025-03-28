#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://mariadb.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apk add \
    newt \
    curl \
    openssh \
    nano \
    mc \
    gpg

msg_ok "Installed Dependencies"

msg_info "Installing MariaDB"
$STD apk add --no-cache mariadb mariadb-client
$STD rc-update add mariadb default
$STD rc-service mariadb start
msg_ok "Installed MariaDB"

msg_info "Configuring MariaDB"
mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql >/dev/null 2>&1
$STD rc-service mariadb restart
msg_ok "MariaDB Configured"

read -r -p "Would you like to install Adminer with lighthttpd? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
    msg_info "Installing Adminer"
    $STD apk add --no-cache lighttpd php php-cgi php-mysqli php-mbstring php-zip php-gd php-json php-curl jq
    sed -i 's|server.modules += ( "mod_cgi" )|server.modules += ( "mod_cgi", "mod_fastcgi" )|' /etc/lighttpd/lighttpd.conf
    echo 'fastcgi.server += ( ".php" => (( "bin-path" => "/usr/bin/php-cgi", "socket" => "/var/run/php-cgi.sock" )))' >>/etc/lighttpd/lighttpd.conf
    ADMINER_VERSION=$(curl -s https://api.github.com/repos/vrana/adminer/releases/latest | jq -r '.tag_name' | sed 's/v//')
    wget -q -O /var/www/adminer.php "https://github.com/vrana/adminer/releases/download/v${ADMINER_VERSION}/adminer-${ADMINER_VERSION}.php"
    chown lighttpd:lighttpd /var/www/adminer.php
    chmod 755 /var/www/adminer.php
    msg_ok "Adminer Installed"

    msg_info "Starting Lighttpd"
    $STD rc-update add lighttpd default
    $STD rc-service lighttpd restart
    msg_ok "Lighttpd Started"

    echo -e "Adminer is available at: ${BL}http://$(hostname -I | awk '{print $1}')/adminer${CL}"
else
    echo -e "Skipped Adminer Installation..."
fi

motd_ssh
customize

msg_info "Cleaning up"
msg_ok "Cleaned"
