#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Original Author: Slaviša Arežina (tremor021)
# Revamped Script: Floris Claessens (FlorisCl)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wger-project/wger

APP="wger"
var_tags="${var_tags:-management;fitness}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-10}"
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

  WGER_HOME="/home/wger"
  WGER_SRC="${WGER_HOME}/src"
  WGER_VENV="${WGER_HOME}/venv"

  if [[ ! -d "${WGER_HOME}" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/wger-project/wger/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then

  msg_info "Updating $APP to v${RELEASE}"

  msg_info "Stopping services"
  systemctl stop celery celery-beat apache2 2>/dev/null || true
  msg_ok "Services stopped"
 
  msg_info "Downloading version ${RELEASE}"

  temp_file=$(mktemp -d)

  curl -fsSL https://github.com/wger-project/wger/archive/refs/tags/${RELEASE}.tar.gz \
    | tar xz -C "${temp_file}"

  rsync -a --delete \
    "${temp_file}/wger-${RELEASE}/" "${WGER_SRC}/"
  rm -rf "${temp_file}"
  msg_ok "Source updated"

  msg_info "Ensuring Python virtual environment exists"
  if [[ ! -x "${WGER_VENV}/bin/python" ]]; then
    msg_warn "Virtual environment missing or broken, recreating"
    rm -rf "${WGER_VENV}"
    $STD python3 -m venv "${WGER_VENV}"
  fi
  msg_ok "Python virtual environment ready"

  cd "${WGER_SRC}" || exit
  
  msg_info "Updating Python dependencies"
    export DJANGO_SETTINGS_MODULE=settings.main
    export PYTHONPATH="${WGER_SRC}"
    export USE_CELERY=True

    $STD "${WGER_VENV}/bin/python" -m pip install -U pip setuptools wheel
    $STD "${WGER_VENV}/bin/python" -m pip install -e .
  msg_ok "Dependencies updated"

  msg_info "Running database migrations"
   $STD "${WGER_VENV}/bin/python" manage.py migrate --no-input
  msg_ok "Database migrated"

  msg_info "Collecting static files"
   $STD "${WGER_VENV}/bin/python" manage.py collectstatic --no-input
  msg_ok "Static files collected"

  cd "${WGER_SRC}" || exit 1


  if command -v npm &>/dev/null && [[ -f package.json ]]; then
    msg_info "Building frontend assets"
    $STD npm install
    $STD npm run build:css:sass
    msg_ok "Frontend assets built"
  else
    msg_info "Skipping frontend build (npm or package.json not found)"
  fi

  msg_info "Starting services"
  systemctl start apache2
  systemctl start celery celery-beat
  msg_ok "Services started"

  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP} to v${RELEASE}"
  else 
    msg_info "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit 0
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
