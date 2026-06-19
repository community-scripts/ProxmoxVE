#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/apache/airflow

APP="Apache-Airflow"
var_tags="${var_tags:-workflow;scheduler;automation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
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

  if [[ ! -d /opt/airflow ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  INSTALLED=$(cat ~/.airflow 2>/dev/null || echo "0")
  LATEST=$(curl -fsSL "https://pypi.org/pypi/apache-airflow/json" | jq -r '.info.version')

  if [[ "$INSTALLED" == "$LATEST" ]]; then
    msg_ok "Already on the latest version (${LATEST})"
    exit
  fi

  msg_info "Stopping Services"
  systemctl stop airflow-api-server airflow-scheduler airflow-dag-processor airflow-triggerer
  msg_ok "Stopped Services"

  create_backup /opt/airflow/.env

  msg_info "Updating Apache Airflow to ${LATEST}"
  $STD uv pip install --python /opt/airflow/.venv/bin/python \
    "apache-airflow[postgres,fab]==${LATEST}" \
    --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-${LATEST}/constraints-3.12.txt"
  echo "${LATEST}" >~/.airflow
  msg_ok "Updated Apache Airflow to ${LATEST}"

  restore_backup

  msg_info "Running Database Migrations"
  set -a && source /opt/airflow/.env && set +a
  $STD /opt/airflow/.venv/bin/airflow db migrate
  msg_ok "Ran Database Migrations"

  msg_info "Starting Services"
  systemctl start airflow-api-server airflow-scheduler airflow-dag-processor airflow-triggerer
  msg_ok "Started Services"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
