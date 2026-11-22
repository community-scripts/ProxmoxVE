#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/perminder-klair/subwave

APP="Subwave"
var_tags="${var_tags:-radio;music;ai}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

export var_admin_user="${var_admin_user:-}"
export var_admin_pass="${var_admin_pass:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/subwave ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "subwave" "perminder-klair/subwave"; then
    msg_info "Stopping Subwave"
    systemctl stop subwave-web subwave-controller subwave-broadcast
    msg_ok "Stopped Subwave"

    NODE_VERSION="24" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "subwave" "perminder-klair/subwave" "tarball"
    fetch_and_deploy_gh_release "liquidsoap" "savonet/liquidsoap" "binary" "$(grep -oP 'savonet/liquidsoap:\Kv[0-9.]+' /opt/subwave/docker/Dockerfile.broadcast)" "" "liquidsoap_*-debian-trixie-ocaml4.14.2-*_$(arch_resolve).deb"

    msg_info "Updating Analyzer and Kokoro"
    $STD uv pip install --python /opt/analyzer/venv/bin/python librosa==0.11.0 soundfile==0.14.0 pyloudnorm==0.2.0
    $STD uv pip install --python /opt/kokoro/venv/bin/python kokoro-onnx==0.5.0 soundfile==0.12.1 misaki==0.9.4 pyopenjtalk-plus==0.4.1.post10 cn2an==0.5.24 jieba==0.42.1 ordered-set==4.1.0 pypinyin==0.55.0 pypinyin-dict==0.9.0
    msg_ok "Updated Analyzer and Kokoro"

    msg_info "Building Subwave"
    cd /opt/subwave/controller
    $STD npm ci --omit=dev
    cd /opt/subwave/web
    $STD npm ci
    NEXT_TELEMETRY_DISABLED=1 $STD npm run build
    cp -r public content .next/standalone/
    cp -r .next/static .next/standalone/.next/
    rm -rf node_modules .next/cache ~/.npm
    cp /opt/subwave/docker/icecast.xml.template /etc/icecast2/icecast.xml.template
    cp /opt/subwave/liquidsoap/radio.liq /etc/liquidsoap/radio.liq
    sed -i 's/^settings.server.telnet.bind_addr := .*/settings.server.telnet.bind_addr := "127.0.0.1"/' /etc/liquidsoap/radio.liq
    cp /opt/subwave/docker/aio/Caddyfile /etc/caddy/Caddyfile
    msg_ok "Built Subwave"

    msg_info "Starting Subwave"
    systemctl reload caddy
    systemctl start subwave-broadcast subwave-controller subwave-web
    msg_ok "Started Subwave"
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
echo -e "${GATEWAY}${BGN}http://${IP}/onboarding${CL}"
echo -e "${INFO}${YW}Admin credentials: ~/subwave.creds (inside the container)${CL}"
