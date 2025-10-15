#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: TheRealVira
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://pf2etools.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  apache2 \
  ca-certificates \
  git
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "pf2etools" "Pf2eToolsOrg/Pf2eTools" "tarball" "latest" "/opt/Pf2eTools"

msg_info "Configuring Pf2eTools"
cd /opt/Pf2eTools
$STD npm install
$STD npm run build
msg_ok "Configured Pf2eTools"

msg_info "Creating Service"
cat <<EOF >>/etc/apache2/apache2.conf
<Location /server-status>
    SetHandler server-status
    Order deny,allow
    Allow from all
</Location>
EOF
rm -rf /var/www/html
ln -s "/opt/Pf2eTools" /var/www/html
chown -R www-data: "/opt/Pf2eTools"
chmod -R 755 "/opt/Pf2eTools"
msg_ok "Created Service"

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"

motd_ssh
customize
