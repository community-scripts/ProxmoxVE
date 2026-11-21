#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | Co-Author: CrazyWolf13, MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://changedetection.io/ | Github: https://github.com/dgtlmoon/changedetection.io

APP="Change Detection"
var_tags="${var_tags:-monitoring;crawler}"
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

  if [[ ! -f /etc/systemd/system/changedetection.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  ensure_dependencies libjpeg-dev poppler-utils file locales xvfb xauth python3

  msg_info "Generating Locales"
  for l in cs_CZ de_DE en_GB en_US es_ES fr_FR id_ID it_IT ja_JP ko_KR \
    pl_PL pt_BR ru_RU tr_TR uk_UA zh_CN zh_TW; do
    sed -i "s/^# *${l}.UTF-8 UTF-8/${l}.UTF-8 UTF-8/" /etc/locale.gen
  done
  $STD locale-gen
  if ! grep -q "^LC_ALL=" /opt/changedetection/.env 2>/dev/null; then
    echo "LC_ALL=en_US.UTF-8" >>/opt/changedetection/.env
  fi
  msg_ok "Generated Locales"

  VENV_PATH="/opt/changedetection/.venv"
  CHANGEDETECTION_BIN="${VENV_PATH}/bin/changedetection.io"
  SERVICE_FILE="/etc/systemd/system/changedetection.service"

  PYTHON_VERSION="3.13" setup_uv

  msg_info "Updating ${APP}"
  [[ -x "$CHANGEDETECTION_BIN" ]] || $STD uv venv --clear "$VENV_PATH"
  $STD uv pip install --python "$VENV_PATH/bin/python" --upgrade changedetection.io playwright
  if ! grep -q "$CHANGEDETECTION_BIN" "$SERVICE_FILE"; then
    sed -i "s|^ExecStart=.*|ExecStart=$CHANGEDETECTION_BIN -d /opt/changedetection -p 5000|" "$SERVICE_FILE"
  fi
  msg_ok "Updated ${APP}"

  if [[ ! -f /etc/apt/sources.list.d/google-chrome.sources ]]; then
    msg_info "Installing Chrome"
    setup_deb822_repo \
      "google-chrome" \
      "https://dl.google.com/linux/linux_signing_key.pub" \
      "https://dl.google.com/linux/chrome/deb/" \
      "stable"
    $STD apt install -y google-chrome-stable
    rm -f /etc/apt/sources.list.d/google-chrome.list
    msg_ok "Installed Chrome"
  else
    msg_info "Updating Chrome"
    apt_update_safe
    $STD apt install -y --only-upgrade google-chrome-stable
    msg_ok "Updated Chrome"
  fi

  if check_for_gh_release "sockpuppetbrowser" "dgtlmoon/sockpuppetbrowser"; then
    [[ -f /etc/systemd/system/sockpuppetbrowser.service ]] && systemctl stop sockpuppetbrowser
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "sockpuppetbrowser" "dgtlmoon/sockpuppetbrowser" "tarball"

    msg_info "Setting up SockPuppetBrowser"
    id -u chrome &>/dev/null || useradd -r -m -s /usr/sbin/nologin chrome
    $STD uv venv --clear --python /usr/bin/python3 /opt/sockpuppetbrowser/.venv
    $STD uv pip install --python /opt/sockpuppetbrowser/.venv/bin/python -r /opt/sockpuppetbrowser/requirements.txt
    msg_ok "Set up SockPuppetBrowser"
  fi

  if [[ -f /etc/systemd/system/browserless.service ]]; then
    msg_info "Replacing Browserless with SockPuppetBrowser"
    systemctl disable -q --now browserless
    rm -f /etc/systemd/system/browserless.service
    rm -rf /opt/browserless /root/.cache/ms-playwright
    $STD apt purge -y microsoft-edge-stable
    rm -f /etc/apt/sources.list.d/microsoft-edge-stable.list
    sed -i 's/browserless\.service/sockpuppetbrowser.service/g' "$SERVICE_FILE"
    sed -i -e '/^WEBDRIVER_URL=/d' \
      -e 's|^PLAYWRIGHT_DRIVER_URL=ws://localhost:3000/chrome.*|PLAYWRIGHT_DRIVER_URL=ws://127.0.0.1:3000/?headful=true\&--window-size=1920,1080|' \
      /opt/changedetection/.env
    msg_ok "Replaced Browserless with SockPuppetBrowser"
  fi

  if [[ ! -f /etc/systemd/system/sockpuppetbrowser.service ]]; then
    msg_info "Creating SockPuppetBrowser Service"
    cat <<EOF >/etc/systemd/system/sockpuppetbrowser.service
[Unit]
Description=SockPuppetBrowser
After=network.target

[Service]
User=chrome
Group=chrome
WorkingDirectory=/opt/sockpuppetbrowser/backend
Environment=CHROME_BIN=/usr/bin/google-chrome-stable
Environment=LOG_LEVEL=INFO
ExecStart=/opt/sockpuppetbrowser/.venv/bin/python server.py --host 127.0.0.1 --port 3000 --sport 8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable -q sockpuppetbrowser
    msg_ok "Created SockPuppetBrowser Service"
  fi

  systemctl daemon-reload
  systemctl restart sockpuppetbrowser
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
