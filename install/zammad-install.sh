#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
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
  nginx \
  apt-transport-https
msg_ok "Installed Dependencies"

msg_info "Setting up Elasticsearch"
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
cat <<EOF | sudo tee /etc/apt/sources.list.d/elasticsearch.sources >/dev/null
Types: deb
URIs: https://artifacts.elastic.co/packages/7.x/apt
Suites: stable
Components: main
Signed-By: /usr/share/keyrings/elasticsearch-keyring.gpg
EOF
$STD apt update
$STD apt -y install elasticsearch
echo "-Xms2g" >>/etc/elasticsearch/jvm.options
echo "-Xmx2g" >>/etc/elasticsearch/jvm.options
$STD /usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-attachment -b
systemctl enable -q elasticsearch
systemctl restart -q elasticsearch
msg_ok "Setup Elasticsearch"

msg_info "Installing Zammad"
curl -fsSL https://dl.packager.io/srv/zammad/zammad/key | gpg --dearmor | sudo tee /etc/apt/keyrings/pkgr-zammad.gpg >/dev/null
cat <<EOF | sudo tee /etc/apt/sources.list.d/zammad.sources >/dev/null
Types: deb
URIs: https://dl.packager.io/srv/deb/zammad/zammad/stable/debian
Suites: 12
Components: main
Signed-By: /etc/apt/keyrings/pkgr-zammad.gpg
EOF
$STD apt update
$STD apt -y install zammad
$STD zammad run rails r "Setting.set('es_url', 'http://localhost:9200')"
$STD zammad run rake zammad:searchindex:rebuild
msg_ok "Installed Zammad"

msg_info "Setup Services"
cp /opt/zammad/contrib/nginx/zammad.conf /etc/nginx/sites-available/zammad.conf
IPADDRESS=$(hostname -I | awk '{print $1}')
sed -i "s/server_name localhost;/server_name $IPADDRESS;/g" /etc/nginx/sites-available/zammad.conf
$STD systemctl reload nginx
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
