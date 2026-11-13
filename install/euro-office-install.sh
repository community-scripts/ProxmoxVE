#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Euro-Office/DocumentServer

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_nonfree

msg_info "Installing Dependencies"
$STD apt install -y \
  nginx-extras \
  rabbitmq-server
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="euro_office" PG_DB_USER="euro_office" setup_postgresql_db

msg_info "Configuring RabbitMQ"
RMQ_PASS=$(random_password)
$STD rabbitmqctl add_user euro_office "$RMQ_PASS"
$STD rabbitmqctl set_permissions -p / euro_office ".*" ".*" ".*"
msg_ok "Configured RabbitMQ"

msg_info "Preseeding Euro-Office"
debconf-set-selections <<EOF
ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true
euro-office-documentserver ds/db-type string postgres
euro-office-documentserver ds/db-host string localhost
euro-office-documentserver ds/db-port string 5432
euro-office-documentserver ds/db-name string euro_office
euro-office-documentserver ds/db-user string euro_office
euro-office-documentserver ds/db-pwd password ${PG_DB_PASS}
euro-office-documentserver ds/rabbitmq-host string localhost
euro-office-documentserver ds/rabbitmq-user string euro_office
euro-office-documentserver ds/rabbitmq-pwd password ${RMQ_PASS}
euro-office-documentserver ds/jwt-enabled boolean true
euro-office-documentserver ds/jwt-secret string $(random_password 32)
EOF
msg_ok "Preseeded Euro-Office"

fetch_and_deploy_gh_release "euro-office" "Euro-Office/DocumentServer" "binary" "latest" "" "euro-office-documentserver_*_$(arch_resolve).deb"

msg_info "Starting Euro-Office"
systemctl restart ds-metrics ds-converter ds-docservice nginx
for _ in {1..60}; do
  [[ "$(curl -fs http://127.0.0.1/healthcheck)" == "true" ]] && break
  sleep 2
done
msg_ok "Started Euro-Office"

motd_ssh
customize
cleanup_lxc
