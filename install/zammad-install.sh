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

import_local_ip

msg_info "Setting up Elasticsearch"
setup_deb822_repo \
  "elasticsearch" \
  "https://artifacts.elastic.co/GPG-KEY-elasticsearch" \
  "https://artifacts.elastic.co/packages/7.x/apt" \
  "stable" \
  "main"
$STD apt install -y elasticsearch
echo "-Xms2g" >>/etc/elasticsearch/jvm.options
echo "-Xmx2g" >>/etc/elasticsearch/jvm.options
$STD /usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-attachment -b
systemctl enable -q elasticsearch
systemctl restart -q elasticsearch
msg_ok "Setup Elasticsearch"

msg_info "Installing Zammad"
setup_deb822_repo \
  "zammad" \
  "https://dl.packager.io/srv/zammad/zammad/key" \
  "https://dl.packager.io/srv/deb/zammad/zammad/stable/debian" \
  "$(get_os_info version_id)" \
  "main"
$STD apt install -y zammad
$STD zammad run rails r "Setting.set('es_url', 'http://localhost:9200')"
$STD zammad run rake zammad:searchindex:rebuild
msg_ok "Installed Zammad"

msg_info "Setup Services"
cp /opt/zammad/contrib/nginx/zammad.conf /etc/nginx/sites-available/zammad.conf
sed -i "s/server_name localhost;/server_name $LOCAL_IP;/g" /etc/nginx/sites-available/zammad.conf
$STD systemctl reload nginx
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
