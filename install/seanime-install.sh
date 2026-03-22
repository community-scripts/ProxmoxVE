#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Mike F (mkforde)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://seanime.app/ | Github: https://github.com/5rahim/seanime

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os
setup_hwaccel

function normalize_seanime_binary() {
  local binary_path
  binary_path=$(find /opt/seanime/app -maxdepth 1 -type f \( -name 'seanime' -o -name 'seanime-*' -o -name 'Seanime*' \) ! -name '*.tar.gz' ! -name '*.zip' | sort | head -n1)

  if [[ -z "$binary_path" ]]; then
    msg_error "Unable to locate Seanime binary after extraction"
    exit 1
  fi

  chmod 755 "$binary_path"
  if [[ "$binary_path" != "/opt/seanime/app/seanime" ]]; then
    mv "$binary_path" /opt/seanime/app/seanime
  fi
  chmod 755 /opt/seanime/app/seanime
  chown -R root:root /opt/seanime/app
}

msg_info "Installing Dependencies"
$STD apt install -y ffmpeg
msg_ok "Installed Dependencies"

msg_info "Preparing Directories"
mkdir -p /opt/seanime/app /opt/seanime/data
msg_ok "Prepared Directories"

case "$(dpkg --print-architecture 2>/dev/null || uname -m)" in
amd64 | x86_64)
  fetch_and_deploy_gh_release "seanime" "5rahim/seanime" "prebuild" "latest" "/opt/seanime/app" "seanime-*Linux_x86_64.tar.gz"
  ;;
arm64 | aarch64)
  fetch_and_deploy_gh_release "seanime" "5rahim/seanime" "prebuild" "latest" "/opt/seanime/app" "seanime-*Linux_arm64.tar.gz"
  ;;
*)
  msg_error "Unsupported architecture: $(dpkg --print-architecture 2>/dev/null || uname -m)"
  exit 1
  ;;
esac
normalize_seanime_binary

msg_info "Configuring Seanime"
cat <<EOF >/opt/seanime/seanime.env
HOME=/opt/seanime/data
SEANIME_DATA_DIR=/opt/seanime/data
SEANIME_SERVER_HOST=0.0.0.0
SEANIME_SERVER_PORT=43211
EOF
chown root:root /opt/seanime/seanime.env
chmod 640 /opt/seanime/seanime.env
msg_ok "Configured Seanime"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/seanime.service
[Unit]
Description=Seanime Server
After=network.target

[Service]
Type=simple
EnvironmentFile=/opt/seanime/seanime.env
WorkingDirectory=/opt/seanime/app
ExecStart=/opt/seanime/app/seanime
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now seanime
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
