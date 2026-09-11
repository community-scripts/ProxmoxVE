#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.elastic.co/elasticsearch

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# vm.max_map_count is not namespaced, so a container cannot raise it - the value
# is inherited from the Proxmox host. Elasticsearch refuses to start below the
# required limit once it binds to a non-loopback address (production mode).
msg_info "Checking Kernel Limits"
if (($(sysctl -n vm.max_map_count) < 262144)); then
  msg_error "vm.max_map_count is $(sysctl -n vm.max_map_count), Elasticsearch needs at least 262144"
  msg_error "Set it on the PROXMOX HOST, not in this container:"
  msg_error "  echo 'vm.max_map_count=1048576' >/etc/sysctl.d/99-elasticsearch.conf && sysctl --system"
  exit 1
fi
msg_ok "Checked Kernel Limits"

JAVA_VERSION="21" setup_java

setup_deb822_repo \
  "elasticsearch" \
  "https://artifacts.elastic.co/GPG-KEY-elasticsearch" \
  "https://artifacts.elastic.co/packages/9.x/apt" \
  "stable" \
  "main"

msg_info "Installing Elasticsearch"
$STD apt install -y elasticsearch
msg_ok "Installed Elasticsearch"

msg_info "Configuring Elasticsearch"
mkdir -p /opt/elasticsearch_data
chown -R elasticsearch:elasticsearch /opt/elasticsearch_data
cat <<EOF >/etc/elasticsearch/elasticsearch.yml
cluster.name: proxmox
node.name: ${HOSTNAME}
path.data: /opt/elasticsearch_data
path.logs: /var/log/elasticsearch

network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node

xpack.security.enabled: true
xpack.security.enrollment.enabled: true
xpack.security.http.ssl.enabled: false
xpack.security.transport.ssl.enabled: false
EOF

cat <<EOF >/etc/elasticsearch/jvm.options.d/heap.options
-Xms1g
-Xmx1g
EOF
systemctl enable -q --now elasticsearch
msg_ok "Configured Elasticsearch"


motd_ssh
customize
cleanup_lxc
