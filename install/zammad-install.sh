#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://zammad.com

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  nginx
msg_ok "Installed Dependencies"

msg_info "Setting up Elasticsearch"
setup_deb822_repo \
  "elasticsearch" \
  "https://artifacts.elastic.co/GPG-KEY-elasticsearch" \
  "https://artifacts.elastic.co/packages/8.x/apt" \
  "stable" \
  "main"
ES_JAVA_OPTS="-Xms1g -Xmx1g" $STD apt install -y elasticsearch
cat <<EOF >/etc/elasticsearch/jvm.options.d/heap.options
-Xms2g
-Xmx2g
EOF
cat <<EOF >/etc/elasticsearch/elasticsearch.yml
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
discovery.type: single-node
network.host: 127.0.0.1
xpack.security.enabled: false
xpack.security.transport.ssl.enabled: false
xpack.security.http.ssl.enabled: false
bootstrap.memory_lock: false
EOF
systemctl daemon-reload
systemctl enable -q elasticsearch
systemctl restart -q elasticsearch
for i in $(seq 1 30); do
  if curl -s http://127.0.0.1:9200 >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
msg_ok "Setup Elasticsearch"

msg_info "Installing Zammad"
setup_deb822_repo \
  "zammad" \
  "https://go.packager.io/srv/deb/zammad/zammad/gpg-key.asc" \
  "https://go.packager.io/srv/deb/zammad/zammad/stable/debian" \
  "$(get_os_info version_id)" \
  "main"
$STD apt install -y zammad
$STD zammad run rails r "Setting.set('es_url', 'http://127.0.0.1:9200')"
$STD zammad run rake zammad:searchindex:rebuild
msg_ok "Installed Zammad"

msg_info "Setup Services"
cp /opt/zammad/contrib/nginx/zammad.conf /etc/nginx/sites-available/zammad.conf
sed -i "s/server_name localhost;/server_name $LOCAL_IP;/g" /etc/nginx/sites-available/zammad.conf
nginx_enable_site zammad.conf
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
