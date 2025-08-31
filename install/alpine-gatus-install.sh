#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TwiN/gatus

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apk add --no-cache \
  ca-certificates \
  libcap-setcap \
  go
msg_ok "Installed dependencies"

fetch_and_deploy_gh_release "gatus" "TwiN/gatus" "tarball"

msg_info "Installing gatus"
cd /opt/gatus
$STD go mod tidy
CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .
setcap CAP_NET_RAW+ep gatus
mv config.yaml config
msg_ok "Installed gatus"

msg_info "Enabling gatus Service"
cat <<EOF >/etc/init.d/gatus
#!/sbin/openrc-run
description="gatus Service"
directory="/opt/gatus"
command="/opt/gatus/gatus"
command_args=""
command_background="true"
command_user="root"
pidfile="/var/run/gatus.pid"

export GATUS_CONFIG_PATH=""
export GATUS_LOG_LEVEL="INFO"
export PORT="8080"

depend() {
    use net
}
EOF
chmod +x /etc/init.d/gatus
$STD rc-update add gatus default
msg_ok "Enabled gatus Service"

msg_info "Starting gatus"
$STD service gatus start
msg_ok "Started gatus"

motd_ssh
customize

msg_info "Cleaning up"
$STD apk cache clean
msg_ok "Cleaned"
