#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: ethan-hgwr
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/gchq/CyberChef

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y caddy
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs
fetch_and_deploy_gh_release "cyberchef" "gchq/CyberChef" "tarball"

msg_info "Building CyberChef (Patience)"
cd /opt/cyberchef
$STD npm ci --ignore-scripts
$STD npm run postinstall
$STD npm run build
msg_ok "Built CyberChef"

msg_info "Configuring Caddy"
cat <<EOF >/etc/caddy/Caddyfile
:80 {
    root * /opt/cyberchef/build/prod
    file_server
}
EOF
systemctl enable -q --now caddy
systemctl reload caddy
msg_ok "Configured Caddy"

motd_ssh
customize
cleanup_lxc
