#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://emby.media/ | Github: https://github.com/MediaBrowser/Emby.Releases

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "emby" "MediaBrowser/Emby.Releases" "binary"

setup_hwaccel "emby"

motd_ssh
customize
cleanup_lxc
