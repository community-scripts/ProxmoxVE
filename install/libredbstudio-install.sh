#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Yusuf Gundogdu (yusuf-gundogdu)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://libredb.org

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "libredb-studio" "libredb/libredb-studio" "binary" "latest" "" "libredb-studio_*_$(arch_resolve).deb"

msg_info "Configuring LibreDB Studio"
JWT_SECRET="$(openssl rand -hex 32)"
ADMIN_PASSWORD="$(openssl rand -base64 18 | tr -d '/+=' | cut -c1-16)"
mkdir -p /etc/libredb-studio
cat <<EOF >/etc/libredb-studio/env
HOSTNAME=0.0.0.0
PORT=3000
# Cookie is marked Secure on non-loopback hosts; plain-HTTP LXC login loops without this.
AUTH_COOKIE_SECURE=false
AUTH_BOOTSTRAP=off
JWT_SECRET=${JWT_SECRET}
ADMIN_EMAIL=admin@libredb.org
ADMIN_PASSWORD=${ADMIN_PASSWORD}
EOF
chmod 600 /etc/libredb-studio/env
systemctl enable -q --now libredb-studio
msg_ok "Configured LibreDB Studio"

motd_ssh
customize
cleanup_lxc
