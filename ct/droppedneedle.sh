#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: michelroegl-brunner | Co-Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://droppedneedle.com/ | Github: https://github.com/DroppedNeedle/DroppedNeedle

APP="DroppedNeedle"
var_tags="${var_tags:-arr;media}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-16}"
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

  if [[ ! -d /opt/droppedneedle && ! -d /opt/musicseerr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  MIGRATING=false
  [[ -d /opt/musicseerr ]] && MIGRATING=true

  if [[ "$MIGRATING" == "true" ]] || check_for_gh_release "droppedneedle" "DroppedNeedle/DroppedNeedle"; then
    FROM_V2=false
    [[ "$MIGRATING" == "true" || -d /opt/droppedneedle/venv ]] && FROM_V2=true
    OLD_VERSION="$(cat ~/.droppedneedle 2>/dev/null || true)"

    if [[ "$MIGRATING" == "true" ]]; then
      msg_warn "Migrating Musicseerr to DroppedNeedle"
      msg_info "Stopping Musicseerr Service"
      systemctl disable -q --now musicseerr
      msg_ok "Stopped Musicseerr Service"
    else
      msg_info "Stopping Service"
      systemctl stop droppedneedle
      msg_ok "Stopped Service"
    fi

    msg_info "Installing Dependencies"
    $STD apt install -y build-essential cmake pkg-config ffmpeg python3
    msg_ok "Installed Dependencies"

    RUST_PROFILE="minimal" setup_rust
    NODE_VERSION="22" NODE_MODULE="pnpm@10.33.0" setup_nodejs
    CLEAN_INSTALL=1 CLEAN_INSTALL_KEEP="backend/config backend/cache backend/plugins backend/imports" fetch_and_deploy_gh_release "droppedneedle" "DroppedNeedle/DroppedNeedle" "tarball"

    msg_info "Building Frontend"
    cd /opt/droppedneedle/frontend
    export NODE_OPTIONS="--max-old-space-size=3072"
    $STD pnpm install --frozen-lockfile && DROPPEDNEEDLE_BASE_PATH_PLACEHOLDER=1 $STD pnpm run build || {
      echo "$OLD_VERSION" >~/.droppedneedle
      msg_error "Frontend build failed; the old version stays recorded, run update again"
      exit 1
    }
    rm -rf node_modules
    msg_ok "Built Frontend"

    msg_info "Building DroppedNeedle (Patience)"
    cd /opt/droppedneedle
    $STD cargo build --release --locked --manifest-path server/Cargo.toml --bins -p droppedneedle -p droppedneedle-tool || {
      echo "$OLD_VERSION" >~/.droppedneedle
      msg_error "Build failed; the old version stays recorded, run update again"
      exit 1
    }
    cp server/target/release/droppedneedle server/target/release/droppedneedle-tool /usr/local/bin/
    rm -rf server/target
    msg_ok "Built DroppedNeedle"

    if [[ "$MIGRATING" == "true" ]]; then
      msg_info "Migrating Musicseerr Data"
      rm -rf /opt/droppedneedle/backend/config /opt/droppedneedle/backend/cache
      mkdir -p /opt/droppedneedle/backend
      cp -a /opt/musicseerr/backend/config /opt/droppedneedle/backend/config
      cp -a /opt/musicseerr/backend/cache /opt/droppedneedle/backend/cache
      rm -f /etc/systemd/system/musicseerr.service
      sed -i 's/musicseerr/droppedneedle/g' /bin/update
      rm -rf /opt/musicseerr
      msg_ok "Migrated Musicseerr Data"
    fi
    mkdir -p /opt/droppedneedle/backend/{config,cache,plugins,imports}

    msg_info "Writing systemd Service"
    SLSKD_LINE="$(grep -s '^Environment=SLSKD_DOWNLOADS_PATH=' /etc/systemd/system/droppedneedle.service || echo '# Environment=SLSKD_DOWNLOADS_PATH=<path-to-slskd-downloads>')"
    cat <<EOF >/etc/systemd/system/droppedneedle.service
[Unit]
Description=DroppedNeedle Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/droppedneedle/backend
Environment=ROOT_APP_DIR=/opt/droppedneedle/backend
Environment=DROPPEDNEEDLE_STATIC_DIR=/opt/droppedneedle/frontend/build
Environment=PORT=8688
Environment=COMMIT_TAG=v$(<~/.droppedneedle)
${SLSKD_LINE}
ExecStart=/usr/local/bin/droppedneedle
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable -q droppedneedle
    msg_ok "Wrote systemd Service"

    rm -rf /opt/droppedneedle/venv
    msg_info "Starting Service"
    systemctl start droppedneedle
    msg_ok "Started Service"
    if [[ "$FROM_V2" == "true" ]]; then
      msg_warn "DroppedNeedle 3 needs a one-time upgrade of the v2 data: open http://${LOCAL_IP}:8688 and sign in with a v2 admin."
      msg_warn "Before pressing Upgrade: single sign-on and Spotify callback URLs move from /api/v1 to /api/v3. See docs/upgrading-from-v2.md upstream."
    fi
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
echo -e "${GATEWAY}${BGN}http://${IP}:8688${CL}"
