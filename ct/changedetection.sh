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

wait_http() {
  local -r url="$1" timeout="${2:-30}"
  local -r deadline=$((SECONDS + timeout))
  local code
  while ((SECONDS < deadline)); do
    code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 "$url" 2>/dev/null)" || code="000"
    [[ "$code" =~ ^([23][0-9][0-9]|401|403)$ ]] && return 0
    sleep 2
  done
  return 1
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  local -r CDIO_DIR="/opt/changedetection"
  local -r CDIO_ENV="${CDIO_DIR}/.env"
  local -r CDIO_VENV="${CDIO_DIR}/.venv"
  local -r CDIO_BIN="${CDIO_VENV}/bin/changedetection.io"
  local -r CDIO_UNIT="/etc/systemd/system/changedetection.service"
  local -r CDIO_URL="http://127.0.0.1:5000/"

  local -r SOCKPUPPET_DIR="/opt/sockpuppet"
  local -r SOCKPUPPET_UNIT="/etc/systemd/system/sockpuppet.service"
  local -r SOCKPUPPET_STATS="http://127.0.0.1:8080/stats"

  local -r BROWSERLESS_UNIT="/etc/systemd/system/browserless.service"

  if [[ ! -f "$CDIO_UNIT" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  ensure_dependencies libjpeg-dev poppler-utils file locales xvfb xauth

  msg_info "Regenerating Locales"
  for l in cs_CZ de_DE en_GB en_US es_ES fr_FR id_ID it_IT ja_JP ko_KR \
    pl_PL pt_BR ru_RU tr_TR uk_UA zh_CN zh_TW; do
    sed -i "s/^# *${l}.UTF-8 UTF-8/${l}.UTF-8 UTF-8/" /etc/locale.gen
  done
  $STD locale-gen
  if ! grep -q "^LC_ALL=" "$CDIO_ENV" 2>/dev/null; then
    echo "LC_ALL=en_US.UTF-8" >>"$CDIO_ENV"
  fi
  msg_ok "Regenerated Locales"

  # sockpuppet runs as the non-root chrome user, so uv's Python must live outside /root (mode 700).
  export UV_PYTHON_INSTALL_DIR=/opt/uv-python
  PYTHON_VERSION="3.13" setup_uv

  if [[ ! -d "$CDIO_VENV" || ! -x "$CDIO_BIN" ]]; then
    msg_info "Migrating to uv/venv"
    rm -rf "$CDIO_VENV"
    $STD uv venv --clear "$CDIO_VENV"
    $STD "$CDIO_VENV/bin/python" -m ensurepip --upgrade
    $STD "$CDIO_VENV/bin/python" -m pip install --upgrade pip
    $STD "$CDIO_VENV/bin/python" -m pip install changedetection.io playwright
    msg_ok "Migrated to uv/venv"
  else
    msg_info "Updating ${APP}"
    $STD "$CDIO_VENV/bin/python" -m pip install --upgrade changedetection.io playwright
    msg_ok "Updated ${APP}"
  fi

  if ! grep -qF "$CDIO_BIN" "$CDIO_UNIT"; then
    msg_info "Updating systemd service"
    sed -i "s|^ExecStart=.*|ExecStart=${CDIO_BIN} -d ${CDIO_DIR} -p 5000|" "$CDIO_UNIT"
    $STD systemctl daemon-reload
    msg_ok "Updated systemd service"
  fi

  msg_info "Updating Chrome"
  if [[ ! -f /etc/apt/sources.list.d/google-chrome.sources ]]; then
    setup_deb822_repo "google-chrome" \
      "https://dl.google.com/linux/linux_signing_key.pub" \
      "https://dl.google.com/linux/chrome/deb/" "stable"
  else
    apt_update_safe
  fi
  $STD apt install -y google-chrome-stable
  msg_ok "Updated Chrome"

  groupadd -f chrome 2>/dev/null || true
  id -u chrome >/dev/null 2>&1 ||
    useradd --system --create-home --shell /usr/sbin/nologin -g chrome chrome

  if check_for_gh_branch "sockpuppet" "dgtlmoon/sockpuppetbrowser" "master"; then
    systemctl stop sockpuppet 2>/dev/null || true
    fetch_and_deploy_gh_branch "sockpuppet" "dgtlmoon/sockpuppetbrowser" "master"
    $STD uv venv --clear --python 3.12 "${SOCKPUPPET_DIR}/.venv"
    $STD uv pip install --python "${SOCKPUPPET_DIR}/.venv/bin/python" -r "${SOCKPUPPET_DIR}/requirements.txt"
  fi

  if [[ ! -f "$SOCKPUPPET_UNIT" ]]; then
    cat <<EOF >"$SOCKPUPPET_UNIT"
[Unit]
Description=sockpuppetbrowser service
After=network.target
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=chrome
Group=chrome
WorkingDirectory=${SOCKPUPPET_DIR}/backend
Environment=CHROME_BIN=/usr/bin/google-chrome-stable
Environment=CHROME_HEADFUL=true
Environment=PYTHONDONTWRITEBYTECODE=1
ExecStart=${SOCKPUPPET_DIR}/.venv/bin/python server.py --host 127.0.0.1 --port 3000 --sport 8080
Restart=on-failure
RestartSec=5
SyslogIdentifier=sockpuppet

[Install]
WantedBy=default.target
EOF
  fi
  systemctl enable -q sockpuppet

  if [[ -f "$BROWSERLESS_UNIT" ]]; then
    systemctl disable --now browserless 2>/dev/null || true
  fi

  if ! safe_service_restart sockpuppet || ! wait_http "$SOCKPUPPET_STATS" 30 ||
    ! curl -sS --max-time 5 "$SOCKPUPPET_STATS" | grep -qE '"chrome_version":[[:space:]]*"Google Chrome'; then
    msg_error "Sockpuppet failed to start"
    systemctl status sockpuppet --no-pager -l | head -20 || true
    systemctl disable --now sockpuppet 2>/dev/null || true
    if [[ -f "$BROWSERLESS_UNIT" ]]; then
      systemctl enable --now browserless 2>/dev/null || true
      msg_warn "Restarted Browserless; changedetection was not switched"
    fi
    exit 1
  fi
  msg_ok "Started Sockpuppet"

  local -r STAMP="$(date +%Y%m%d-%H%M%S)"

  if grep -q "browserless\.service" "$CDIO_UNIT"; then
    sed -i."$STAMP" 's/browserless\.service/sockpuppet.service/g' "$CDIO_UNIT"
    $STD systemctl daemon-reload
  fi

  if grep -q '^WEBDRIVER_URL=' "$CDIO_ENV" 2>/dev/null ||
    grep -q '^PLAYWRIGHT_DRIVER_URL=ws://localhost:3000/chrome' "$CDIO_ENV"; then
    sed -i."$STAMP" -e '/^WEBDRIVER_URL=/d' -e '/^PLAYWRIGHT_DRIVER_URL=/d' "$CDIO_ENV"
    echo "PLAYWRIGHT_DRIVER_URL=ws://127.0.0.1:3000/?headful=true&--window-size=1920,1080" >>"$CDIO_ENV"
  fi

  msg_info "Starting Change Detection"
  if ! safe_service_restart changedetection || ! wait_http "$CDIO_URL" 30; then
    msg_error "changedetection failed to start"
    systemctl status changedetection --no-pager -l | head -20 || true
    exit 1
  fi
  msg_ok "Started Change Detection"

  if [[ -f "$BROWSERLESS_UNIT" ]]; then
    msg_info "Removing Browserless"
    systemctl disable --now browserless 2>/dev/null || true
    rm -f "$BROWSERLESS_UNIT"
    rm -rf /opt/browserless
    rm -rf /root/.cache/ms-playwright
    $STD systemctl daemon-reload
    msg_ok "Removed Browserless"
  fi

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
