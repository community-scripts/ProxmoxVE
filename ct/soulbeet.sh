#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/terry90/soulbeet

APP="Soulbeet"
var_tags="${var_tags:-music;downloader;soulseek}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-3072}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-yes}" # built from source, dx and every toolchain ship arm64, but not yet run on arm64
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/soulbeet ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "soulbeet" "terry90/soulbeet"; then
    msg_info "Stopping Soulbeet"
    systemctl stop soulbeet
    msg_ok "Stopped Soulbeet"

    NODE_VERSION="22" setup_nodejs
    RUST_PROFILE="minimal" setup_rust
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "soulbeet" "terry90/soulbeet" "tarball"
    fetch_and_deploy_gh_release "dioxus-cli" "DioxusLabs/dioxus" "prebuild" "v$(awk -F'"' '/^name = "dioxus"$/{getline; print $2}' /opt/soulbeet/Cargo.lock)" "/usr/local/bin" "dx-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.tar.gz"

    msg_info "Updating beets"
    UV_TOOL_BIN_DIR=/usr/local/bin $STD uv tool install --force --python 3.11 --constraints /opt/soulbeet/build/requirements-beets.txt beets --with requests --with musicbrainzngs
    msg_ok "Updated beets"

    msg_info "Building Soulbeet (Patience)"
    cd /opt/soulbeet
    rm -f package-lock.json
    $STD npm install
    $STD npx @tailwindcss/cli -i ./web/assets/input.css -o ./web/assets/tailwind.css
    RUSTUP_AUTO_INSTALL=0 $STD dx bundle --package web --release
    mv /opt/soulbeet/target/dx/web/release/web /opt/soulbeet/server
    rm -rf /opt/soulbeet/target /opt/soulbeet/node_modules ~/.cargo/registry ~/.cargo/git ~/.npm
    msg_ok "Built Soulbeet"

    msg_info "Starting Soulbeet"
    systemctl start soulbeet
    msg_ok "Started Soulbeet"
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
echo -e "${GATEWAY}${BGN}http://${IP}:9765${CL}"
