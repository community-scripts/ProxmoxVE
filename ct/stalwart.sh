#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/stalwartlabs/stalwart

APP="Stalwart"
var_tags="${var_tags:-mail;smtp;imap}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/stalwart ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [[ "$(cat ~/.stalwart 2>/dev/null)" == 0.* ]]; then
    if check_for_gh_release "stalwart" "stalwartlabs/stalwart" "v0.16.27" "v1 needs the migration below"; then
      msg_info "Stopping Service"
      systemctl stop stalwart
      msg_ok "Stopped Service"

      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "stalwart" "stalwartlabs/stalwart" "prebuild" "v0.16.27" "/opt/stalwart" "stalwart-$(arch_resolve x86_64 aarch64)-unknown-linux-gnu.tar.gz"
      chmod +x /opt/stalwart/stalwart

      msg_info "Starting Service"
      systemctl start stalwart
      msg_ok "Started Service"
    fi

    CONFIG_DIR="/opt/stalwart_data/etc"
    if [[ ! -t 0 ]]; then
      msg_warn "Stalwart v1 needs a migration that asks questions. Run update from the container console."
      exit
    fi
    if ! grep -q '"@type":"RocksDb"' "${CONFIG_DIR}/config.json"; then
      msg_error "This script migrates only the default RocksDB store to Stalwart v1. Migrate manually: https://stalw.art/docs/migration/upgrade-0-16/"
      exit 1
    fi
    SOURCE_PATH=$(grep -oP '"path":"\K[^"]+' "${CONFIG_DIR}/config.json")
    TARGET_PATH="${SOURCE_PATH%/}-v1/"
    DATA_KB=$(du -sk "$SOURCE_PATH" | cut -f1)
    FREE_KB=$(df -Pk "$(dirname "${SOURCE_PATH%/}")" | awk 'NR==2 {print $4}')
    if ((FREE_KB < DATA_KB * 11 / 10 + 524288)); then
      msg_error "The migration copies the data store ($((DATA_KB / 1024)) MB) but only $((FREE_KB / 1024)) MB are free. Resize the container disk and run update again."
      exit 1
    fi

    fetch_and_deploy_gh_release "stalwart-migrate" "stalwartlabs/stalwart-migrate" "prebuild" "latest" "/opt/stalwart-migrate" "stalwart-migrate-$(arch_resolve x86_64 aarch64)-unknown-linux-gnu.tar.xz"
    echo "{\"@type\":\"RocksDb\",\"path\":\"${TARGET_PATH}\"}" >"${CONFIG_DIR}/config-v1.json"

    msg_warn "Stalwart v1 cannot open the v0.16 data store, so it is copied to ${TARGET_PATH}. Mail is down while the copy runs."
    echo -e "${TAB}Press Enter to accept the recommended answers."
    /opt/stalwart-migrate/stalwart-migrate prepare --source "${CONFIG_DIR}/config.json" --state /opt/stalwart_data/migrate

    msg_info "Copying data to the v1 store"
    systemctl stop stalwart
    if ! $STD /opt/stalwart-migrate/stalwart-migrate run --final --yes --source "${CONFIG_DIR}/config.json" --target "${CONFIG_DIR}/config-v1.json" --state /opt/stalwart_data/migrate; then
      systemctl start stalwart
      msg_error "Migration failed, Stalwart v0.16 is running again. Logs: /opt/stalwart_data/migrate/logs"
      exit 1
    fi
    msg_ok "Copied data to the v1 store"

    mv "${CONFIG_DIR}/config.json" "${CONFIG_DIR}/config-0.16.json"
    mv "${CONFIG_DIR}/config-v1.json" "${CONFIG_DIR}/config.json"
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "stalwart" "stalwartlabs/stalwart" "prebuild" "latest" "/opt/stalwart" "stalwart-$(arch_resolve x86_64 aarch64)-unknown-linux-gnu.tar.gz"
    chmod +x /opt/stalwart/stalwart

    msg_info "Starting Service"
    systemctl start stalwart
    msg_ok "Started Service"
    msg_ok "Migrated to Stalwart $(cat ~/.stalwart)"
    msg_warn "OAuth clients have to sign in again. Search results stay incomplete until v1 has rebuilt the index."
    msg_warn "The v0.16 store stays in ${SOURCE_PATH} (${CONFIG_DIR}/config-0.16.json). Delete it once v1 works."
    exit
  fi

  if check_for_gh_release "stalwart" "stalwartlabs/stalwart"; then
    msg_info "Stopping Service"
    systemctl stop stalwart
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "stalwart" "stalwartlabs/stalwart" "prebuild" "latest" "/opt/stalwart" "stalwart-$(arch_resolve x86_64 aarch64)-unknown-linux-gnu.tar.gz"
    chmod +x /opt/stalwart/stalwart

    msg_info "Starting Service"
    systemctl start stalwart
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080/admin${CL}"
echo -e "${INFO}${YW}The bootstrap admin password was printed to the service log:${CL}"
echo -e "${TAB}${DEFAULT}${BGN}journalctl -u stalwart | grep -A8 'bootstrap mode'${CL}"
