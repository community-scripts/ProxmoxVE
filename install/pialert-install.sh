#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get -y install \
  sudo \
  mc \
  curl \
  apt-utils \
  avahi-utils \
  lighttpd \
  sqlite3 \
  mmdb-bin \
  arp-scan \
  dnsutils \
  net-tools \
  nbtscan \
  libwww-perl \
  nmap \
  zip \
  aria2 \
  wakeonlan
msg_ok "Installed Dependencies"

msg_info "Installing PHP Dependencies"
$STD apt-get -y install \
  php \
  php-cgi \
  php-fpm \
  php-curl \
  php-xml \
  php-sqlite3
$STD lighttpd-enable-mod fastcgi-php
service lighttpd force-reload
msg_ok "Installed PHP Dependencies"

msg_info "Installing Python Dependencies"
$STD apt-get -y install \
  python3-pip \
  python3-requests \
  python3-tz \
  python3-tzlocal
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
$STD pip3 install mac-vendor-lookup
$STD pip3 install fritzconnection
$STD pip3 install cryptography
$STD pip3 install pyunifi
msg_ok "Installed Python Dependencies"

msg_info "Installing Pi.Alert"
curl -sL https://github.com/leiweibau/Pi.Alert/raw/main/tar/pialert_latest.tar | tar xvf - -C /opt >/dev/null 2>&1
rm -rf /var/lib/ieee-data /var/www/html/index.html
sed -i -e 's#^sudo cp -n /usr/share/ieee-data/.* /var/lib/ieee-data/#\# &#' -e '/^sudo mkdir -p 2_backup$/s/^/# /' -e '/^sudo cp \*.txt 2_backup$/s/^/# /' -e '/^sudo cp \*.csv 2_backup$/s/^/# /' /opt/pialert/back/update_vendors.sh
mv /var/www/html/index.lighttpd.html /var/www/html/index.lighttpd.html.old
ln -s /usr/share/ieee-data/ /var/lib/
ln -s /opt/pialert/install/index.html /var/www/html/index.html
ln -s /opt/pialert/front /var/www/html/pialert
chmod go+x /opt/pialert /opt/pialert/back/shoutrrr/x86/shoutrrr
chgrp -R www-data /opt/pialert/db /opt/pialert/front/reports /opt/pialert/config /opt/pialert/config/pialert.conf
chmod -R 775 /opt/pialert/db /opt/pialert/db/temp /opt/pialert/config /opt/pialert/front/reports
touch /opt/pialert/log/pialert.vendors.log /opt/pialert/log/pialert.IP.log /opt/pialert/log/pialert.1.log /opt/pialert/log/pialert.cleanup.log /opt/pialert/log/pialert.webservices.log
src_dir="/opt/pialert/log"
dest_dir="/opt/pialert/front/php/server"
for file in pialert.vendors.log pialert.IP.log pialert.1.log pialert.cleanup.log pialert.webservices.log; do
    ln -s "$src_dir/$file" "$dest_dir/$file"
done
sed -i 's#PIALERT_PATH\s*=\s*'\''/home/pi/pialert'\''#PIALERT_PATH           = '\''/opt/pialert'\''#' /opt/pialert/config/pialert.conf
sed -i 's/$HOME/\/opt/g' /opt/pialert/install/pialert.cron
crontab /opt/pialert/install/pialert.cron
echo "python3 /opt/pialert/back/pialert.py 1" >/usr/bin/scan
chmod +x /usr/bin/scan
echo "/opt/pialert/back/pialert-cli set_permissions --lxc" >/usr/bin/permissions
chmod +x /usr/bin/permissions
echo "/opt/pialert/back/pialert-cli set_sudoers --lxc" >/usr/bin/sudoers
chmod +x /usr/bin/sudoers
msg_ok "Installed Pi.Alert"

msg_info "Start Pi.Alert Scan (Patience)"
$STD python3 /opt/pialert/back/pialert.py update_vendors
$STD python3 /opt/pialert/back/pialert.py internet_IP
$STD python3 /opt/pialert/back/pialert.py 1
msg_ok "Finished Pi.Alert Scan"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
