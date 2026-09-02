#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rustmailer/bichon

APP="Bichon"
var_tags="${var_tags:-email;archive}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /opt/bichon ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  CURRENT_VERSION="unknown"
  if [[ -f /root/.bichon ]]; then
    CURRENT_VERSION=$(cat /root/.bichon)
  fi

  if [[ $CURRENT_VERSION != 1.* && $CURRENT_VERSION != 2.* ]]; then
    msg_error "Installed ${APP} version (${CURRENT_VERSION}) is too old for an automatic update to v2.x."
    msg_error "Please create a new ${APP} container and migrate your data manually."
    msg_error "Guide: https://github.com/rustmailer/bichon/wiki/Bichon-v2.x-Migration-Guide"
    exit
  fi

  MIGRATE_V2=0
  if [[ $CURRENT_VERSION == 1.* ]]; then
    MIGRATE_V2=1
    STORAGE_KB=$(du -sk /opt/bichon-data/bichon-storage 2>/dev/null | awk '{print $1}')
    FREE_KB=$(df -Pk /opt/bichon-data | awk 'NR==2 {print $4}')
    if [[ -n "$STORAGE_KB" && -n "$FREE_KB" && "$FREE_KB" -lt "$STORAGE_KB" ]]; then
      echo -e "\n${RD}Warning: migration needs about $((STORAGE_KB / 1024))MB, only $((FREE_KB / 1024))MB free.${CL}"
      echo -e "${RD}The new bichon-blob store is written alongside the existing fjall data.${CL}"
      read -r -p "Are you sure you want to proceed with the update? (y/N): " proceed
      if [[ ! $proceed =~ ^[Yy]$ ]]; then
        msg_error "Update cancelled by user."
        exit
      fi
    fi
  fi

  if check_for_gh_release "bichon" "rustmailer/bichon"; then
    msg_info "Stopping service"
    systemctl stop bichon
    msg_ok "Stopped service"

    create_backup /opt/bichon/bichon.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "bichon" "rustmailer/bichon" "prebuild" "latest" "/opt/bichon" "bichon-*-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.tar.gz"
    restore_backup

    if [ "$MIGRATE_V2" -eq 1 ]; then
      msg_info "Migrating storage from fjall to bichon-blob (patience)"
      $STD apt install -y expect
      # Menu: 0 Reset Password, 1 Migrate v0.3.7, 2 Migrate v1.x, 3 Exit
      $STD expect <<'EOF'
set timeout -1
spawn /opt/bichon/bichon-admin
expect "*Select an operation*"
send "\033\[B\033\[B\r"
expect "*--bichon-root-dir*"
send "/opt/bichon-data\r"
expect "*--bichon-data-dir*"
send "\r"
expect "*batch size*"
send "1000\r"
expect eof
catch wait
EOF
      $STD apt remove --purge expect -y
      $STD apt autoremove -y

      if [[ ! -d /opt/bichon-data/bichon-storage/blobs ]] ||
        [[ "$(cat /opt/bichon-data/STORAGE_VERSION 2>/dev/null)" != "2" ]]; then
        msg_error "Storage migration did not complete - service left stopped, legacy data untouched."
        msg_error "Run /opt/bichon/bichon-admin manually and select 'Migrate v1.x Storage to v2.x'."
        exit
      fi
      msg_ok "Migrated storage to bichon-blob"

      msg_info "Removing legacy fjall files"
      rm -rf /opt/bichon-data/bichon-storage/keyspaces
      rm -f /opt/bichon-data/bichon-storage/0.jnl
      rm -f /opt/bichon-data/bichon-storage/lock
      rm -f /opt/bichon-data/bichon-storage/version
      msg_ok "Removed legacy fjall files"
    fi

    msg_info "Starting service"
    systemctl start bichon
    msg_ok "Service started"
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
echo -e "${GATEWAY}${BGN}http://${IP}:15630${CL}"
