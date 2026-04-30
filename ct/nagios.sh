#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CanbiZ (MickLesk)
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

  msg_info "Backing up Configuration"
  cp -a /usr/local/nagios/etc /opt/nagios-etc-backup
  msg_ok "Backed up Configuration"

  if check_for_gh_release "nagios" "NagiosEnterprises/nagioscore"; then
    msg_info "Stopping Nagios"
    systemctl stop nagios
    msg_ok "Stopped Nagios"

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
    $STD make install-webconf
    $STD a2enmod rewrite
    $STD a2enmod cgi
    msg_ok "Built Nagios Core"

    msg_info "Starting Nagios"
    systemctl restart apache2
    systemctl start nagios
    msg_ok "Started Nagios"
  fi

  if check_for_gh_release "nagios-plugins" "nagios-plugins/nagios-plugins"; then
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
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/nagios${CL}"
