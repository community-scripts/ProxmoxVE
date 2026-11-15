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

setup_deb_based() {
  fetch_and_deploy_gh_release "openlist" "OpenListTeam/OpenList" "prebuild" "latest" "/opt/openlist" "openlist-linux-musl-$(arch_resolve "amd64" "arm64").tar.gz"

  msg_info "Configuring OpenList"
  ADMIN_PASS="$(random_password 16)"
  $STD /opt/openlist/openlist --data /opt/openlist_data admin set "$ADMIN_PASS"
  if [[ ! -f /opt/openlist_data/data.db ]]; then
    msg_error "OpenList did not initialise its database"
    exit 1
  fi
  cat <<EOF >~/openlist.creds
OpenList Credentials
Username: admin
Password: ${ADMIN_PASS}
EOF
  chmod 600 ~/openlist.creds
  msg_ok "Configured OpenList"

  msg_info "Creating Service"
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
  msg_ok "Created Service"
}

setup_alpine() {
  fetch_and_deploy_gh_release "openlist" "OpenListTeam/OpenList" "prebuild" "latest" "/opt/openlist" "openlist-linux-musl-$(arch_resolve "amd64" "arm64").tar.gz"

  msg_info "Configuring OpenList"
  ADMIN_PASS="$(random_password 16)"
  $STD /opt/openlist/openlist --data /opt/openlist_data admin set "$ADMIN_PASS"
  if [[ ! -f /opt/openlist_data/data.db ]]; then
    msg_error "OpenList did not initialise its database"
    exit 1
  fi
  cat <<EOF >~/openlist.creds
OpenList Credentials
Username: admin
Password: ${ADMIN_PASS}
EOF
  chmod 600 ~/openlist.creds
  msg_ok "Configured OpenList"

  msg_info "Creating Service"
  cat <<EOF >/etc/init.d/openlist
#!/sbin/openrc-run
name="openlist"
description="OpenList Daemon"
directory="/opt/openlist"
command="/opt/openlist/openlist"
command_args="server --data /opt/openlist_data"
command_background="yes"
pidfile="/run/openlist.pid"

depend() {
    need net
}
EOF
  chmod +x /etc/init.d/openlist
  $STD rc-update add openlist default
  $STD rc-service openlist start
  msg_ok "Created Service"
}

run_os_setup

motd_ssh
customize
cleanup_lxc
