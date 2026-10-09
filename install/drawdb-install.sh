#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/drawdb-io/drawdb

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y nginx
msg_ok "Installed Dependencies"

NODE_VERSION="20" setup_nodejs
fetch_and_deploy_gh_tag "drawdb" "drawdb-io/drawdb" "latest" "/opt/drawdb"

msg_info "Building Frontend"
cd /opt/drawdb
$STD npm ci
NODE_OPTIONS="--max-old-space-size=4096" $STD npm run build
msg_ok "Built Frontend"

msg_info "Applying crypto.randomUUID Polyfill"
sed -i '/<head>/a <script>if(!crypto.randomUUID){crypto.randomUUID=function(){return([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g,function(c){return(c^(crypto.getRandomValues(new Uint8Array(1))[0]&(15>>c/4))).toString(16)})}};</script>' /opt/drawdb/dist/index.html
msg_ok "Applied Polyfill"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/conf.d/drawdb.conf
server {
    listen 3000;
    server_name _;
    root /opt/drawdb/dist;

    location / {
        try_files \$uri /index.html;
    }
}
EOF
rm -f /etc/nginx/sites-enabled/default
systemctl enable -q --now nginx
systemctl reload nginx
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
