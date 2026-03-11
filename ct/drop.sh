#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
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

  if [[ ! -d /opt/drop/.git ]]; then
    msg_error "No ${APP} Git Repository Found! Cannot update."
    exit
  fi

  msg_info "Checking for Updates"
  cd /opt/drop || exit
  CURRENT_COMMIT=$(git rev-parse HEAD)
  $STD git fetch origin develop
  LATEST_COMMIT=$(git rev-parse origin/develop)

  if [[ "$CURRENT_COMMIT" == "$LATEST_COMMIT" ]]; then
    msg_ok "No update required. Already at latest version."
    exit
  fi

  msg_info "Stopping Services"
  systemctl stop drop
  msg_ok "Stopped Services"

  msg_info "Backing up Configuration"
  cp /opt/drop/.env /opt/drop_env_backup 2>/dev/null || true
  msg_ok "Backed up Configuration"

  msg_info "Updating Drop"
  cd /opt/drop || exit
  $STD git reset --hard origin/develop
  $STD git submodule update --init --recursive
  msg_ok "Updated Drop"

  msg_info "Installing Dependencies"
  cd /opt/drop || exit
  export PNPM_HOME="/root/.local/share/pnpm"
  export PATH="/root/.cargo/bin:$PNPM_HOME:$PATH"
  $STD pnpm install
  msg_ok "Installed Dependencies"

  msg_info "Building Application"
  cd /opt/drop || exit
  $STD pnpm run build
  msg_ok "Built Application"

  msg_info "Building Torrential"
  cd /opt/drop/torrential || exit
  export PATH="/root/.cargo/bin:$PATH"
  $STD cargo build --release
  msg_ok "Built Torrential"

  msg_info "Running Database Migrations"
  cd /opt/drop || exit
  $STD pnpm add prisma@7.3.0 dotenv
  source /opt/drop/.env
  $STD pnpm exec prisma migrate deploy
  msg_ok "Ran Database Migrations"

  msg_info "Restoring Configuration"
  cp /opt/drop_env_backup /opt/drop/.env 2>/dev/null || true
  rm -f /opt/drop_env_backup
  msg_ok "Restored Configuration"

  msg_info "Starting Services"
  systemctl start drop
  msg_ok "Started Services"
  msg_ok "Updated successfully!"

  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"

msg_info "Waiting for setup URL to be available"
sleep 5
SETUP_URL=$(pct exec "$CTID" -- journalctl -u drop -b0 --no-pager 2>/dev/null | grep -oP 'Open \Khttps?://[^\s]+' | tail -n1 || true)
if [[ -n "$SETUP_URL" ]]; then
  msg_ok "Setup URL retrieved"
  echo -e "${INFO}${YW} Setup URL:${CL}"
  echo -e "${TAB}${GATEWAY}${BGN}${SETUP_URL}${CL}"
else
  echo -e "${INFO}${YW} To retrieve the setup URL run in LXC:${CL}"
  echo -e "${TAB}pct exec ""$CTID"" -- journalctl -u drop -b0 --no-pager | grep -oP 'Open \Khttps?://[^\s]+'${CL}"
fi
