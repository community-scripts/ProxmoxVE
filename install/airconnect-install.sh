#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Chris Moriarty (cwmoriarty)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/philippe44/AirConnect

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "airconnect" "philippe44/AirConnect" "prebuild" "latest" "/opt/airconnect" "AirConnect-*.zip"

msg_info "Configuring AirConnect"
ARCH=$(arch_resolve x86_64 aarch64)
chmod +x "/opt/airconnect/airupnp-linux-${ARCH}" "/opt/airconnect/aircast-linux-${ARCH}"
ln -sf "/opt/airconnect/airupnp-linux-${ARCH}" /opt/airconnect/airupnp
ln -sf "/opt/airconnect/aircast-linux-${ARCH}" /opt/airconnect/aircast
find /opt/airconnect -maxdepth 1 -type f ! -name "airupnp-linux-${ARCH}" ! -name "aircast-linux-${ARCH}" ! -name "*.xml" -delete
cat <<EOF >/etc/default/airconnect
AIRUPNP_OPTS="-l 1000:2000"
AIRCAST_OPTS=""
EOF
msg_ok "Configured AirConnect"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/airupnp.service
[Unit]
Description=AirUPnP bridge
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/airconnect
EnvironmentFile=-/etc/default/airconnect
ExecStart=/opt/airconnect/airupnp -Z -x /opt/airconnect/airupnp.xml \$AIRUPNP_OPTS
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now airupnp

cat <<EOF >/etc/systemd/system/aircast.service
[Unit]
Description=AirCast bridge
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/airconnect
EnvironmentFile=-/etc/default/airconnect
ExecStart=/opt/airconnect/aircast -Z -x /opt/airconnect/aircast.xml \$AIRCAST_OPTS
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now aircast
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
