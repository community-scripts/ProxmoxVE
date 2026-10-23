#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gitlab.com/storyteller-platform/storyteller

APP="Storyteller"
var_tags="${var_tags:-media;ebook;audiobook}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-10240}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /opt/storyteller ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" NODE_MODULE="corepack" setup_nodejs

  if check_for_gl_release "storyteller" "storyteller-platform/storyteller" "" "" "web-v2"; then
    msg_info "Stopping Service"
    systemctl stop storyteller
    msg_ok "Stopped Service"

    ensure_dependencies cmake argon2 libcurl4t64 libxml2

    fetch_and_deploy_gh_release "readium" "readium/cli" "prebuild" "v0.9.1" "/opt/readium" "readium_linux_$(arch_resolve "x86_64" "arm64").tar.gz"

    create_backup /opt/storyteller/.env
    CLEAN_INSTALL=1 CLEAN_INSTALL_KEEP="data" fetch_and_deploy_gl_release "storyteller" "storyteller-platform/storyteller" "tarball" "latest" "/opt/storyteller" "" "web-v2"
    restore_backup

    msg_info "Building Storyteller (Patience)"
    cd /opt/storyteller
    $STD corepack yarn install
    export NODE_ENV=production
    export NEXT_TELEMETRY_DISABLED=1
    export SQLITE_NATIVE_BINDING=/opt/storyteller/node_modules/better-sqlite3/build/Release/better_sqlite3.node
    $STD corepack yarn workspaces foreach -Rpt --from @storyteller-platform/web --exclude @storyteller-platform/eslint run build
    STANDALONE=/opt/storyteller/applications/web/.next/standalone
    WEB_DIR="$STANDALONE/applications/web"
    mkdir -p "$WEB_DIR"/{public,.next/static,.next/cache,migrations,sqlite,scripts}
    cp -rT applications/web/public "$WEB_DIR/public"
    cp -rT applications/web/.next/static "$WEB_DIR/.next/static"
    cp -rT applications/web/migrations "$WEB_DIR/migrations"
    cp applications/web/sqlite/uuid.c.so "$WEB_DIR/sqlite/"
    cp docker-scripts/reset-password.sh "$WEB_DIR/scripts/"
    cp -r applications/web/work-dist applications/web/file-write-dist "$WEB_DIR/"
    mkdir -p "$WEB_DIR/work-dist/@storyteller-platform/align/prebuilds"
    cp -r "libraries/align/prebuilds/linux-$(arch_resolve "x64" "arm64")" "$WEB_DIR/work-dist/@storyteller-platform/align/prebuilds/"
    cp node_modules/@echogarden/icu-segmentation-wasm/wasm/*.wasm "$WEB_DIR/work-dist/"
    cp -rT node_modules/@parcel "$STANDALONE/node_modules/@parcel"
    cp -rT node_modules/kuromoji "$STANDALONE/node_modules/kuromoji"
    ln -sf /opt/storyteller/.env "$WEB_DIR/.env"
    msg_ok "Built Storyteller"

    msg_info "Updating Whisper"
    WHISPER_VARIANT="linux-$(arch_resolve "x64" "arm64")-cpu"
    $STD node /opt/storyteller/libraries/ghost-story/dist/cli/bin.js install binary "$WHISPER_VARIANT"
    $STD node /opt/storyteller/libraries/ghost-story/dist/cli/bin.js install model tiny.en
    if [[ "$WHISPER_VARIANT" == "linux-x64-cpu" ]]; then
      $STD node /opt/storyteller/libraries/ghost-story/dist/cli/bin.js install binary linux-x64-cpu-legacy
    fi
    msg_ok "Updated Whisper"

    cat <<EOF >/etc/systemd/system/storyteller.service
[Unit]
Description=Storyteller
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${WEB_DIR}
EnvironmentFile=/opt/storyteller/.env
Environment=SQLITE_NATIVE_BINDING=${STANDALONE}/node_modules/better-sqlite3/build/Release/better_sqlite3.node
Environment=ERROR_ALIGN_NATIVE_BINDING=${WEB_DIR}/work-dist/@storyteller-platform/align/
Environment=STORYTELLER_WORKER=worker.mjs
Environment=STORYTELLER_FILE_WRITE_WORKER=fileWriteWorker.mjs
ExecStart=/usr/bin/node --enable-source-maps server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload

    msg_info "Starting Service"
    systemctl start storyteller
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
echo -e "${GATEWAY}${BGN}http://${IP}:8001${CL}"
