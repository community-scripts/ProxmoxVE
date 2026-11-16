#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Nicolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tvheadend.org/ | Github: https://github.com/tvheadend/tvheadend

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb822_repo \
  "tvheadend" \
  "https://dl.cloudsmith.io/public/tvheadend/tvheadend/gpg.C6CC06BD69B430C6.key" \
  "https://dl.cloudsmith.io/public/tvheadend/tvheadend/deb/debian" \
  "$(get_os_info codename)" \
  "main"

var_admin_user="${var_admin_user:-admin}"
var_admin_pass="${var_admin_pass:-$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)}"

msg_info "Installing Tvheadend"
echo "tvheadend tvheadend/admin_username string ${var_admin_user}" | debconf-set-selections
echo "tvheadend tvheadend/admin_password password ${var_admin_pass}" | debconf-set-selections
$STD apt install -y tvheadend
msg_ok "Installed Tvheadend"

msg_info "Starting Service"
systemctl enable -q --now tvheadend
msg_ok "Started Service"

msg_info "Saving Credentials"
cat <<EOF >~/tvheadend.creds
Tvheadend Admin Credentials
Username: ${var_admin_user}
Password: ${var_admin_pass}
EOF
msg_ok "Saved Credentials"

motd_ssh
customize
cleanup_lxc
