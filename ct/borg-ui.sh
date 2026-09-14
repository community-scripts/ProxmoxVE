#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/karanhudia/borg-ui

APP="Borg-UI"
var_tags="${var_tags:-backup}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/borg-ui ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "borg-ui" "karanhudia/borg-ui"; then
    msg_info "Stopping Service"
    systemctl stop borg-ui
    msg_ok "Stopped Service"

    create_backup /opt/borg-ui/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "borg-ui" "karanhudia/borg-ui" "tarball"

    restore_backup

    BORG_UI_VERSION=$(cat "$HOME/.borg-ui" 2>/dev/null)
    if [[ -n "$BORG_UI_VERSION" ]]; then
      if grep -q '^APP_VERSION=' /opt/borg-ui/.env; then
        sed -i "s|^APP_VERSION=.*|APP_VERSION=${BORG_UI_VERSION}|" /opt/borg-ui/.env
      else
        echo "APP_VERSION=${BORG_UI_VERSION}" >>/opt/borg-ui/.env
      fi
    fi

    # Only the three Borg pins appear in every release of this file; PYTHON_VERSION
    # and RCLONE_VERSION were added upstream after v2.2.6, so both fall back.
    RUNTIME_ENV="/opt/borg-ui/docker/runtime-base.env"
    BORG1_VERSION=$(sed -n 's/^BORG1_VERSION=//p' "$RUNTIME_ENV" 2>/dev/null | tr -d ' \r')
    BORG2_VERSION=$(sed -n 's/^BORG2_VERSION=//p' "$RUNTIME_ENV" 2>/dev/null | tr -d ' \r')
    BORGSTORE_VERSION=$(sed -n 's/^BORGSTORE_VERSION=//p' "$RUNTIME_ENV" 2>/dev/null | tr -d ' \r')
    RCLONE_VERSION=$(sed -n 's/^RCLONE_VERSION=//p' "$RUNTIME_ENV" 2>/dev/null | tr -d ' \r')
    BORG_PYTHON=$(sed -n 's/^PYTHON_VERSION=//p' "$RUNTIME_ENV" 2>/dev/null | tr -d ' \r')
    BORG_PYTHON="${BORG_PYTHON:-3.12}"
    if [[ -z "$BORG1_VERSION" || -z "$BORG2_VERSION" || -z "$BORGSTORE_VERSION" ]]; then
      msg_error "Could not read the pinned Borg versions from ${RUNTIME_ENV}"
      exit 1
    fi

    if [[ "$(cat /opt/borg1-venv/.pinned_version 2>/dev/null)" != "$BORG1_VERSION" ]]; then
      msg_info "Installing Borg ${BORG1_VERSION} (Patience)"
      $STD uv venv --python "$BORG_PYTHON" /opt/borg1-venv
      $STD uv pip install --python /opt/borg1-venv pyfuse3 "borgbackup==${BORG1_VERSION}"
      echo "$BORG1_VERSION" >/opt/borg1-venv/.pinned_version
      ln -sf /opt/borg1-venv/bin/borg /usr/local/bin/borg
      msg_ok "Installed Borg ${BORG1_VERSION}"
    fi

    if [[ "$(cat /opt/borg2-venv/.pinned_version 2>/dev/null)" != "${BORG2_VERSION}-${BORGSTORE_VERSION}" ]]; then
      msg_info "Installing Borg ${BORG2_VERSION} (Patience)"
      $STD uv venv --python "$BORG_PYTHON" /opt/borg2-venv
      $STD uv pip install --python /opt/borg2-venv pyfuse3 "borgbackup==${BORG2_VERSION}" "borgstore[rclone,sftp,rest,s3,blake3]==${BORGSTORE_VERSION}"
      echo "${BORG2_VERSION}-${BORGSTORE_VERSION}" >/opt/borg2-venv/.pinned_version
      ln -sf /opt/borg2-venv/bin/borg /usr/local/bin/borg2
      msg_ok "Installed Borg ${BORG2_VERSION}"
    fi

    RCLONE_TAG="${RCLONE_VERSION:+v${RCLONE_VERSION}}"
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "rclone" "rclone/rclone" "prebuild" "${RCLONE_TAG:-latest}" "/opt/rclone" "rclone-${RCLONE_TAG:-*}-linux-$(arch_resolve amd64 arm64).zip"
    ln -sf /opt/rclone/rclone /usr/local/bin/rclone

    msg_info "Building Frontend"
    cd /opt/borg-ui/frontend
    $STD npm ci
    $STD npm run build
    rm -rf /opt/borg-ui/app/static
    mkdir -p /opt/borg-ui/app/static
    cp -r /opt/borg-ui/frontend/build/* /opt/borg-ui/app/static/
    msg_ok "Built Frontend"

    msg_info "Updating Python Environment"
    cd /opt/borg-ui
    $STD uv venv --python "$BORG_PYTHON" /opt/borg-ui/.venv
    $STD uv pip install --python /opt/borg-ui/.venv -r requirements.txt
    msg_ok "Updated Python Environment"

    msg_info "Starting Service"
    systemctl start borg-ui
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8081${CL}"
