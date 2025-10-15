#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://signoz.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  apt-transport-https \
  ca-certificates
msg_ok "Installed Dependencies"

JAVA_VERSION="21" setup_java

msg_info "Setting up ClickHouse"
curl -fsSL "https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key" | gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg
cat <<EOF >/etc/apt/sources.list.d/clickhouse.sources
Types: deb
URIs: https://packages.clickhouse.com/deb
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/clickhouse-keyring.gpg
EOF
$STD apt update
export DEBIAN_FRONTEND=noninteractive
$STD apt install -y clickhouse-server clickhouse-client
msg_ok "Setup ClickHouse"

msg_info "Setting up Zookeeper"
ZOOURL=$(curl -fsSL https://dlcdn.apache.org/zookeeper/current/ | grep -o 'apache-zookeeper-[0-9.]\+-bin\.tar\.gz' | head -n1)
curl -fsSL "https://dlcdn.apache.org/zookeeper/current/$ZOOURL" -o ~/zookeeper.tar.gz
tar -xzf "$HOME/zookeeper.tar.gz" -C "$HOME"
mkdir -p /opt/zookeeper
mkdir -p /var/lib/zookeeper
mkdir -p /var/log/zookeeper
cp -r ~/apache-zookeeper-*-bin/* /opt/zookeeper

cat <<EOF >/opt/zookeeper/conf/zoo.cfg
tickTime=2000
dataDir=/var/lib/zookeeper
clientPort=2181
admin.serverPort=3181
EOF

cat <<EOF >/opt/zookeeper/conf/zoo.env
ZOO_LOG_DIR=/var/log/zookeeper
EOF

cat <<EOF >/etc/systemd/system/zookeeper.service
[Unit]
Description=Zookeeper
Documentation=http://zookeeper.apache.org

[Service]
EnvironmentFile=/opt/zookeeper/conf/zoo.env
Type=forking
WorkingDirectory=/opt/zookeeper
ExecStart=/opt/zookeeper/bin/zkServer.sh start /opt/zookeeper/conf/zoo.cfg
ExecStop=/opt/zookeeper/bin/zkServer.sh stop /opt/zookeeper/conf/zoo.cfg
ExecReload=/opt/zookeeper/bin/zkServer.sh restart /opt/zookeeper/conf/zoo.cfg
TimeoutSec=30
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now zookeeper
msg_ok "Setup Zookeeper"

msg_info "Configuring ClickHouse"
cat <<EOF >/etc/clickhouse-server/config.d/cluster.xml
<clickhouse replace="true">
    <distributed_ddl>
        <path>/clickhouse/task_queue/ddl</path>
    </distributed_ddl>
    <remote_servers>
        <cluster>
            <shard>
                <replica>
                    <host>127.0.0.1</host>
                    <port>9000</port>
                </replica>
            </shard>
        </cluster>
    </remote_servers>
    <zookeeper>
        <node>
            <host>127.0.0.1</host>
            <port>2181</port>
        </node>
    </zookeeper>
    <macros>
        <shard>01</shard>
        <replica>01</replica>
    </macros>
</clickhouse>
EOF
systemctl enable -q --now clickhouse-server
msg_ok "Configured ClickHouse"

fetch_and_deploy_gh_release "signoz-schema-migrator" "SigNoz/signoz-otel-collector" "prebuild" "latest" "/opt/signoz-schema-migrator" "signoz-schema-migrator_linux_amd64.tar.gz"

msg_info "Running ClickHouse migrations"
cd /opt/signoz-schema-migrator/bin
$STD ./signoz-schema-migrator sync --dsn="tcp://localhost:9000?password=" --replication=true --up=
$STD ./signoz-schema-migrator async --dsn="tcp://localhost:9000?password=" --replication=true --up=
msg_ok "ClickHouse Migrations Completed"

fetch_and_deploy_gh_release "signoz" "SigNoz/signoz" "prebuild" "latest" "/opt/signoz" "signoz-community_linux_amd64.tar.gz"

msg_info "Setting up SigNoz"
mkdir -p /var/lib/signoz
cat <<EOF >/opt/signoz/conf/systemd.env
SIGNOZ_INSTRUMENTATION_LOGS_LEVEL=info
INVITE_EMAIL_TEMPLATE=/opt/signoz/templates/invitation_email_template.html
SIGNOZ_SQLSTORE_SQLITE_PATH=/var/lib/signoz/signoz.db
SIGNOZ_WEB_ENABLED=true
SIGNOZ_WEB_DIRECTORY=/opt/signoz/web
SIGNOZ_JWT_SECRET=secret
SIGNOZ_ALERTMANAGER_PROVIDER=signoz
SIGNOZ_TELEMETRYSTORE_PROVIDER=clickhouse
SIGNOZ_TELEMETRYSTORE_CLICKHOUSE_DSN=tcp://localhost:9000?password=
DOT_METRICS_ENABLED=true
EOF

cat <<EOF >/etc/systemd/system/signoz.service
[Unit]
Description=SigNoz
Documentation=https://signoz.io/docs
After=clickhouse-server.service

[Service]
Type=simple
KillMode=mixed
Restart=on-failure
WorkingDirectory=/opt/signoz
EnvironmentFile=/opt/signoz/conf/systemd.env
ExecStart=/opt/signoz/bin/signoz server

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now signoz
msg_ok "Setup Signoz"

fetch_and_deploy_gh_release "signoz-otel-collector" "SigNoz/signoz-otel-collector" "prebuild" "latest" "/opt/signoz-otel-collector" "signoz-otel-collector_linux_amd64.tar.gz"

msg_info "Setting up SigNoz OTel Collector"
mkdir -p /var/lib/signoz-otel-collector
cat <<EOF >/opt/signoz-otel-collector/conf/config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
        max_recv_msg_size_mib: 16
      http:
        endpoint: 0.0.0.0:4318
  jaeger:
    protocols:
      grpc:
        endpoint: 0.0.0.0:14250
      thrift_http:
        endpoint: 0.0.0.0:14268
  httplogreceiver/heroku:
    endpoint: 0.0.0.0:8081
    source: heroku
  httplogreceiver/json:
    endpoint: 0.0.0.0:8082
    source: json
processors:
  batch:
    send_batch_size: 50000
    timeout: 1s
  signozspanmetrics/delta:
    metrics_exporter: signozclickhousemetrics
    latency_histogram_buckets: [100us, 1ms, 2ms, 6ms, 10ms, 50ms, 100ms, 250ms, 500ms, 1000ms, 1400ms, 2000ms, 5s, 10s, 20s, 40s, 60s]
    dimensions_cache_size: 100000
    dimensions:
      - name: service.namespace
        default: default
      - name: deployment.environment
        default: default
      - name: signoz.collector.id
    aggregation_temporality: AGGREGATION_TEMPORALITY_DELTA
extensions:
  health_check:
    endpoint: 0.0.0.0:13133
  zpages:
    endpoint: localhost:55679
  pprof:
    endpoint: localhost:1777
exporters:
  clickhousetraces:
    datasource: tcp://localhost:9000/signoz_traces?password=
    use_new_schema: true
  signozclickhousemetrics:
    dsn: tcp://localhost:9000/signoz_metrics?password=
    timeout: 45s
  clickhouselogsexporter:
    dsn: tcp://localhost:9000/signoz_logs?password=
    timeout: 10s
    use_new_schema: true
  metadataexporter:
    dsn: tcp://localhost:9000/signoz_metadata?password=
    timeout: 10s
    tenant_id: default
    cache:
      provider: in_memory
service:
  telemetry:
    logs:
      encoding: json
  extensions: [health_check, zpages, pprof]
  pipelines:
    traces:
      receivers: [otlp, jaeger]
      processors: [signozspanmetrics/delta, batch]
      exporters: [clickhousetraces, metadataexporter]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [metadataexporter, signozclickhousemetrics]
    logs:
      receivers: [otlp, httplogreceiver/heroku, httplogreceiver/json]
      processors: [batch]
      exporters: [clickhouselogsexporter, metadataexporter]
EOF

cat <<EOF >/opt/signoz-otel-collector/conf/opamp.yaml
server_endpoint: ws://127.0.0.1:4320/v1/opamp
EOF

cat <<EOF >/etc/systemd/system/signoz-otel-collector.service
[Unit]
Description=SigNoz OTel Collector
Documentation=https://signoz.io/docs
After=clickhouse-server.service

[Service]
Type=simple
KillMode=mixed
Restart=on-failure
WorkingDirectory=/opt/signoz-otel-collector
ExecStart=/opt/signoz-otel-collector/bin/signoz-otel-collector --config=/opt/signoz-otel-collector/conf/config.yaml --manager-config=/opt/signoz-otel-collector/conf/opamp.yaml --copy-path=/var/lib/signoz-otel-collector/config.yaml

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now signoz-otel-collector

motd_ssh
customize

msg_info "Cleaning up"
rm -rf ~/zookeeper.tar.gz
rm -rf ~/apache-zookeeper-*-bin
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
