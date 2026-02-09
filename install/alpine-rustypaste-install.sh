#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/orhun/rustypaste

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing RustyPaste"
$STD apk add --no-cache rustypaste --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community
msg_ok "Installed RustyPaste"

msg_info "Configuring RustyPaste"
mkdir -p /var/lib/rustypaste
sed -i 's|^address = ".*"|address = "0.0.0.0:8000"|' /etc/rustypaste/config.toml
msg_ok "Configured RustyPaste"

msg_info "Creating Service"
cat <<'EOF' >/etc/init.d/rustypaste
#!/sbin/openrc-run

name="rustypaste"
description="RustyPaste - A minimal file upload/pastebin service"
command="/usr/bin/rustypaste"
command_args=""
command_user="root"
command_background=true
pidfile="/run/${RC_SVCNAME}.pid"
directory="/var/lib/rustypaste"

depend() {
    need net
    after firewall
}

start_pre() {
    export CONFIG=/etc/rustypaste/config.toml
    checkpath --directory --owner root:root --mode 0755 /var/lib/rustypaste
}
EOF
chmod +x /etc/init.d/rustypaste
$STD rc-update add rustypaste default
$STD rc-service rustypaste start
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
