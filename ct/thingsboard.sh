#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/thingsboard/thingsboard

APP="ThingsBoard"
var_tags="${var_tags:-iot;platform}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /usr/share/thingsboard ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  JAVA_VERSION="25" setup_java

  if ! grep -q "install.data_dir" /etc/thingsboard/conf/thingsboard.conf; then
    msg_info "Restoring Package Defaults"
    cat <<'EOF' >>/etc/thingsboard/conf/thingsboard.conf

export JAVA_OPTS="$JAVA_OPTS -Dplatform=deb -Dinstall.data_dir=/usr/share/thingsboard/data"
export JAVA_OPTS="$JAVA_OPTS -Xlog:gc*,heap*,age*,safepoint=debug:file=/var/log/thingsboard/gc.log:time,uptime,level,tags:filecount=10,filesize=10M"
export JAVA_OPTS="$JAVA_OPTS -XX:+IgnoreUnrecognizedVMOptions -XX:+HeapDumpOnOutOfMemoryError"
export JAVA_OPTS="$JAVA_OPTS -XX:-UseBiasedLocking -XX:+UseTLAB -XX:+ResizeTLAB -XX:+PerfDisableSharedMem -XX:+UseCondCardMark"
export JAVA_OPTS="$JAVA_OPTS -XX:+UseG1GC -XX:MaxGCPauseMillis=500 -XX:+UseStringDeduplication -XX:+ParallelRefProcEnabled -XX:MaxTenuringThreshold=10"
export LOG_FILENAME=thingsboard.out
export LOADER_PATH=/usr/share/thingsboard/conf,/usr/share/thingsboard/extensions
export SQL_DATA_FOLDER=/usr/share/thingsboard/data/sql
EOF
    systemctl restart thingsboard
    msg_ok "Restored Package Defaults"
  fi

  if check_for_gh_release "thingsboard" "thingsboard/thingsboard"; then
    msg_info "Stopping Service"
    systemctl stop thingsboard
    msg_ok "Stopped Service"

    DPKG_FORCE_CONFOLD=1 fetch_and_deploy_gh_release "thingsboard" "thingsboard/thingsboard" "binary" "latest" "/tmp" "thingsboard-*.deb"

    msg_info "Running Database Upgrade"
    $STD /usr/share/thingsboard/bin/install/upgrade.sh
    msg_ok "Ran Database Upgrade"

    msg_info "Starting Service"
    systemctl start thingsboard
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
