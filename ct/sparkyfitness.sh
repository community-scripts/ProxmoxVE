#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Tom Frenzel (tomfrenzel)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/CodeWithCJ/SparkyFitness

APP="SparkyFitness"
var_tags="${var_tags:-health;fitness}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -d /opt/sparkyfitness ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  GARMIN_INSTALLED=0
  if [[ -d /opt/sparkyfitness/SparkyFitnessGarmin/.venv ]]; then
    GARMIN_INSTALLED=1
  fi

  if [[ "${GARMIN_INSTALLED}" == "0" ]]; then
    CHOICE=$(msg_menu "SparkyFitness Update Options" \
      "1" "Update SparkyFitness" \
      "2" "Install SparkyFitness Garmin Microservice")
  fi

  case "${CHOICE:=1}" in
  1)
    if check_for_gh_release "sparkyfitness" "CodeWithCJ/SparkyFitness"; then

    msg_info "Stopping Services"
    if [[ "${GARMIN_INSTALLED}" == "1" ]]; then
      systemctl stop sparkyfitness-server sparkyfitness-garmin nginx
    else
      systemctl stop sparkyfitness-server nginx
    fi
    msg_ok "Stopped Services"

    msg_info "Backing up data"
    mkdir -p /opt/sparkyfitness_backup
    if [[ -d /opt/sparkyfitness/SparkyFitnessServer/uploads ]]; then
      cp -r /opt/sparkyfitness/SparkyFitnessServer/uploads /opt/sparkyfitness_backup/
    fi
    if [[ -d /opt/sparkyfitness/SparkyFitnessServer/backup ]]; then
      cp -r /opt/sparkyfitness/SparkyFitnessServer/backup /opt/sparkyfitness_backup/
    fi
    msg_ok "Backed up data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "sparkyfitness" "CodeWithCJ/SparkyFitness" "tarball"

    PNPM_VERSION="$(jq -r '.packageManager | split("@")[1]' /opt/sparkyfitness/package.json)"
    NODE_VERSION="25" NODE_MODULE="pnpm@${PNPM_VERSION}" setup_nodejs

    msg_info "Updating SparkyFitness Backend"
    cd /opt/sparkyfitness/SparkyFitnessServer
    $STD npm install
    msg_ok "Updated SparkyFitness Backend"

    msg_info "Updating SparkyFitness Frontend (Patience)"
    cd /opt/sparkyfitness/SparkyFitnessFrontend
    $STD pnpm install
    $STD pnpm run build
    cp -a /opt/sparkyfitness/SparkyFitnessFrontend/dist/. /var/www/sparkyfitness/
    msg_ok "Updated SparkyFitness Frontend"

    if [[ "${GARMIN_INSTALLED}" == "1" ]]; then
      PYTHON_VERSION="3.13" setup_uv
      msg_info "Updating SparkyFitness Garmin Service"
      cd /opt/sparkyfitness/SparkyFitnessGarmin
      $STD uv venv --clear "/opt/sparkyfitness/SparkyFitnessGarmin/.venv"
      $STD uv pip install -r requirements.txt --python /opt/sparkyfitness/SparkyFitnessGarmin/.venv/bin/python3
      msg_ok "Updated SparkyFitness Garmin Service"
    fi

    msg_info "Restoring data"
    cp -r /opt/sparkyfitness_backup/. /opt/sparkyfitness/SparkyFitnessServer/
    rm -rf /opt/sparkyfitness_backup
    msg_ok "Restored data"

    msg_info "Starting Services"
    if [[ "${GARMIN_INSTALLED}" == "1" ]]; then
      $STD systemctl start sparkyfitness-server sparkyfitness-garmin nginx
    else
      $STD systemctl start sparkyfitness-server nginx
    fi
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
    exit
    ;;
  2)
    PYTHON_VERSION="3.13" setup_uv
    msg_info "Setting up SparkyFitness Garmin microservice"
    cd /opt/sparkyfitness/SparkyFitnessGarmin
    $STD uv venv --clear /opt/sparkyfitness/SparkyFitnessGarmin/.venv
    $STD uv pip install -r /opt/sparkyfitness/SparkyFitnessGarmin/requirements.txt
    sed -i -e "s|^#\?GARMIN_MICROSERVICE_URL=.*|GARMIN_MICROSERVICE_URL=http://${LOCAL_IP}:8000|" "/etc/sparkyfitness/.env"
    cat <<EOF >/etc/systemd/system/sparkyfitness-garmin.service
[Unit]
Description=SparkyFitness Garmin Microservice
After=network.target sparkyfitness-server.service
Requires=sparkyfitness-server.service

[Service]
Type=simple
WorkingDirectory=/opt/sparkyfitness/SparkyFitnessGarmin
EnvironmentFile=/etc/sparkyfitness/.env
ExecStart=/opt/sparkyfitness/SparkyFitnessGarmin/.venv/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable -q --now sparkyfitness-garmin
    systemctl restart sparkyfitness-server
    msg_ok "Setup SparkyFitness Garmin microservice"
    exit
    ;;
  esac
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
