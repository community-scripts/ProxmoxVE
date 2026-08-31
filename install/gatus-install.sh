#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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

setup_deb_based() {
  msg_info "Installing Dependencies"
  $STD apt install -y \
    ca-certificates \
    libcap2-bin
  msg_ok "Installed Dependencies"

  fetch_and_deploy_gh_release "gatus" "TwiN/gatus" "tarball"
  GO_VERSION="$(grep -m1 '^go ' /opt/gatus/go.mod | awk '{print $2}')" setup_go

  msg_info "Configuring gatus"
  cd /opt/gatus
  $STD go mod tidy
  CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .
  setcap CAP_NET_RAW+ep gatus
  mv config.yaml config
  msg_ok "Configured gatus"

  msg_info "Creating Service"
  cat <<EOF >/etc/systemd/system/gatus.service
[Unit]
Description=gatus Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/gatus
ExecStart=/opt/gatus/gatus
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now gatus
  msg_ok "Created Service"
}

setup_alpine() {
  msg_info "Installing dependencies"
  $STD apk add --no-cache \
    ca-certificates \
    libcap-setcap
  $STD apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community go
  msg_ok "Installed dependencies"

  fetch_and_deploy_gh_release "gatus" "TwiN/gatus" "tarball"

  msg_info "Configuring gatus"
  cd /opt/gatus
  $STD go get golang.org/x/net@v0.55.0
  $STD go mod tidy
  CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .
  setcap CAP_NET_RAW+ep gatus
  mv config.yaml config
  msg_ok "Configured gatus"

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
}

run_os_setup

motd_ssh
customize
cleanup_lxc
