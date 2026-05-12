#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wakapi.dev/ | https://github.com/muety/wakapi

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apk add --no-cache \
  ca-certificates \
  tzdata
$STD update-ca-certificates
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "wakapi" "muety/wakapi" "prebuild" "latest" "/opt/wakapi" "wakapi_linux_amd64.zip"

msg_info "Configuring Wakapi"
LOCAL_IP=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
cd /opt/wakapi
sed -i 's/listen_ipv6: ::1/listen_ipv6: "-"/g' config.yml
sed -i 's/listen_ipv4: 127.0.0.1/listen_ipv4: "0.0.0.0"/g' config.yml
sed -i "s/public_url: http:\/\/localhost:3000/public_url: http:\/\/$LOCAL_IP:3000/g" config.yml
msg_ok "Configured Wakapi"

msg_info "Enabling Wakapi Service"
cat <<EOF >/etc/init.d/wakapi
#!/sbin/openrc-run
description="Wakapi Service"
directory="/opt/wakapi"
command="/opt/wakapi/wakapi"
command_args="-config config.yml"
command_background="true"
command_user="root"
pidfile="/var/run/wakapi.pid"

depend() {
    use net
}
EOF
chmod +x /etc/init.d/wakapi
$STD rc-update add wakapi default
msg_ok "Enabled Wakapi Service"

msg_info "Starting Wakapi"
$STD rc-service wakapi start
msg_ok "Started Wakapi"

motd_ssh
customize
