#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://changedetection.io/ | Github: https://github.com/dgtlmoon/changedetection.io

APP="Change Detection"
var_tags="${var_tags:-monitoring;crawler}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
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

  if [[ ! -f /etc/systemd/system/changedetection.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  ensure_dependencies libjpeg-dev

  NODE_VERSION="24" setup_nodejs

  VENV_PATH="/opt/changedetection/.venv"
  CHANGEDETECTION_BIN="${VENV_PATH}/bin/changedetection.io"

  PYTHON_VERSION="3.13" setup_uv

  if [[ ! -d "$VENV_PATH" || ! -x "$CHANGEDETECTION_BIN" ]]; then
    msg_info "Migrating to uv/venv"
    rm -rf "$VENV_PATH"
    $STD uv venv --clear "$VENV_PATH"
    $STD "$VENV_PATH/bin/python" -m ensurepip --upgrade
    $STD "$VENV_PATH/bin/python" -m pip install --upgrade pip
    $STD "$VENV_PATH/bin/python" -m pip install changedetection.io playwright
    msg_ok "Migrated to uv/venv"
  else
    msg_info "Updating ${APP}"
    $STD "$VENV_PATH/bin/python" -m pip install --upgrade changedetection.io playwright
    msg_ok "Updated ${APP}"
  fi

  SERVICE_FILE="/etc/systemd/system/changedetection.service"
  if ! grep -q "${VENV_PATH}/bin/changedetection.io" "$SERVICE_FILE"; then
    msg_info "Updating systemd service"
    sed -i "s|^ExecStart=.*|ExecStart=${VENV_PATH}/bin/changedetection.io -d /opt/changedetection -p 5000|" "$SERVICE_FILE"
    $STD systemctl daemon-reload
    msg_ok "Updated systemd service"
  fi

  if [[ -f /etc/systemd/system/browserless.service ]]; then
    msg_info "Updating Browserless (Patience)"
    $STD git -C /opt/browserless/ fetch --all
    $STD git -C /opt/browserless/ reset --hard origin/main
    $STD npm update --prefix /opt/browserless
    $STD npm ci --include=optional --include=dev --prefix /opt/browserless
    $STD /opt/browserless/node_modules/playwright-core/cli.js install --with-deps
    # Update Chrome separately, as it has to be done with the force option. Otherwise the installation of other browsers will not be done if Chrome is already installed.
    $STD /opt/browserless/node_modules/playwright-core/cli.js install --force chrome
    $STD /opt/browserless/node_modules/playwright-core/cli.js install --force msedge
    $STD /opt/browserless/node_modules/playwright-core/cli.js install chromium firefox webkit
    $STD npm install --prefix /opt/browserless esbuild typescript ts-node @types/node --save-dev
    $STD npm run build --prefix /opt/browserless
    $STD npm run build:function --prefix /opt/browserless
    $STD npm prune production --prefix /opt/browserless
    systemctl restart browserless
    msg_ok "Updated Browserless"
  else
    msg_error "No Browserless Installation Found!"
  fi

  systemctl restart changedetection
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:5000${CL}"
