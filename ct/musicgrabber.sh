#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gitlab.com/g33kphr33k/musicgrabber

APP="MusicGrabber"
var_tags="${var_tags:-music;downloader;media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; arm64 uses Debian Chromium instead of Google Chrome, not run yet
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/musicgrabber ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(get_latest_gl_tag "g33kphr33k/musicgrabber" "v*")
  if [[ "$RELEASE" == "$(cat ~/.musicgrabber 2>/dev/null)" ]]; then
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
    exit
  fi

  msg_info "Stopping MusicGrabber"
  systemctl stop musicgrabber
  msg_ok "Stopped MusicGrabber"

  fetch_and_deploy_gh_release "yt-dlp" "yt-dlp/yt-dlp" "singlefile" "latest" "/usr/local/bin" "yt-dlp_$(arch_resolve "linux" "linux_aarch64")"
  fetch_and_deploy_gh_release "deno" "denoland/deno" "prebuild" "latest" "/usr/local/bin" "deno-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.zip"
  CLEAN_INSTALL=1 CLEAN_INSTALL_KEEP=".venv" fetch_and_deploy_gl_tag "musicgrabber" "g33kphr33k/musicgrabber" "$RELEASE"

  msg_info "Updating MusicGrabber"
  cd /opt/musicgrabber
  $STD uv pip install --python .venv/bin/python \
    "fastapi~=0.162.0" \
    "uvicorn[standard]~=0.54.0" \
    "httpx~=0.28.1" \
    "pydantic~=2.14.1" \
    "mutagen~=1.48.1" \
    "playwright~=1.64.1" \
    "apprise>=1.13.1,<2" \
    "bcrypt~=4.3.0" \
    "pycryptodome~=4.2.0" \
    "certifi>=2026.10.18" \
    "seleniumbase>=4.54,<5"
  PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright $STD .venv/bin/playwright install chromium
  msg_ok "Updated MusicGrabber"

  CLEAN_INSTALL=1 fetch_and_deploy_from_url "https://codeload.github.com/FraysKosher/flac-verifier/tar.gz/$(grep -oP 'FraysKosher/flac-verifier/tar.gz/\K[0-9a-f]+' /opt/musicgrabber/Dockerfile)" "/opt/flac-verifier/engine"

  msg_info "Starting MusicGrabber"
  systemctl start musicgrabber
  msg_ok "Started MusicGrabber"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
