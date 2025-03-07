#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Auther: tanujdargan
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ThePhaseless/Byparr

APP="Byparr"
var_tags="cloudflare,solver"
var_cpu="2"
var_ram="2048"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/byparr ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating Byparr"
    cd /opt/byparr
    $STD git pull
    $STD uv sync --group test
    systemctl restart byparr.service
    msg_ok "Updated Byparr"
    exit
}

start
build_container
description

# Give container a moment to fully initialize
msg_info "Waiting for container to fully initialize..."
sleep 10

# Download and execute the installation script inside the container
msg_info "Running installation script inside the container"
# Download the installation script to a temporary location in the container
$STD pct exec $CTID -- bash -c "wget -qO /tmp/byparr-install.sh https://raw.githubusercontent.com/tanujdargan/ProxmoxVE/main/install/byparr-install.sh"
# Make it executable
$STD pct exec $CTID -- bash -c "chmod +x /tmp/byparr-install.sh"
# Execute the installation script
if [[ "$VERBOSE" == "true" ]]; then
    $STD pct exec $CTID -- bash -c "FUNCTIONS_FILE_PATH='$(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/install.func)' /tmp/byparr-install.sh --verbose"
else
    $STD pct exec $CTID -- bash -c "FUNCTIONS_FILE_PATH='$(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/install.func)' /tmp/byparr-install.sh"
fi
msg_ok "Installation completed inside the container"

# Ensure network is ready and IP is retrievable (add retry mechanism)
msg_info "Retrieving container IP address"
MAX_ATTEMPTS=5
ATTEMPT=1
IP=""

while [[ -z "$IP" && $ATTEMPT -le $MAX_ATTEMPTS ]]; do
    IP=$(pct exec "$CTID" -- ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    if [[ -z "$IP" ]]; then
        echo "Attempt $ATTEMPT: IP not found, waiting 5 seconds..."
        sleep 5
        ATTEMPT=$((ATTEMPT + 1))
    fi
done

if [[ -z "$IP" ]]; then
    msg_error "Failed to retrieve container IP address after $MAX_ATTEMPTS attempts."
    echo -e "${INFO}${YW} You'll need to manually check the IP address of container $CTID${CL}"
    IP="YOUR-CONTAINER-IP"
else
    msg_ok "Retrieved container IP: $IP"
fi

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8191${CL}"