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

setup_deb_based() {
  fetch_and_deploy_gh_release "rustdesk-hbbr" "lejianwen/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-hbbr*$(arch_resolve).deb"
  fetch_and_deploy_gh_release "rustdesk-hbbs" "lejianwen/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-hbbs*$(arch_resolve).deb"
  fetch_and_deploy_gh_release "rustdesk-utils" "lejianwen/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-utils*$(arch_resolve).deb"
  fetch_and_deploy_gh_release "rustdesk-api" "lejianwen/rustdesk-api" "binary" "latest" "/opt/rustdesk" "rustdesk-api-server*$(arch_resolve).deb"
  systemctl enable -q --now rustdesk-hbbr
  systemctl enable -q --now rustdesk-hbbs
  systemctl enable -q --now rustdesk-api
}

setup_alpine() {
  fetch_and_deploy_gh_release "rustdesk-server" "lejianwen/rustdesk-server" "prebuild" "latest" "/opt/rustdesk-server" "rustdesk-server-linux-$(arch_resolve "amd64" "arm64v8").zip"

  msg_info "Configuring RustDesk Server"
  mkdir -p /root/.config/rustdesk
  cd /opt/rustdesk-server
  ./rustdesk-utils genkeypair >/tmp/rustdesk_keys.txt
  grep "Public Key" /tmp/rustdesk_keys.txt | awk '{print $3}' >/root/.config/rustdesk/id_ed25519.pub
  grep "Secret Key" /tmp/rustdesk_keys.txt | awk '{print $3}' >/root/.config/rustdesk/id_ed25519
  chmod 600 /root/.config/rustdesk/id_ed25519
  chmod 644 /root/.config/rustdesk/id_ed25519.pub
  rm /tmp/rustdesk_keys.txt
  msg_ok "Configured RustDesk Server"

  fetch_and_deploy_gh_release "rustdesk-api" "lejianwen/rustdesk-api" "prebuild" "latest" "/opt/rustdesk-api" "linux-$(arch_resolve).tar.gz"

  msg_info "Configuring RustDesk API"
  cd /opt/rustdesk-api
  ADMINPASS=$(head -c 16 /dev/urandom | xxd -p -c 16)
  $STD ./apimain reset-admin-pwd "$ADMINPASS"
  cat <<EOF >~/rustdesk.creds
RustDesk WebUI

Username: admin
Password: $ADMINPASS
EOF
  msg_ok "Configured RustDesk API"

  msg_info "Enabling RustDesk Server Services"
  cat <<EOF >/etc/init.d/rustdesk-server-hbbs
#!/sbin/openrc-run
description="RustDesk HBBS Service"
directory="/opt/rustdesk-server"
command="/opt/rustdesk-server/hbbs"
command_args=""
command_background="true"
command_user="root"
pidfile="/var/run/rustdesk-server-hbbs.pid"
output_log="/var/log/rustdesk-hbbs.log"
error_log="/var/log/rustdesk-hbbs.err"

depend() {
    use net
}
EOF

  cat <<EOF >/etc/init.d/rustdesk-server-hbbr
#!/sbin/openrc-run
description="RustDesk HBBR Service"
directory="/opt/rustdesk-server"
command="/opt/rustdesk-server/hbbr"
command_args=""
command_background="true"
command_user="root"
pidfile="/var/run/rustdesk-server-hbbr.pid"
output_log="/var/log/rustdesk-hbbr.log"
error_log="/var/log/rustdesk-hbbr.err"

depend() {
    use net
}
EOF

  cat <<EOF >/etc/init.d/rustdesk-api
#!/sbin/openrc-run
description="RustDesk API Service"
directory="/opt/rustdesk-api"
command="/opt/rustdesk-api/apimain"
command_args=""
command_background="true"
command_user="root"
pidfile="/var/run/rustdesk-api.pid"
output_log="/var/log/rustdesk-api.log"
error_log="/var/log/rustdesk-api.err"

depend() {
    use net
}
EOF
  chmod +x /etc/init.d/rustdesk-server-hbbs
  chmod +x /etc/init.d/rustdesk-server-hbbr
  chmod +x /etc/init.d/rustdesk-api
  $STD rc-update add rustdesk-server-hbbs default
  $STD rc-update add rustdesk-server-hbbr default
  $STD rc-update add rustdesk-api default
  msg_ok "Enabled RustDesk Server Services"

  msg_info "Starting RustDesk Server"
  $STD service rustdesk-server-hbbs start
  $STD service rustdesk-server-hbbr start
  $STD service rustdesk-api start
  msg_ok "Started RustDesk Server"
}

run_os_setup

motd_ssh
customize
cleanup_lxc
