#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Don Locke (DonLocke)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wavelog/wavelog

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.4" PHP_APACHE="YES" PHP_MAX_EXECUTION_TIME="600" setup_php
setup_mariadb
MARIADB_DB_NAME="wavelog" MARIADB_DB_USER="waveloguser" setup_mariadb_db
fetch_and_deploy_gh_release "wavelog" "wavelog/wavelog" "tarball"

msg_info "Configuring Wavelog"
chown -R www-data:www-data /opt/wavelog/
find /opt/wavelog/ -type d -exec chmod 755 {} \;
find /opt/wavelog/ -type f -exec chmod 664 {} \;
msg_ok "Configured Wavelog"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/wavelog.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /opt/wavelog

    <Directory /opt/wavelog>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/error.log
    CustomLog /var/log/apache2/access.log combined
</VirtualHost>
EOF
$STD a2ensite wavelog.conf
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
