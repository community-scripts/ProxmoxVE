#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CanbiZ (MickLesk)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/NagiosEnterprises/nagioscore

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  autoconf \
  automake \
  build-essential \
  bc \
  dc \
  gawk \
  gettext \
  gperf \
  libgd-dev \
  libmcrypt-dev \
  libnet-snmp-perl \
  libssl-dev \
  snmp \
  apache2 \
  apache2-utils
msg_ok "Installed Dependencies"

PHP_APACHE="YES" setup_php

fetch_and_deploy_gh_release "nagios" "NagiosEnterprises/nagioscore" "tarball"

msg_info "Building Nagios Core"
cd /opt/nagios
$STD ./configure --with-httpd-conf=/etc/apache2/sites-enabled
$STD make all
$STD make install-groups-users
usermod -a -G nagios www-data
$STD make install
$STD make install-daemoninit
$STD make install-commandmode
$STD make install-config
$STD make install-webconf
$STD a2enmod rewrite
$STD a2enmod cgi
msg_ok "Built Nagios Core"

fetch_and_deploy_gh_release "nagios-plugins" "nagios-plugins/nagios-plugins" "tarball"

msg_info "Building Nagios Plugins"
cd /opt/nagios-plugins
$STD ./tools/setup
$STD ./configure
$STD make
$STD make install
setcap cap_net_raw+p /bin/ping
msg_ok "Built Nagios Plugins"

msg_info "Configuring Web Authentication"
$STD htpasswd -bc /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin
chown root:www-data /usr/local/nagios/etc/htpasswd.users
chmod 640 /usr/local/nagios/etc/htpasswd.users
msg_ok "Configured Web Authentication"

msg_info "Starting Services"
systemctl enable -q apache2
systemctl restart apache2
systemctl enable -q --now nagios
msg_ok "Started Services"

motd_ssh
customize
cleanup_lxc
