#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

APP="BookLore"

header_info "$APP"
variables
color

msg_error "This script is no longer available in community-scripts."
msg_error "The Booklore or the Fork Grimmory will for now not return to community-scripts. Due to the unstable nature of this Projects we decided to remove them, and decide on a later Point if they come back. Wich will most likley not happen. Dont create Issues for this."
msg_info "More info: https://community-scripts.org/scripts/booklore"
exit 1
