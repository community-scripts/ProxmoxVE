#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/marcopiovanello/yt-dlp-web-ui

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y ffmpeg
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "yt-dlp-webui" "marcopiovanello/yt-dlp-web-ui" "singlefile" "latest" "/usr/local/bin" "yt-dlp-webui_linux-amd64"
fetch_and_deploy_gh_release "yt-dlp" "yt-dlp/yt-dlp" "singlefile" "latest" "/usr/local/bin" "yt-dlp"

msg_info "Setting up YT-DLP-WEBUI"
mkdir -p /opt/yt-dlp-webui
mkdir /downloads
RPC_PASSWORD=$(openssl rand -base64 16)
{
  echo "yt-dlp-webui-Credentials"
  echo "Username: admin"
  echo "Password: ${RPC_PASSWORD}"
} >>~/yt-dlp-webui.creds

cat <<EOF >/opt/yt-dlp-webui/config.conf
# Host where server will listen at (default: "0.0.0.0")
#host: 0.0.0.0

# Port where server will listen at (default: 3033)
port: 3033

# Directory where downloaded files will be stored (default: ".")
downloadPath: /downloads

# [optional] Enable RPC authentication (requires username and password)
require_auth: true
username: admin
password: ${RPC_PASSWORD}

# [optional] The download queue size (default: logical cpu cores)
queue_size: 4 # min. 2

# [optional] Full path to the yt-dlp (default: "yt-dlp")
downloaderPath: /usr/local/bin/yt-dlp

# [optional] Enable file based logging with rotation (default: false)
#enable_file_logging: false

# [optional] Directory where the log file will be stored (default: ".")
#log_path: .

# [optional] Directory where the session database file will be stored (default: ".")
#session_file_path: .

# [optional] Path where the sqlite database will be created/opened (default: "./local.db")
#local_database_path

# [optional] Path where a custom frontend will be loaded (instead of the embedded one)
#frontend_path: ./web/solid-frontend
EOF
msg_ok "Set up YT-DLP-WEBUI"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/yt-dlp-webui.service
[Unit]
Description=yt-dlp-webui service file
After=network.target

[Service]
ExecStart=/usr/local/bin/yt-dlp-webui --conf /opt/yt-dlp-webui/config.conf

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now yt-dlp-webui
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
