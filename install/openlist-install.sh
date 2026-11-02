#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: uchouT (uchouT)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/OpenListTeam/OpenList/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "openlist" "OpenListTeam/OpenList" "prebuild" "latest" "/opt/openlist" "openlist-linux-musl-$(arch_resolve "amd64" "arm64").tar.gz"

msg_info "Setting up OpenList"
ADMIN_PASS="$(head -c 256 /dev/urandom | tr -dc 'A-Za-z0-9')"
ADMIN_PASS="${ADMIN_PASS:0:16}"
$STD /opt/openlist/openlist --data /opt/openlist_data admin set "$ADMIN_PASS"
if [[ ! -f /opt/openlist_data/data.db ]]; then
  msg_error "OpenList did not initialise its database"
  exit 1
fi
{
  echo "OpenList Credentials"
  echo "Username: admin"
  echo "Password: ${ADMIN_PASS}"
} >~/openlist.creds
chmod 600 ~/openlist.creds
msg_ok "Set up OpenList"

setup_deb_based() {
  msg_info "Creating OpenList Service"
  cat <<EOF >/etc/systemd/system/openlist.service
[Unit]
Description=OpenList
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/openlist
ExecStart=/opt/openlist/openlist server --data /opt/openlist_data
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now openlist
  msg_ok "Created OpenList Service"
}

setup_alpine() {
  msg_info "Creating OpenList Service"
  cat <<'EOF' >/etc/init.d/openlist
#!/sbin/openrc-run
name="OpenList"
description="OpenList - a file list program that supports multiple storages"

command="/opt/openlist/openlist"
command_args="server --data /opt/openlist_data"
supervisor=supervise-daemon
directory="/opt/openlist"
output_log="/var/log/openlist.log"
error_log="/var/log/openlist.log"
respawn_delay=10

depend() {
  need net
  after firewall
}

start_pre() {
  checkpath -f -m 0640 "$output_log"
}
EOF
  chmod +x /etc/init.d/openlist
  $STD rc-update add openlist default
  $STD rc-service openlist start
  msg_ok "Created OpenList Service"
}

run_os_setup

motd_ssh
customize
cleanup_lxc
