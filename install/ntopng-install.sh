#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.ntop.org/products/traffic-analysis/ntop/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NTOP_CODENAME="$(get_os_info codename)"
case "$NTOP_CODENAME" in
bookworm | trixie)
  fetch_and_deploy_from_url "https://packages.ntop.org/apt/${NTOP_CODENAME}/all/apt-ntop.deb" ""
  ;;
*)
  fetch_and_deploy_from_url "https://packages.ntop.org/apt-stable/${NTOP_CODENAME}/all/apt-ntop-stable.deb" ""
  ;;
esac

msg_info "Installing ntopng"
$STD apt update
$STD apt install -y ntopng
msg_ok "Installed ntopng"

msg_info "Configuring ntopng"
cat <<EOF >/etc/ntopng/ntopng.conf
-i=$(ip -4 route | awk '/default/ {print $5; exit}')
-w=3000
-d=/var/lib/ntopng
--community
EOF
systemctl restart ntopng
msg_ok "Configured ntopng"

motd_ssh
customize
cleanup_lxc
