#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: rcastley
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.splunk.com/en_us/download.html

APP="Splunk-Enterprise"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-40}"
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
    if [[ ! -d /opt/splunk ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_error "Currently we don't provide an update function for this ${APP}."
    exit
}

start

# The installer runs under lxc-attach, which has no terminal, so the terms
# question has to be answered here on the host.
if [[ "${var_splunk_terms:-}" != "yes" ]]; then
    echo -e "${TAB3}┌─────────────────────────────────────────────────────────────────────────┐"
    echo -e "${TAB3}│                          SPLUNK GENERAL TERMS                           │"
    echo -e "${TAB3}└─────────────────────────────────────────────────────────────────────────┘"
    echo ""
    echo -e "${TAB3}Before proceeding with the Splunk Enterprise installation, you must"
    echo -e "${TAB3}review and accept the Splunk General Terms."
    echo ""
    echo -e "${TAB3}Please review the terms at:"
    echo -e "${TAB3}${GATEWAY}${BGN}https://www.splunk.com/en_us/legal/splunk-general-terms.html${CL}"
    echo ""

    while true; do
        echo -e "${TAB3}Do you accept the Splunk General Terms? (y/N): \c"
        read -r response
        case $response in
        [Yy] | [Yy][Ee][Ss])
            var_splunk_terms="yes"
            msg_ok "Terms accepted. Proceeding with installation..."
            break
            ;;
        [Nn] | [Nn][Oo] | "")
            msg_error "Terms not accepted. Installation cannot proceed."
            msg_error "Please review the terms and run the script again if you wish to proceed."
            exit 254
            ;;
        *)
            msg_error "Invalid response. Please enter 'y' for yes or 'n' for no."
            ;;
        esac
    done
fi
export var_splunk_terms

build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access the Splunk Enterprise Web interface using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
