#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.drawio.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os
setup_hwaccel

msg_info "Installing Dependencies"
$STD apt install -y tomcat11
msg_ok "Installed Dependencies"

USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "drawio" "jgraph/drawio" "singlefile" "latest" "/var/lib/tomcat11/webapps" "draw.war"

motd_ssh
customize
cleanup_lxc
