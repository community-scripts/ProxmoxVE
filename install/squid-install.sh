#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: 007hacky007
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.squid-cache.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Configuring Squid"
mkdir -p /etc/squid
cat <<EOF >/etc/squid/squid.conf
acl localnet src 0.0.0.1-0.255.255.255
acl localnet src 10.0.0.0/8
acl localnet src 100.64.0.0/10
acl localnet src 169.254.0.0/16
acl localnet src 172.16.0.0/12
acl localnet src 192.168.0.0/16
acl localnet src fc00::/7
acl localnet src fe80::/10

acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT

http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager

auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwords
auth_param basic realm proxy
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all

http_port 3128

coredump_dir /var/spool/squid

refresh_pattern ^ftp:        1440    20%    10080
refresh_pattern ^gopher:     1440    0%     1440
refresh_pattern -i (/cgi-bin/|\\?) 0  0%     0
refresh_pattern .            0       20%    4320

# Privacy / hardening
httpd_suppress_version_string on
visible_hostname $(hostname)
forwarded_for delete
request_header_access X-Forwarded-For deny all
EOF
msg_ok "Configured Squid"

msg_info "Installing Dependencies"
$STD apt install -y \
  squid \
  apache2-utils
msg_ok "Installed Dependencies"

msg_info "Configuring Squid Authentication"
touch /etc/squid/passwords
chown proxy:proxy /etc/squid/passwords
chmod 640 /etc/squid/passwords
$STD squid -k parse
msg_ok "Configured Squid Authentication"

msg_info "Starting Service"
systemctl enable -q --now squid
msg_ok "Started Service"

motd_ssh
customize
cleanup_lxc
