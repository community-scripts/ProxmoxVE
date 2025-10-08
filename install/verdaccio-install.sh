#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: BrynnJKnight
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://verdaccio.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  ca-certificates \
  build-essential
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="verdaccio" setup_nodejs

msg_info "Configuring Verdaccio"
mkdir -p /opt/verdaccio/config
mkdir -p /opt/verdaccio/storage

cat <<EOF >/opt/verdaccio/config/config.yaml
# Verdaccio configuration
storage: /opt/verdaccio/storage
auth:
  htpasswd:
    file: /opt/verdaccio/storage/htpasswd
    max_users: 1000
uplinks:
  npmjs:
    url: https://registry.npmjs.org/
packages:
  '@*/*':
    access: \$all
    publish: \$authenticated
    proxy: npmjs
  '**':
    access: \$all
    publish: \$authenticated
    proxy: npmjs
middlewares:
  audit:
    enabled: true
logs:
  - {type: stdout, format: pretty, level: http}
listen:
  - 0.0.0.0:4873
web:
  enable: true
  title: Verdaccio
  gravatar: true
  sort_packages: asc
  login: true
EOF

chown -R root:root /opt/verdaccio
chmod -R 755 /opt/verdaccio
msg_ok "Configured Verdaccio"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/verdaccio.service
[Unit]
Description=Verdaccio lightweight private npm proxy registry
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/verdaccio --config /opt/verdaccio/config/config.yaml
Restart=on-failure
StandardOutput=journal
StandardError=journal
SyslogIdentifier=verdaccio
KillMode=control-group

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now verdaccio
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
