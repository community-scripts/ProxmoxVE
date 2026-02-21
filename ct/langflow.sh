#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Yamon
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.langflow.org/

APP="Langflow"
var_tags="${var_tags:-ai;interface}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-12288}"
var_disk="${var_disk:-16}"
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

  if [[ ! -d /opt/langflow || ! -f /etc/systemd/system/langflow.service || ! -x /opt/langflow/.venv/bin/python ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  local TS BACKUP_DIR OLD_VERSION TARGET_VERSION
  TS="$(date +%Y%m%d-%H%M%S)"
  BACKUP_DIR="/opt/langflow/backups/${TS}"
  TARGET_VERSION="${LANGFLOW_TARGET_VERSION:-latest}"
  OLD_VERSION="$([ -x /opt/langflow/.venv/bin/python ] && /opt/langflow/.venv/bin/python -m pip show langflow 2>/dev/null | awk '/^Version:/ {print $2}')"
  LATEST_VERSION="$(get_latest_github_release "langflow-ai/langflow" 2>/dev/null || echo "unknown")"

  msg_info "Installed Version: ${OLD_VERSION:-unknown} | Latest Upstream: ${LATEST_VERSION}"

  msg_info "Preparing Backup"
  mkdir -p "${BACKUP_DIR}"
  cp -a /opt/langflow/.env "${BACKUP_DIR}/.env" 2>/dev/null || true
  cp -a /opt/langflow/data/langflow.db* "${BACKUP_DIR}/" 2>/dev/null || true
  msg_ok "Backup saved to ${BACKUP_DIR}"

  msg_info "Stopping Service"
  systemctl stop langflow
  msg_ok "Stopped Service"

  PYTHON_VERSION="3.12" setup_uv
  UV_CONCURRENT_DOWNLOADS="${UV_CONCURRENT_DOWNLOADS:-2}"
  UV_CONCURRENT_BUILDS="${UV_CONCURRENT_BUILDS:-1}"
  UV_CONCURRENT_INSTALLS="${UV_CONCURRENT_INSTALLS:-1}"
  LANGFLOW_NO_CACHE="${LANGFLOW_NO_CACHE:-false}"
  UV_CACHE_ARGS=()
  if [[ "${LANGFLOW_NO_CACHE,,}" == "true" || "${LANGFLOW_NO_CACHE}" == "1" ]]; then
    UV_CACHE_ARGS+=(--no-cache)
  fi

  msg_info "Pinning CPU Torch"
  if ! $STD env \
    UV_CONCURRENT_DOWNLOADS="${UV_CONCURRENT_DOWNLOADS}" \
    UV_CONCURRENT_BUILDS="${UV_CONCURRENT_BUILDS}" \
    UV_CONCURRENT_INSTALLS="${UV_CONCURRENT_INSTALLS}" \
    uv pip install --python /opt/langflow/.venv/bin/python "${UV_CACHE_ARGS[@]}" \
    --index-strategy unsafe-best-match \
    --index-url https://download.pytorch.org/whl/cpu \
    --extra-index-url https://pypi.org/simple \
    "torch==2.8.0+cpu"; then
    msg_error "Failed to install CPU torch"
    exit 1
  fi
  msg_ok "Pinned CPU Torch"

  msg_info "Updating Langflow (${TARGET_VERSION})"
  if [[ "${TARGET_VERSION}" == "latest" ]]; then
    if ! $STD env \
      UV_CONCURRENT_DOWNLOADS="${UV_CONCURRENT_DOWNLOADS}" \
      UV_CONCURRENT_BUILDS="${UV_CONCURRENT_BUILDS}" \
      UV_CONCURRENT_INSTALLS="${UV_CONCURRENT_INSTALLS}" \
      uv pip install --python /opt/langflow/.venv/bin/python "${UV_CACHE_ARGS[@]}" --upgrade langflow; then
      msg_error "Langflow update failed"
      if [[ -n "${OLD_VERSION}" ]]; then
        msg_info "Rolling back to ${OLD_VERSION}"
        $STD env \
          UV_CONCURRENT_DOWNLOADS="${UV_CONCURRENT_DOWNLOADS}" \
          UV_CONCURRENT_BUILDS="${UV_CONCURRENT_BUILDS}" \
          UV_CONCURRENT_INSTALLS="${UV_CONCURRENT_INSTALLS}" \
          uv pip install --python /opt/langflow/.venv/bin/python "${UV_CACHE_ARGS[@]}" "langflow==${OLD_VERSION}" || true
      fi
      cp -a "${BACKUP_DIR}/.env" /opt/langflow/.env 2>/dev/null || true
      cp -a "${BACKUP_DIR}/langflow.db"* /opt/langflow/data/ 2>/dev/null || true
      systemctl start langflow || true
      exit 1
    fi
  else
    if ! $STD env \
      UV_CONCURRENT_DOWNLOADS="${UV_CONCURRENT_DOWNLOADS}" \
      UV_CONCURRENT_BUILDS="${UV_CONCURRENT_BUILDS}" \
      UV_CONCURRENT_INSTALLS="${UV_CONCURRENT_INSTALLS}" \
      uv pip install --python /opt/langflow/.venv/bin/python "${UV_CACHE_ARGS[@]}" "langflow==${TARGET_VERSION}"; then
      msg_error "Langflow update to ${TARGET_VERSION} failed"
      if [[ -n "${OLD_VERSION}" ]]; then
        msg_info "Rolling back to ${OLD_VERSION}"
        $STD env \
          UV_CONCURRENT_DOWNLOADS="${UV_CONCURRENT_DOWNLOADS}" \
          UV_CONCURRENT_BUILDS="${UV_CONCURRENT_BUILDS}" \
          UV_CONCURRENT_INSTALLS="${UV_CONCURRENT_INSTALLS}" \
          uv pip install --python /opt/langflow/.venv/bin/python "${UV_CACHE_ARGS[@]}" "langflow==${OLD_VERSION}" || true
      fi
      cp -a "${BACKUP_DIR}/.env" /opt/langflow/.env 2>/dev/null || true
      cp -a "${BACKUP_DIR}/langflow.db"* /opt/langflow/data/ 2>/dev/null || true
      systemctl start langflow || true
      exit 1
    fi
  fi
  msg_ok "Updated Langflow"

  msg_info "Starting Service"
  systemctl start langflow

  if [[ "$(systemctl is-active langflow)" != "active" ]]; then
    msg_error "Service failed to start"
    if [[ -n "${OLD_VERSION}" ]]; then
      msg_info "Rolling back to ${OLD_VERSION}"
      $STD env \
        UV_CONCURRENT_DOWNLOADS="${UV_CONCURRENT_DOWNLOADS}" \
        UV_CONCURRENT_BUILDS="${UV_CONCURRENT_BUILDS}" \
        UV_CONCURRENT_INSTALLS="${UV_CONCURRENT_INSTALLS}" \
        uv pip install --python /opt/langflow/.venv/bin/python "${UV_CACHE_ARGS[@]}" "langflow==${OLD_VERSION}" || true
      cp -a "${BACKUP_DIR}/.env" /opt/langflow/.env 2>/dev/null || true
      cp -a "${BACKUP_DIR}/langflow.db"* /opt/langflow/data/ 2>/dev/null || true
      systemctl restart langflow || true
    fi
    exit 1
  fi

  msg_info "Running Health Check"
  ensure_dependencies curl || true
  if command -v curl >/dev/null 2>&1; then
    for _ in {1..30}; do
      if curl -fsS http://127.0.0.1:7860/ >/dev/null 2>&1; then
        break
      fi
      sleep 2
    done
    if ! curl -fsS http://127.0.0.1:7860/ >/dev/null 2>&1; then
      msg_error "Health check failed. Check logs: journalctl -u langflow -n 100"
      exit 1
    fi
  else
    msg_info "curl not available, skipping HTTP health check"
  fi
  msg_ok "Health check passed"
  msg_info "If migration errors occur, review Langflow docs before using 'langflow migration --fix'"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7860${CL}"
