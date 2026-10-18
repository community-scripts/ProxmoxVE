#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://zammad.com

APP="Zammad"
var_tags="${var_tags:-webserver;ticket-system}"
var_disk="${var_disk:-8}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/zammad ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping Service"
  systemctl stop zammad
  msg_ok "Stopped Service"

  if grep -qs "dl.packager.io" /etc/apt/sources.list.d/zammad*; then
    msg_info "Migrating Zammad Repository"
    rm -f /etc/apt/keyrings/pkgr-zammad.gpg
    setup_deb822_repo \
      "zammad" \
      "https://go.packager.io/srv/deb/zammad/zammad/gpg-key.asc" \
      "https://go.packager.io/srv/deb/zammad/zammad/stable/debian" \
      "$(get_os_info version_id)" \
      "main"
    msg_ok "Migrated Zammad Repository"
  fi

  REBUILD_INDEX=false
  if [[ "$(dpkg-query -W -f='${Version}' elasticsearch 2>/dev/null)" == 7.* ]]; then
    msg_info "Upgrading Elasticsearch to 8.x"
    systemctl stop elasticsearch
    if /usr/share/elasticsearch/bin/elasticsearch-plugin list 2>/dev/null | grep -q "ingest-attachment"; then
      $STD /usr/share/elasticsearch/bin/elasticsearch-plugin remove ingest-attachment
    fi
    rm -f /etc/apt/sources.list.d/elastic-7.x.list /usr/share/keyrings/elasticsearch-keyring.gpg
    setup_deb822_repo \
      "elasticsearch" \
      "https://artifacts.elastic.co/GPG-KEY-elasticsearch" \
      "https://artifacts.elastic.co/packages/8.x/apt" \
      "stable" \
      "main"
    ES_JAVA_OPTS="-Xms1g -Xmx1g" $STD apt install -y elasticsearch
    if [[ -f /etc/elasticsearch/jvm.options.dpkg-dist ]]; then
      mv /etc/elasticsearch/jvm.options.dpkg-dist /etc/elasticsearch/jvm.options
    fi
    rm -f /etc/elasticsearch/elasticsearch.yml.dpkg-dist
    rm -rf /var/lib/elasticsearch/*
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
    systemctl restart -q elasticsearch
    for i in $(seq 1 30); do
      if curl -s http://127.0.0.1:9200 >/dev/null 2>&1; then
        break
      fi
      sleep 2
    done
    REBUILD_INDEX=true
    msg_ok "Upgraded Elasticsearch to 8.x"
  fi

  msg_info "Updating Zammad"
  apt_update_safe
  $STD apt-mark hold zammad
  $STD apt upgrade -y
  $STD apt-mark unhold zammad
  $STD apt upgrade -y
  msg_ok "Updated Zammad"

  if [[ "$REBUILD_INDEX" == true ]]; then
    msg_info "Rebuilding Search Index"
    $STD zammad run rake zammad:searchindex:rebuild
    msg_ok "Rebuilt Search Index"
  fi

  msg_info "Starting Service"
  systemctl start zammad
  msg_ok "Started Service"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
