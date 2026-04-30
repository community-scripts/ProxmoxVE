#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: GitHub Copilot (GPT-5.3-Codex)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/NagiosEnterprises/nagioscore

APP="Nagios"
var_tags="${var_tags:-monitoring;alerts;infrastructure}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-20}"
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

  if [[ ! -f /usr/local/nagios/etc/nagios.cfg ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  local core_update=0
  local plugins_update=0

  if check_for_gh_release "nagios" "NagiosEnterprises/nagioscore"; then
    core_update=1
  fi

  if check_for_gh_release "nagios-plugins" "nagios-plugins/nagios-plugins"; then
    plugins_update=1
  fi

  if [[ "$core_update" == "1" || "$plugins_update" == "1" ]]; then
    msg_info "Stopping Services"
    systemctl stop nagios
    systemctl stop apache2
    msg_ok "Stopped Services"

    msg_info "Backing up Configuration"
    cp -a /usr/local/nagios/etc /opt/nagios-etc-backup
    msg_ok "Backed up Configuration"

    if [[ "$core_update" == "1" ]]; then
      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "nagios" "NagiosEnterprises/nagioscore" "tarball"

      msg_info "Building Nagios Core"
      cd /opt/nagios
      $STD ./configure --with-httpd-conf=/etc/apache2/sites-enabled
      $STD make all
      $STD make install-groups-users
      usermod -a -G nagios www-data
      $STD make install
      $STD make install-daemoninit
      $STD make install-commandmode
      $STD make install-config
      $STD make install-webconf
      a2enmod rewrite >/dev/null 2>&1
      a2enmod cgi >/dev/null 2>&1
      msg_ok "Built Nagios Core"
    fi

    if [[ "$plugins_update" == "1" ]]; then
      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "nagios-plugins" "nagios-plugins/nagios-plugins" "tarball"

      msg_info "Building Nagios Plugins"
      cd /opt/nagios-plugins
      $STD ./tools/setup
      $STD ./configure
      $STD make
      $STD make install
      msg_ok "Built Nagios Plugins"
    fi

    msg_info "Restoring Configuration"
    rm -rf /usr/local/nagios/etc
    cp -a /opt/nagios-etc-backup /usr/local/nagios/etc
    rm -rf /opt/nagios-etc-backup
    msg_ok "Restored Configuration"

    msg_info "Starting Services"
    systemctl start apache2
    systemctl start nagios
    msg_ok "Started Services"

    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/nagios${CL}"
