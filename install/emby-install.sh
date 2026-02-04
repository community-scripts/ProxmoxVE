#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://emby.media/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_hwaccel

fetch_and_deploy_gh_release "emby" "MediaBrowser/Emby.Releases" "binary"

msg_info "Configuring Emby"
if [[ "$CTTYPE" == "0" ]]; then
  sed -i -e 's/^ssl-cert:x:104:$/render:x:104:root,emby/' -e 's/^render:x:108:root,emby$/ssl-cert:x:108:/' /etc/group
else
  sed -i -e 's/^ssl-cert:x:104:$/render:x:104:emby/' -e 's/^render:x:108:emby$/ssl-cert:x:108:/' /etc/group
fi
msg_ok "Configured Emby"

motd_ssh
customize
cleanup_lxc
