#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rustdesk/rustdesk-server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

if [[ -n "${var_rustdesk_api:-}" ]]; then
  prompt="$var_rustdesk_api"
else
  read -r -p "${TAB3}Would you like to add the RustDesk API web UI (lejianwen/rustdesk-api, unmaintained since 09/2025)? <y/N> " prompt
fi
INSTALL_API=0
[[ "${prompt,,}" =~ ^(y|yes|true)$ ]] && INSTALL_API=1
API_PASS="$(random_password 16)"

# rustdesk-api hands these to clients; its shipped defaults point at 192.168.1.66
api_env() {
  printf '%s\n' \
    "RUSTDESK_API_RUSTDESK_ID_SERVER=${LOCAL_IP}:21116" \
    "RUSTDESK_API_RUSTDESK_RELAY_SERVER=${LOCAL_IP}:21117" \
    "RUSTDESK_API_RUSTDESK_API_SERVER=http://${LOCAL_IP}:21114" \
    "RUSTDESK_API_RUSTDESK_KEY_FILE=$1"
}

# hbbs creates its key pair in its working directory on first start
write_creds() {
  local key_file="$1"
  for _ in $(seq 1 30); do
    [[ -s "$key_file" ]] && break
    sleep 1
  done
  if [[ ! -s "$key_file" ]]; then
    msg_error "hbbs did not create ${key_file}"
    exit 1
  fi
  cat <<EOF >~/rustdesk.creds
RustDesk Server
ID Server: ${LOCAL_IP}
Key: $(<"$key_file")
EOF
  if ((INSTALL_API)); then
    cat <<EOF >>~/rustdesk.creds

RustDesk API Web UI: http://${LOCAL_IP}:21114/_admin/
Username: admin
Password: ${API_PASS}
EOF
  fi
}

setup_deb_based() {
  fetch_and_deploy_gh_release "rustdesk-hbbr" "rustdesk/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-hbbr*$(arch_resolve).deb"
  fetch_and_deploy_gh_release "rustdesk-hbbs" "rustdesk/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-hbbs*$(arch_resolve).deb"
  fetch_and_deploy_gh_release "rustdesk-utils" "rustdesk/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-utils*$(arch_resolve).deb"
  systemctl enable -q --now rustdesk-hbbs rustdesk-hbbr
  write_creds /var/lib/rustdesk-server/id_ed25519.pub

  if ((INSTALL_API)); then
    fetch_and_deploy_gh_release "rustdesk-api" "lejianwen/rustdesk-api" "binary" "latest" "/opt/rustdesk" "rustdesk-api-server*$(arch_resolve).deb"
    msg_info "Configuring RustDesk API"
    mkdir -p /etc/systemd/system/rustdesk-api.service.d
    {
      echo "[Service]"
      api_env /var/lib/rustdesk-server/id_ed25519.pub | sed 's/^/Environment=/'
    } >/etc/systemd/system/rustdesk-api.service.d/override.conf
    systemctl daemon-reload
    systemctl stop rustdesk-api
    cd /var/lib/rustdesk-api
    $STD rustdesk-api reset-admin-pwd "$API_PASS"
    systemctl enable -q --now rustdesk-api
    msg_ok "Configured RustDesk API"
  fi
}

setup_alpine() {
  fetch_and_deploy_gh_release "rustdesk-server" "rustdesk/rustdesk-server" "prebuild" "latest" "/opt/rustdesk-server" "rustdesk-server-linux-$(arch_resolve "amd64" "arm64v8").zip"

  msg_info "Creating RustDesk Server Services"
  for svc in hbbs hbbr; do
    cat <<EOF >"/etc/init.d/rustdesk-server-${svc}"
#!/sbin/openrc-run
description="RustDesk ${svc^^} Service"
directory="/opt/rustdesk-server"
command="/opt/rustdesk-server/${svc}"
command_background="true"
pidfile="/var/run/rustdesk-server-${svc}.pid"
output_log="/var/log/rustdesk-${svc}.log"
error_log="/var/log/rustdesk-${svc}.err"

depend() {
    use net
}
EOF
    chmod +x "/etc/init.d/rustdesk-server-${svc}"
    $STD rc-update add "rustdesk-server-${svc}" default
    $STD service "rustdesk-server-${svc}" start
  done
  msg_ok "Created RustDesk Server Services"
  write_creds /opt/rustdesk-server/id_ed25519.pub

  if ((INSTALL_API)); then
    fetch_and_deploy_gh_release "rustdesk-api" "lejianwen/rustdesk-api" "prebuild" "latest" "/opt/rustdesk-api" "linux-$(arch_resolve).tar.gz"
    msg_info "Configuring RustDesk API"
    api_env /opt/rustdesk-server/id_ed25519.pub | sed 's/^/export /' >/etc/conf.d/rustdesk-api
    cd /opt/rustdesk-api
    $STD ./apimain reset-admin-pwd "$API_PASS"
    cat <<EOF >/etc/init.d/rustdesk-api
#!/sbin/openrc-run
description="RustDesk API Service"
directory="/opt/rustdesk-api"
command="/opt/rustdesk-api/apimain"
command_background="true"
pidfile="/var/run/rustdesk-api.pid"
output_log="/var/log/rustdesk-api.log"
error_log="/var/log/rustdesk-api.err"

depend() {
    use net
    after rustdesk-server-hbbs
}
EOF
    chmod +x /etc/init.d/rustdesk-api
    $STD rc-update add rustdesk-api default
    $STD service rustdesk-api start
    msg_ok "Configured RustDesk API"
  fi
}

run_os_setup

motd_ssh
customize
cleanup_lxc
