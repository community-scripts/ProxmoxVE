#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Nícolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Starting the process to check and install required packages"
$STD apt-get install -y \
  curl \
  git \
  sudo \
  mc \
  gpg \
  wget \
  lsof \
  gnupg \
  apt-transport-https \
  debsums \
  chrony \
  redis-server \
  postfix
msg_ok "Required packages installed"

msg_info "Starting the process to set up required packages and swap"
$STD apt -y upgrade
echo "CONF_SWAPFILE=/home/.swap" > /etc/dphys-swapfile
echo "CONF_SWAPSIZE=2048" >> /etc/dphys-swapfile
echo "CONF_MAXSWAP=2048" >> /etc/dphys-swapfile
$STD apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew install dphys-swapfile
msg_ok "Swap file and required packages set up"

msg_info "Starting the process to generate locales"
$STD apt -y install locales locales-all
$STD /usr/sbin/locale-gen en_US.UTF-8
msg_ok "Locales generated"

msg_info "Starting the process to remove unnecessary packages"
$STD apt -y --purge remove mysql* &> /dev/null
msg_ok "Unnecessary packages removed"

msg_info "Starting the process to add CloudPanel repositories"
curl -fsSL https://d17k9fuiwb52nc.cloudfront.net/key.gpg | sudo gpg --yes --dearmor -o /etc/apt/trusted.gpg.d/cloudpanel-keyring.gpg

cat <<EOF > /etc/apt/sources.list.d/packages.cloudpanel.io.list
deb https://d17k9fuiwb52nc.cloudfront.net/ bookworm main
deb https://d17k9fuiwb52nc.cloudfront.net/ bookworm nginx
deb https://d17k9fuiwb52nc.cloudfront.net/ bookworm php-7.1
deb https://d17k9fuiwb52nc.cloudfront.net/ bookworm php-7.2
deb https://d17k9fuiwb52nc.cloudfront.net/ bookworm php-7.3
deb https://d17k9fuiwb52nc.cloudfront.net/ bookworm php-7.4
deb https://d17k9fuiwb52nc.cloudfront.net/ bookworm php-8.0
deb https://d17k9fuiwb52nc.cloudfront.net/ bookworm php-8.1
deb https://d17k9fuiwb52nc.cloudfront.net/ bookworm php-8.2
deb https://d17k9fuiwb52nc.cloudfront.net/ bookworm php-8.3
deb https://d17k9fuiwb52nc.cloudfront.net/ bookworm php-8.4
deb https://d17k9fuiwb52nc.cloudfront.net/ bookworm proftpd
deb https://d17k9fuiwb52nc.cloudfront.net/ bookworm varnish-7
EOF

cat <<EOF > /etc/apt/preferences.d/00packages.cloudpanel.io.pref
Package: *
Pin: origin d17k9fuiwb52nc.cloudfront.net
Pin-Priority: 1000
EOF

$STD apt -y update
msg_ok "CloudPanel repositories added"

msg_info "Starting the process to install MariaDB"
wget -qO- https://mariadb.org/mariadb_release_signing_key.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/mariadb.gpg
echo "deb [arch=amd64,arm64] https://mirror.mariadb.org/repo/11.4/debian bookworm main" > /etc/apt/sources.list.d/mariadb.list
$STD apt -y update
$STD apt -y install mariadb-server
ln -sf /usr/bin/mariadb /usr/bin/mysql
ln -sf /usr/bin/mariadb-access /usr/bin/mysqlaccess
ln -sf /usr/bin/mariadb-admin /usr/bin/mysqladmin
ln -sf /usr/bin/mariadb-check /usr/bin/mysqlanalyze
ln -sf /usr/bin/mariadb-binlog /usr/bin/mysqlbinlog
ln -sf /usr/bin/mariadb-check /usr/bin/mysqlcheck
ln -sf /usr/bin/mariadb-convert-table-format /usr/bin/mysql_convert_table_format
ln -sf /usr/bin/mariadbd-multi /usr/bin/mysqld_multi
ln -sf /usr/bin/mariadbd-safe /usr/bin/mysqld_safe
ln -sf /usr/bin/mariadbd-safe-helper /usr/bin/mysqld_safe_helper
ln -sf /usr/bin/mariadb-dump /usr/bin/mysqldump
ln -sf /usr/bin/mariadb-dumpslow /usr/bin/mysqldumpslow
ln -sf /usr/bin/mariadb-find-rows /usr/bin/mysql_find_rows
ln -sf /usr/bin/mariadb-fix-extensions /usr/bin/mysql_fix_extensions
ln -sf /usr/bin/mariadb-hotcopy /usr/bin/mysqlhotcopy
ln -sf /usr/bin/mariadb-import /usr/bin/mysqlimport
ln -sf /usr/bin/mariadb-install-db /usr/bin/mysql_install_db
ln -sf /usr/bin/mariadb-check /usr/bin/mysqloptimize
ln -sf /usr/bin/mariadb-plugin /usr/bin/mysql_plugin
ln -sf /usr/bin/mariadb-check /usr/bin/mysqlrepair
ln -sf /usr/bin/mariadb-report /usr/bin/mysqlreport
ln -sf /usr/bin/mariadb-secure-installation /usr/bin/mysql_secure_installation
ln -sf /usr/bin/mariadb-setpermission /usr/bin/mysql_setpermission
ln -sf /usr/bin/mariadb-show /usr/bin/mysqlshow
ln -sf /usr/bin/mariadb-slap /usr/bin/mysqlslap
ln -sf /usr/bin/mariadb-tzinfo-to-sql /usr/bin/mysql_tzinfo_to_sql
ln -sf /usr/bin/mariadb-upgrade /usr/bin/mysql_upgrade
ln -sf /usr/bin/mariadb-waitpid /usr/bin/mysql_waitpid
msg_ok "MariaDB installed and MySQL links created"

msg_info "Starting the process to install CloudPanel"
$STD apt -o Dpkg::Options::="--force-overwrite" install -y cloudpanel
msg_ok "CloudPanel installed"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
