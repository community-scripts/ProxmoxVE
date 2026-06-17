#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ui.com/

APP="UniFi-OS-Server"
var_tags="${var_tags:-network}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-0}"
var_tun="${var_tun:-yes}"
var_nesting="${var_nesting:-1}"
var_ns="${var_ns:-1.1.1.1 8.8.8.8}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /usr/local/sbin/unifi-os-server.bin && ! -d /data/unifi ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_custom "🚀" "${GN}" "The app offers a built-in updater. Please use it."
  exit
}

start
build_container

HOOKSCRIPT_PATH="/var/lib/vz/snippets/unifi-os-server-multicast-${CTID}.sh"
cat >"$HOOKSCRIPT_PATH" <<EOF
#!/bin/sh
# Hookscript: enable multicast on the veth interface for UniFi OS Server LXC ${CTID}
# Required so the UniFi discovery client does not crash on startup inside the container.
if [ "\$1" = "${CTID}" ] && [ "\$2" = "post-start" ]; then
  ip link set "veth${CTID}i0" multicast on 2>/dev/null || true
fi
EOF
chmod +x "$HOOKSCRIPT_PATH"
pct set "$CTID" --hookscript "local:snippets/unifi-os-server-multicast-${CTID}.sh"

description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}https://${IP}:11443${CL}"
