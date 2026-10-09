#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.haproxy.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing HAProxy"
$STD apt install -y haproxy
msg_ok "Installed HAProxy"

msg_info "Configuring HAProxy"
HAPROXY_STATS_PASSWORD=$(openssl rand -base64 18)
cat <<EOF >/etc/haproxy/haproxy.cfg
global
	log /dev/log local0
	chroot /var/lib/haproxy
	stats socket /run/haproxy/admin.sock mode 660 level admin
	stats timeout 30s
	user haproxy
	group haproxy
	daemon
	ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
	log global
	mode http
	option httplog
	option dontlognull
	timeout connect 5s
	timeout client 50s
	timeout server 50s
	errorfile 400 /etc/haproxy/errors/400.http
	errorfile 403 /etc/haproxy/errors/403.http
	errorfile 408 /etc/haproxy/errors/408.http
	errorfile 500 /etc/haproxy/errors/500.http
	errorfile 502 /etc/haproxy/errors/502.http
	errorfile 503 /etc/haproxy/errors/503.http
	errorfile 504 /etc/haproxy/errors/504.http

listen stats
	bind *:8404
	stats enable
	stats uri /
	stats refresh 10s
	stats admin if TRUE
	stats auth admin:${HAPROXY_STATS_PASSWORD}

# Example: replace with your own frontend/backend pairs.
#frontend http_in
#	bind *:80
#	default_backend servers
#
#backend servers
#	balance roundrobin
#	server web1 192.168.1.10:80 check
#	server web2 192.168.1.11:80 check
EOF
$STD haproxy -c -f /etc/haproxy/haproxy.cfg
systemctl restart haproxy
msg_ok "Configured HAProxy"

motd_ssh
customize
cleanup_lxc
