#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Stephen Chin (steveonjava)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/langfuse/langfuse

APP="Langfuse"
var_tags="${var_tags:-ai;monitoring;analytics}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-16384}"
var_disk="${var_disk:-100}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

export var_admin_email="${var_admin_email:-}"
export var_admin_pass="${var_admin_pass:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/langfuse || ! -f /opt/langfuse_data/.env ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "seaweedfs" "seaweedfs/seaweedfs"; then
    msg_info "Stopping SeaweedFS"
    systemctl stop langfuse-storage
    msg_ok "Stopped SeaweedFS"

    fetch_and_deploy_gh_release "seaweedfs" "seaweedfs/seaweedfs" "prebuild" "latest" "/opt/seaweedfs" "linux_$(arch_resolve).tar.gz"

    msg_info "Starting SeaweedFS"
    systemctl start langfuse-storage
    $STD curl --retry 30 --retry-delay 2 --retry-connrefused -fsS http://127.0.0.1:8333/healthz
    msg_ok "Started SeaweedFS"
  fi

  if check_for_gh_release "migrate" "golang-migrate/migrate"; then
    fetch_and_deploy_gh_release "migrate" "golang-migrate/migrate" "binary"
  fi

  if check_for_gh_release "langfuse" "langfuse/langfuse"; then
    msg_warn "Take a container snapshot before updating Langfuse; database migrations cannot be rolled back by this script."
    msg_info "Stopping Langfuse"
    systemctl stop langfuse-web langfuse-worker
    msg_ok "Stopped Langfuse"

    create_backup "$HOME/.langfuse"
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "langfuse" "langfuse/langfuse" "tarball"
    restore_backup
    NODE_VERSION="24" NODE_MODULE="pnpm@$(jq -r '.engines.pnpm' /opt/langfuse/package.json)" setup_nodejs
    RUST_TOOLCHAIN="$(sed -n 's/^channel = "\(.*\)"/\1/p' /opt/langfuse/packages/native/rust-toolchain.toml)" RUST_PROFILE="minimal" setup_rust

    msg_info "Building Langfuse"
    cd /opt/langfuse
    HUSKY=0 $STD pnpm install --frozen-lockfile
    DOCKER_BUILD=1 NEXT_TELEMETRY_DISABLED=1 CI=true pnpm_config_verify_deps_before_run=false $STD pnpm turbo run build --filter=web... --filter=worker... --concurrency=1
    cp -r web/.next/static web/.next/standalone/web/.next/
    cp -r web/public web/.next/standalone/web/
    msg_ok "Built Langfuse"

    msg_info "Starting Langfuse"
    systemctl restart langfuse-migrate
    systemctl start langfuse-web langfuse-worker
    $STD curl --retry 60 --retry-delay 2 --retry-connrefused -fsS http://127.0.0.1:3000/api/public/ready
    $STD curl --retry 30 --retry-delay 2 --retry-connrefused -fsS http://127.0.0.1:3030/api/health
    cat <<EOF >"$HOME/.langfuse"
$(jq -r '.version' /opt/langfuse/package.json)
EOF
    msg_ok "Started Langfuse"
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
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
