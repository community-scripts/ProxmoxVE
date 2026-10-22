#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/cryptpad/cryptpad

APP="CryptPad"
var_tags="${var_tags:-docs;office}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d "/opt/cryptpad" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  # Updates to 2026.10.0 finished without infra.js; run them again so it gets written
  [[ -f /opt/cryptpad/config/infra.example.js && ! -f /opt/cryptpad/config/infra.js ]] && rm -f ~/.cryptpad
  if check_for_gh_release "cryptpad" "cryptpad/cryptpad"; then
    msg_info "Stopping Service"
    systemctl stop cryptpad
    msg_ok "Stopped Service"

    create_backup /opt/cryptpad/config/config.js /opt/cryptpad/config/infra.js /opt/cryptpad/www/common/onlyoffice/dist

    CLEAN_INSTALL=1 CLEAN_INSTALL_KEEP="blob block customize data datastore onlyoffice-conf" fetch_and_deploy_gh_release "cryptpad" "cryptpad/cryptpad" "tarball"

    restore_backup

    msg_info "Updating CryptPad"
    cd /opt/cryptpad
    $STD npm ci --allow-git=all
    $STD npm run install:components
    if [[ -d /opt/cryptpad/www/common/onlyoffice/dist ]]; then
      $STD bash /opt/cryptpad/install-office.sh --accept-license
    fi
    if [[ ! -f /opt/cryptpad/config/infra.js ]]; then
      # 2026.10.0 reads the network settings from infra.js and no longer derives the sandbox origin
      LOCAL_IP="$LOCAL_IP" node - <<'EOF'
const c = require("/opt/cryptpad/config/config.js");
const i = require("/opt/cryptpad/config/infra.example.js");
const port = c.httpPort || i.public.httpPort;
const safePort = c.httpSafePort || port + 1;
const origin = (c.httpUnsafeOrigin || `http://${process.env.LOCAL_IP}:${port}`).replace(/\/+$/, "");
const sandbox = new URL(origin);
sandbox.port = safePort;
Object.assign(i.public, {
  origin,
  sandboxOrigin: (c.httpSafeOrigin || sandbox.origin).replace(/\/+$/, ""),
  httpHost: c.httpAddress || (c.httpUnsafeOrigin ? i.public.httpHost : "0.0.0.0"),
  httpPort: port,
  httpSafePort: safePort,
  externalWebsocketURL: c.externalWebsocketURL,
  fileHost: c.fileHost,
});
require("fs").writeFileSync("/opt/cryptpad/config/infra.js", "module.exports = " + JSON.stringify(i, null, 4) + ";\n");
EOF
    fi
    $STD npm run build
    msg_ok "Updated CryptaPad"

    msg_info "Starting Service"
    systemctl start cryptpad
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
