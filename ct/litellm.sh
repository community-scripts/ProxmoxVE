#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

APP="LiteLLM"

header_info "$APP"
variables
color

msg_error "This script is no longer available in community-scripts."
msg_error "This script was removed and cannot be installed or updated."
msg_info "More info: https://community-scripts.org/scripts/litellm"
exit 1
