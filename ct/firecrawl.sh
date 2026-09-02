#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: esatbayhan
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.firecrawl.dev/

APP="Firecrawl"
var_tags="${var_tags:-scraping;ai;crawler}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-30}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/firecrawl/apps/api ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  ensure_dependencies build-essential ccache

  if check_for_gh_release "firecrawl" "firecrawl/firecrawl"; then
    msg_info "Stopping Services"
    systemctl stop firecrawl firecrawl-playwright
    msg_ok "Stopped Services"

    create_backup /opt/firecrawl/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "firecrawl" "firecrawl/firecrawl" "tarball" "latest" "/opt/firecrawl"
    GO_VERSION="$(grep -m1 '^go ' /opt/firecrawl/apps/api/sharedLibs/go-html-to-md/go.mod | awk '{print $2}')" setup_go

    restore_backup

    FDB_VERSION="$(awk -F= '/^ARG FDB_VERSION=/{print $2; exit}' /opt/firecrawl/apps/api/Dockerfile)"
    if [[ -z "$FDB_VERSION" ]]; then
      msg_error "FDB_VERSION pin not found in upstream Dockerfile"
      exit 1
    fi
    if [[ "$(dpkg-query -W -f='${Version}' foundationdb-clients 2>/dev/null)" != "${FDB_VERSION}-"* ]]; then
      FDB_ARCH="$(get_system_arch)"
      [[ "$FDB_ARCH" == "arm64" ]] && FDB_ARCH="aarch64"
      fetch_and_deploy_gh_release "foundationdb-clients" "apple/foundationdb" "binary" "$FDB_VERSION" "/opt/foundationdb-clients" "foundationdb-clients_${FDB_VERSION}-1_${FDB_ARCH}.deb"
    fi

    msg_info "Building Go Library"
    cd /opt/firecrawl/apps/api/sharedLibs/go-html-to-md
    $STD go build -o libhtml-to-markdown.so -buildmode=c-shared html-to-markdown.go
    msg_ok "Built Go Library"

    msg_info "Building Firecrawl API"
    source "$HOME/.cargo/env"
    cd /opt/firecrawl/apps/api
    $STD pnpm install --frozen-lockfile
    $STD pnpm build
    CI=true $STD pnpm prune --prod --ignore-scripts
    msg_ok "Built Firecrawl API"

    msg_info "Building Playwright Service"
    cd /opt/firecrawl/apps/playwright-service-ts
    $STD npm install
    $STD npx playwright install chromium --with-deps
    $STD npm run build
    $STD npm prune --omit=dev
    msg_ok "Built Playwright Service"

    msg_info "Starting Services"
    systemctl start firecrawl-playwright firecrawl
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3002${CL}"
