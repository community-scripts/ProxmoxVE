#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: hoholms
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/grafana/loki

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Loki"
$STD apk add loki
$STD sed -i '/http_addr/s/127.0.0.1/0.0.0.0/g' /etc/conf.d/loki
mkdir -p /var/lib/loki/{chunks,boltdb-shipper-active,boltdb-shipper-cache}
chown -R loki:grafana /var/lib/loki
mkdir -p /var/log/loki
chown -R loki:grafana /var/log/loki
cat <<EOF >/etc/loki/loki-local-config.yaml
auth_enabled: false

server:
  http_listen_port: 3100
  log_level: info

common:
  instance_addr: 127.0.0.1
  path_prefix: /var/lib/loki
  storage:
    filesystem:
      chunks_directory: /var/lib/loki/chunks
      rules_directory: /var/lib/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

query_range:
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 100

limits_config:
  metric_aggregation_enabled: true

ruler:
  alertmanager_url: http://localhost:9093
EOF
chown loki:grafana /etc/loki/loki-local-config.yaml
chmod 644 /etc/loki/loki-local-config.yaml
echo "output_log=\"\${output_log:-/var/log/loki/output.log}\"" >> /etc/init.d/loki
echo "error_log=\"\${error_log:-/var/log/loki/error.log}\"" >> /etc/init.d/loki
echo "start_stop_daemon_args=\"\${SSD_OPTS} -1 \${output_log} -2 \${error_log}\"" >> /etc/init.d/loki
$STD rc-update add loki default
$STD rc-service loki start
msg_ok "Installed Loki"

read -rp "Would you like to install Promtail? (y/N): " INSTALL_PROMTAIL
if [[ "${INSTALL_PROMTAIL,,}" =~ ^(y|yes)$ ]]; then
  msg_info "Installing Promtail"
  $STD apk add loki-promtail
  $STD sed -i '/http_addr/s/127.0.0.1/0.0.0.0/g' /etc/conf.d/loki-promtail
  $STD rc-update add loki-promtail default
  $STD rc-service loki-promtail start
  msg_ok "Installed Promtail"
fi

motd_ssh
customize
cleanup_lxc
