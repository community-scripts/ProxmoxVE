#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

APP="BookLore"

header_info "$APP"
variables
color

msg_error "This script is no longer available in community-scripts."
msg_error "The Booklore or the Grimmory Fork will for now not return to community-scripts. Due to the unstable nature of these projects we decided to remove them and will decide at later point if they come back, which will most likley not happen. Plese do not create Issues for this."
msg_warn "More info: https://community-scripts.org/scripts/booklore"
exit 1
