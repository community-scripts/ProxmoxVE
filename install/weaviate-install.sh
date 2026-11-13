#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/weaviate/weaviate

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "weaviate" "weaviate/weaviate" "prebuild" "latest" "/opt/weaviate" "weaviate-v*-linux-$(arch_resolve).tar.gz"

msg_info "Configuring Weaviate"
mkdir -p /opt/weaviate_data/data
cat <<EOF >/opt/weaviate_data/.env
PERSISTENCE_DATA_PATH=/opt/weaviate_data/data
QUERY_DEFAULTS_LIMIT=25
CLUSTER_HOSTNAME=node1
CLUSTER_BIND_ADDR=127.0.0.1
CLUSTER_BASIC_AUTH_USERNAME=weaviate
CLUSTER_BASIC_AUTH_PASSWORD=$(random_password)
GRPC_PORT=50051
AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED=false
AUTHENTICATION_APIKEY_ENABLED=true
AUTHENTICATION_APIKEY_ALLOWED_KEYS=${var_api_key:-$(random_password 32)}
AUTHENTICATION_APIKEY_USERS=admin
AUTHENTICATION_DB_USERS_ENABLED=true
AUTHORIZATION_RBAC_ENABLED=true
AUTHORIZATION_RBAC_ROOT_USERS=admin
LIMIT_RESOURCES=true
GO_PROFILING_DISABLE=true
DISABLE_TELEMETRY=true
EOF
chmod 600 /opt/weaviate_data/.env
msg_ok "Configured Weaviate"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/weaviate.service
[Unit]
Description=Weaviate
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/weaviate_data
EnvironmentFile=/opt/weaviate_data/.env
ExecStart=/opt/weaviate/weaviate --host 0.0.0.0 --port 8080 --scheme http
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now weaviate
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
