#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Renan Bastos (renanbastos93)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/temporalio/temporal

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PG_VERSION="17" setup_postgresql
PG_DB_NAME="temporal" PG_DB_USER="temporal" PG_DB_SCHEMA_PERMS="true" setup_postgresql_db

fetch_and_deploy_gh_release "temporal" "temporalio/temporal" "prebuild" "latest" "/opt/temporal" "temporal_*_linux_$(arch_resolve).tar.gz"
fetch_and_deploy_gh_release "temporal-ui" "temporalio/ui-server" "prebuild" "latest" "/opt/temporal-ui" "ui-server_*_linux_$(arch_resolve).tar.gz"
fetch_and_deploy_gh_release "temporal-cli" "temporalio/cli" "prebuild" "latest" "/opt/temporal-cli" "temporal_cli_*_linux_$(arch_resolve).tar.gz"

msg_info "Configuring Temporal"
mkdir -p /etc/temporal/config/dynamicconfig /etc/temporal/ui
ln -sf /opt/temporal-cli/temporal /usr/bin/temporal
cat <<EOF >/etc/temporal/temporal.env
SQL_PLUGIN=postgres12
SQL_HOST=127.0.0.1
SQL_PORT=5432
SQL_USER=temporal
SQL_PASSWORD=${PG_DB_PASS}
EOF
chmod 600 /etc/temporal/temporal.env
cat <<'EOF' >/etc/temporal/config/production.yaml
# enable-template
log:
  stdout: true
  level: info

persistence:
  defaultStore: postgres-default
  visibilityStore: postgres-visibility
  numHistoryShards: 4
  datastores:
    postgres-default:
      sql:
        pluginName: {{ env "SQL_PLUGIN" | quote }}
        databaseName: "temporal"
        connectAddr: {{ printf "%s:%s" (env "SQL_HOST") (env "SQL_PORT") | quote }}
        connectProtocol: "tcp"
        user: {{ env "SQL_USER" | quote }}
        password: {{ env "SQL_PASSWORD" | quote }}
        maxConns: 20
        maxIdleConns: 20
        maxConnLifetime: "1h"
    postgres-visibility:
      sql:
        pluginName: {{ env "SQL_PLUGIN" | quote }}
        databaseName: "temporal_visibility"
        connectAddr: {{ printf "%s:%s" (env "SQL_HOST") (env "SQL_PORT") | quote }}
        connectProtocol: "tcp"
        user: {{ env "SQL_USER" | quote }}
        password: {{ env "SQL_PASSWORD" | quote }}
        maxConns: 10
        maxIdleConns: 10
        maxConnLifetime: "1h"

global:
  membership:
    maxJoinDuration: 30s
    broadcastAddress: "127.0.0.1"

services:
  frontend:
    rpc:
      grpcPort: 7233
      membershipPort: 6933
      bindOnIP: "0.0.0.0"

  matching:
    rpc:
      grpcPort: 7235
      membershipPort: 6935
      bindOnLocalHost: true

  history:
    rpc:
      grpcPort: 7234
      membershipPort: 6934
      bindOnLocalHost: true

  worker:
    rpc:
      grpcPort: 7239
      membershipPort: 6939
      bindOnLocalHost: true

clusterMetadata:
  enableGlobalNamespace: false
  failoverVersionIncrement: 10
  masterClusterName: "active"
  currentClusterName: "active"
  clusterInformation:
    active:
      enabled: true
      initialFailoverVersion: 1
      rpcName: "frontend"
      rpcAddress: "127.0.0.1:7233"

dcRedirectionPolicy:
  policy: "noop"

archival:
  history:
    state: "disabled"
  visibility:
    state: "disabled"

namespaceDefaults:
  archival:
    history:
      state: "disabled"
    visibility:
      state: "disabled"

dynamicConfigClient:
  filepath: "/etc/temporal/config/dynamicconfig/production.yaml"
  pollInterval: "60s"
EOF
cat <<EOF >/etc/temporal/config/dynamicconfig/production.yaml
limit.maxIDLength:
  - value: 255
    constraints: {}
EOF
cat <<EOF >/etc/temporal/ui/production.yaml
temporalGrpcAddress: 127.0.0.1:7233
port: 8080
enableUi: true
defaultNamespace: default
cors:
  cookieInsecure: true
  allowOrigins:
    - http://${LOCAL_IP}:8080
EOF
msg_ok "Configured Temporal"

msg_info "Initializing Temporal Database"
set -a && source /etc/temporal/temporal.env && set +a
$STD /opt/temporal/temporal-sql-tool --db temporal_visibility create-database
$STD /opt/temporal/temporal-sql-tool --db temporal setup-schema -v 0.0
$STD /opt/temporal/temporal-sql-tool --db temporal update-schema --schema-name postgresql/v12/temporal
$STD /opt/temporal/temporal-sql-tool --db temporal_visibility setup-schema -v 0.0
$STD /opt/temporal/temporal-sql-tool --db temporal_visibility update-schema --schema-name postgresql/v12/visibility
msg_ok "Initialized Temporal Database"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/temporal.service
[Unit]
Description=Temporal Server
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/temporal
EnvironmentFile=/etc/temporal/temporal.env
ExecStart=/opt/temporal/temporal-server --root /etc/temporal --env production --allow-no-auth start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/temporal-ui.service
[Unit]
Description=Temporal UI
After=network.target temporal.service
Wants=temporal.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/temporal-ui
ExecStart=/opt/temporal-ui/ui-server --root /etc/temporal --config ui --env production start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now temporal temporal-ui
msg_ok "Created Services"

msg_info "Creating Default Namespace"
for _ in {1..60}; do
  temporal operator cluster health &>/dev/null && break
  sleep 1
done
$STD temporal operator namespace create --namespace default
msg_ok "Created Default Namespace"

motd_ssh
customize
cleanup_lxc
