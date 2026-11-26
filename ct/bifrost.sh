#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: cheesejaguar
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/maximhq/bifrost

APP="Bifrost"
var_tags="${var_tags:-ai;proxy}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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

  if [[ ! -x /opt/bifrost/bifrost-http || ! -f /opt/bifrost_data/config.json ]]; then
    msg_error "No Bifrost Installation Found!"
    exit 1
  fi

  if check_for_gh_release "bifrost" "maximhq/bifrost" "${var_appversion:-}" "" "transports/v"; then
    # Gateway binaries are published to the upstream CDN, not as GitHub assets.
    BIFROST_URL="https://downloads.getmaxim.ai/bifrost/${CHECK_UPDATE_RELEASE##*/}/linux/$(arch_resolve)"
    msg_info "Downloading Bifrost Gateway"
    mkdir -p /opt/bifrost-update
    chmod 700 /opt/bifrost-update
    curl_with_retry "${BIFROST_URL}/bifrost-http" /opt/bifrost-update/bifrost-http
    curl_with_retry "${BIFROST_URL}/bifrost-http.sha256" /opt/bifrost-update/bifrost-http.sha256
    cd /opt/bifrost-update || exit 1
    $STD sha256sum --check bifrost-http.sha256
    msg_ok "Verified Bifrost Gateway"

    msg_info "Stopping Bifrost"
    systemctl stop bifrost
    msg_ok "Stopped Bifrost"

    BACKUP_DIR="/opt/bifrost-backup-$(date +%Y%m%d-%H%M%S)" create_backup /opt/bifrost_data /opt/bifrost/bifrost-http ~/.bifrost

    msg_info "Installing Bifrost Gateway"
    install -m 755 /opt/bifrost-update/bifrost-http /opt/bifrost/bifrost-http
    cd /opt/bifrost || exit 1
    rm -rf /opt/bifrost-update
    msg_ok "Installed Bifrost Gateway"

    msg_info "Starting Bifrost"
    systemctl start bifrost
    $STD curl --fail --silent --show-error --retry 30 --retry-connrefused --retry-delay 2 --retry-max-time 120 --max-time 5 http://127.0.0.1:8080/health
    systemctl is-active --quiet bifrost
    cat <<EOF >~/.bifrost
${CHECK_UPDATE_RELEASE}
EOF
    msg_ok "Started Bifrost"
    msg_ok "Updated Bifrost successfully!"
  else
    RELEASE_CHECK_STATUS=$?
    if [[ "$RELEASE_CHECK_STATUS" -ne 1 ]]; then
      exit "$RELEASE_CHECK_STATUS"
    fi
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
echo -e "${INFO}${YW}Bifrost username: admin. Find BIFROST_ADMIN_PASSWORD in /opt/bifrost_data/.env inside the container.${CL}"
