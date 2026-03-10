#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-unscripted/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: BillyOutlast
# License: MIT | https://github.com/community-unscripted/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Drop-OSS/drop | Docs: https://docs-next.droposs.org/

APP="Drop"
var_tags="${var_tags:-gaming;media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-12}"
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

  if [[ ! -d /opt/drop ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "drop" "Drop-OSS/drop"; then
    msg_info "Stopping Services"
    systemctl stop drop
    systemctl stop nginx
    msg_ok "Stopped Services"

    msg_info "Backing up Configuration"
    cp /opt/drop/.env /opt/drop_env_backup 2>/dev/null || true
    msg_ok "Backed up Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "drop" "Drop-OSS/drop" "tarball" "latest" "/opt/drop"

    msg_info "Initializing Git Repository"
    cd /opt/drop || exit
    $STD git init
    $STD git config user.email "noreply@localhost"
    $STD git config user.name "Build"
    $STD git add -A
    $STD git commit -m "Initial commit"
    msg_ok "Initialized Git Repository"

    msg_info "Installing Dependencies"
    cd /opt/drop || exit
    export PNPM_HOME="/root/.local/share/pnpm"
    export PATH="$PNPM_HOME:$PATH"
    $STD pnpm install --frozen-lockfile
    $STD pnpm prisma generate
    msg_ok "Installed Dependencies"

    msg_info "Running Database Migrations"
    cd /opt/drop || exit
    $STD pnpm prisma migrate deploy
    msg_ok "Ran Database Migrations"

    msg_info "Building Application"
    cd /opt/drop || exit
    $STD pnpm build
    msg_ok "Built Application"

    msg_info "Restoring Configuration"
    cp /opt/drop_env_backup /opt/drop/.env 2>/dev/null || true
    rm -f /opt/drop_env_backup
    msg_ok "Restored Configuration"

    msg_info "Starting Services"
    systemctl start nginx
    systemctl start drop
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
