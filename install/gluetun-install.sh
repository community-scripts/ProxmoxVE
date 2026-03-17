#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/qdm12/gluetun

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  openvpn \
  wireguard-tools \
  iptables
msg_ok "Installed Dependencies"

msg_info "Configuring iptables"
$STD update-alternatives --set iptables /usr/sbin/iptables-legacy
$STD update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
ln -sf /usr/sbin/openvpn /usr/sbin/openvpn2.6
msg_ok "Configured iptables"

setup_go

fetch_and_deploy_gh_release "gluetun" "qdm12/gluetun" "tarball"

msg_info "Building Gluetun"
cd /opt/gluetun
$STD go mod download
CGO_ENABLED=0 $STD go build -trimpath -ldflags="-s -w" -o /usr/local/bin/gluetun ./cmd/gluetun/
msg_ok "Built Gluetun"

msg_info "Configuring Gluetun"
mkdir -p /opt/gluetun-data
touch /etc/alpine-release
ln -sf /opt/gluetun-data /gluetun
cat <<EOF >/opt/gluetun-data/.env
VPN_SERVICE_PROVIDER=custom
VPN_TYPE=openvpn
OPENVPN_CUSTOM_CONFIG=/opt/gluetun-data/custom.ovpn
OPENVPN_USER=
OPENVPN_PASSWORD=
OPENVPN_PROCESS_USER=root
PUID=0
PGID=0
HTTP_CONTROL_SERVER_ADDRESS=:8000
HTTPPROXY=off
SHADOWSOCKS=off
PPROF_ENABLED=no
PPROF_BLOCK_PROFILE_RATE=0
PPROF_MUTEX_PROFILE_RATE=0
PPROF_HTTP_SERVER_ADDRESS=:6060
FIREWALL_ENABLED_DISABLING_IT_SHOOTS_YOU_IN_YOUR_FOOT=on
HEALTH_SERVER_ADDRESS=127.0.0.1:9999
DNS_UPSTREAM_RESOLVERS=cloudflare
LOG_LEVEL=info
STORAGE_FILEPATH=/gluetun/servers.json
PUBLICIP_FILE=/gluetun/ip
VPN_PORT_FORWARDING_STATUS_FILE=/gluetun/forwarded_port
TZ=UTC
EOF
msg_ok "Configured Gluetun"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/gluetun.service
[Unit]
Description=Gluetun VPN Client
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/gluetun-data
EnvironmentFile=/opt/gluetun-data/.env
UnsetEnvironment=USER
ExecStartPre=/bin/sh -c 'rm -f /etc/openvpn/target.ovpn'
ExecStart=/usr/local/bin/gluetun
Restart=on-failure
RestartSec=5
AmbientCapabilities=CAP_NET_ADMIN

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now gluetun
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
