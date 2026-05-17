#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
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

  MIGRATE_V1=0
  if [[ "$CURRENT_VERSION" == 0.* ]]; then
    MIGRATE_V1=1
    DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 50 ]; then
      echo -e "\n${RD}Warning: Less than 50% free storage remaining on the root disk.${CL}"
      echo -e "${RD}Bichon v1 data migration temporarily duplicates data and requires free space for it.${CL}"
      read -r -p "Are you sure you want to proceed with the update? (y/N): " proceed
      if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
        msg_error "Update cancelled by user."
        exit
      fi
    fi

    RAM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$RAM_TOTAL" -lt 2000 ]; then
      echo -e "\n${RD}Warning: LXC has less than 2GB of RAM allocated (${RAM_TOTAL}MB).${CL}"
      echo -e "${RD}Bichon v1 data migration consumes significant memory and may crash if insufficient.${CL}"
      read -r -p "Are you sure you want to proceed with the update? (y/N): " proceed_ram
      if [[ ! "$proceed_ram" =~ ^[Yy]$ ]]; then
        msg_error "Update cancelled by user."
        exit
      fi
    fi
  fi

  if check_for_gh_release "bichon" "rustmailer/bichon"; then
    msg_info "Stopping service"
    systemctl stop bichon
    msg_ok "Stopped service"

    cp /opt/bichon/bichon.env /tmp/bichon.env.backup
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "bichon" "rustmailer/bichon" "prebuild" "latest" "/opt/bichon" "bichon-*-x86_64-unknown-linux-gnu.tar.gz"
    cp /tmp/bichon.env.backup /opt/bichon/bichon.env

    if [ "$MIGRATE_V1" -eq 1 ]; then
      msg_info "Running Bichon v1 Data Migration"
      apt-get install -y expect >/dev/null 2>&1
      expect <<'EOF'
set timeout -1
spawn /opt/bichon/bichon-admin
expect "*Select an operation*"
sleep 0.2
send "\033\[B\r"
expect "*--bichon-root-dir*"
sleep 0.2
send "/opt/bichon-data\r"
expect "*--bichon-index-dir*"
sleep 0.2
send "\r"
expect "*--bichon-data-dir*"
sleep 0.2
send "\r"
expect "*Ready to migrate?*"
sleep 0.2
send "y"
expect "*Enter batch size*"
sleep 0.2
send "1000\r"
expect eof
catch wait
EOF
      msg_ok "Migration completed"

      msg_info "Cleaning up legacy Bichon v0.3.x storage files"
      rm -rf /opt/bichon-data/envelope
      rm -rf /opt/bichon-data/eml
      rm -f /opt/bichon-data/mailbox.db
      rm -f /opt/bichon-data/meta.db
      msg_ok "Cleanup completed"

      msg_info "Updating Bichon service for v1"
      sed -i 's|ExecStart=/opt/bichon/bichon|ExecStart=/opt/bichon/bichon-server|g; s|RestartSec=5|RestartSec=5\n\nLimitNOFILE=65536|g' /etc/systemd/system/bichon.service
      systemctl daemon-reload
      msg_ok "Service updated"
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:15630${CL}"
