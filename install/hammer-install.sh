#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Darkrock-Studios/hammer-editor

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  unzip \
  fontconfig \
  libfreetype6
msg_ok "Installed Dependencies"

JAVA_VERSION="21" setup_java

fetch_and_deploy_gh_release "hammer" "Darkrock-Studios/hammer-editor" "prebuild" "latest" "/opt/hammer" "server.zip"

msg_info "Configuring Hammer Sync Server"
chmod +x /opt/hammer/bin/server
mkdir -p /opt/hammer_data
cat <<EOF >/opt/hammer_data/config.toml
# Hammer Sync Server configuration
# Reference: https://github.com/Darkrock-Studios/hammer-editor/blob/develop/docs/HOW-TO-RUN-A-SERVER.md
# Loaded automatically from the data directory. Apply changes with:
#   systemctl restart hammer

host = "${LOCAL_IP}"
port = 8080

# Hammer clients speak https only and will not connect to plain HTTP. Either put
# a TLS reverse proxy in front of this port, or let Hammer terminate TLS itself
# with a real certificate (self-signed certs are rejected by the clients).
#
# Behind a reverse proxy on this host, restrict the plain port to loopback and
# set the URL the clients actually use:
# bindHosts = ["127.0.0.1", "::1"]
# publicUrl = "https://hammer.example.com"
#
# Hammer terminating TLS itself:
# sslPort = 443
# [sslCert]
# certChainPath = "/etc/letsencrypt/live/hammer.example.com/fullchain.pem"
# privateKeyPath = "/etc/letsencrypt/live/hammer.example.com/privkey.pem"
# forceHttps = true

# Per-page social share images. fontconfig and libfreetype6 are already installed.
# richLinkPreviews = true

# communityEnabled = true

# Storage defaults to an in-process PostgreSQL under /opt/hammer_data/pgdata.
# To use an external PostgreSQL instead:
# [storage]
# type = "remote"
# [storage.remote]
# host = "db.example.com"
# port = 5432
# database = "hammer"
# user = "hammer"
# password = "change-me"
# useSsl = true

# Regenerable render/preview caches, default <data dir>/cache.
# [cache]
# directory = "/var/tmp/hammer-cache"
# maxSizeMb = 200
EOF
cat <<EOF >/etc/systemd/system/hammer.service
[Unit]
Description=Hammer Sync Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/hammer
Environment=SERVER_OPTS=-Duser.home=/opt
ExecStart=/opt/hammer/bin/server
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now hammer
msg_ok "Configured Hammer Sync Server"

motd_ssh
customize
cleanup_lxc
