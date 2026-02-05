#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bysinka-95
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/grafana/loki

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb822_repo \
  "grafana" \
  "https://apt.grafana.com/gpg.key" \
  "https://apt.grafana.com" \
  "stable" \
  "main"

msg_info "Installing Loki"
$STD apt install -y loki
mkdir -p /var/lib/loki/{chunks,boltdb-shipper-active,boltdb-shipper-cache}
chown -R loki /var/lib/loki
cat <<EOF >/etc/loki/config.yml
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
chown loki /etc/loki/config.yml
systemctl enable -q --now loki
msg_ok "Installed Loki"

read -rp "Would you like to install Promtail? (y/N): " INSTALL_PROMTAIL
if [[ "${INSTALL_PROMTAIL,,}" =~ ^(y|yes)$ ]]; then
  msg_info "Installing Promtail"
  $STD apt install -y promtail
  systemctl enable -q --now promtail
  msg_ok "Installed Promtail"
fi

motd_ssh
customize
cleanup_lxc
