#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Dictionarry-Hub/profilarr

APP="Profilarr"
var_tags="${var_tags:-arr;radarr;sonarr;config}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/profilarr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [[ -d /opt/profilarr/backend ]]; then
    msg_error "Profilarr v1 detected!"
    echo -e "\nProfilarr v2 is a complete rewrite and is NOT compatible with v1."
    echo -e "There is no migration path. Please create a new LXC container for v2.\n"
    exit
  fi

  if check_for_gh_release "profilarr" "Dictionarry-Hub/profilarr"; then
    msg_info "Stopping Service"
    systemctl stop profilarr
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "profilarr" "Dictionarry-Hub/profilarr" "tarball"
    PROFILARR_VERSION=$(curl -fsSL "https://api.github.com/repos/Dictionarry-Hub/profilarr/releases/latest" | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')

    msg_info "Building Profilarr v${PROFILARR_VERSION} (Patience)"
    cd /opt/profilarr
    ARCH=$(uname -m)
    cat >src/lib/shared/build.ts <<EOF
// Generated at update time. Do not hand-edit.
export type Channel = 'stable' | 'develop' | 'dev';

export interface BuildInfo {
	readonly version: string;
	readonly channel: Channel;
	readonly commit: string | null;
	readonly builtAt: string | null;
}

export const build: BuildInfo = {
	version: '${PROFILARR_VERSION}',
	channel: 'stable',
	commit: null,
	builtAt: '$(date -u +"%Y-%m-%dT%H:%M:%SZ")'
};
EOF
    $STD deno install --node-modules-dir
    export APP_BASE_PATH=/opt/profilarr/dist/build
    export VITE_CHANNEL=stable
    $STD deno run -A npm:vite build
    case "$ARCH" in
    aarch64) DENO_TARGET="aarch64-unknown-linux-gnu" ;;
    *) DENO_TARGET="x86_64-unknown-linux-gnu" ;;
    esac
    $STD deno compile \
      --no-check \
      --allow-net \
      --allow-read \
      --allow-write \
      --allow-env \
      --allow-ffi \
      --allow-run \
      --allow-sys \
      --target "$DENO_TARGET" \
      --output dist/build/profilarr \
      dist/build/mod.ts
    msg_ok "Built Profilarr"

    msg_info "Updating Profilarr"
    cp dist/build/profilarr /opt/profilarr/app/profilarr
    cp dist/build/server.js /opt/profilarr/app/server.js
    cp -r dist/build/static /opt/profilarr/app/static
    chmod +x /opt/profilarr/app/profilarr
    msg_ok "Updated Profilarr"

    msg_info "Starting Service"
    systemctl start profilarr
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6868${CL}"
