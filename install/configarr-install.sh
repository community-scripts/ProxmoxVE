#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: finkerle,BlackDark
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/raydak-labs/configarr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  git
msg_ok "Installed Dependencies"

get_configarr_architecture() {
    local arch
    local configarr_tar
    
    # Determine system architecture
    arch=$(uname -m)
    
    case "$arch" in
        x86_64)
            configarr_tar="configarr-linux-x64.tar.xz"
            ;;
        aarch64)
            configarr_tar="configarr-linux-arm64.tar.xz"
            ;;
        *)
            echo "Unsupported architecture: $arch" >&2
            return 1
            ;;
    esac
    
    # Return the filename via stdout
    echo "$configarr_tar"
    return 0
}

# Call the function and capture the result
if configarr_file=$(get_configarr_architecture); then
    fetch_and_deploy_gh_release "configarr" "raydak-labs/configarr" "prebuild" "latest" "/opt/configarr" "$configarr_file"
else
    exit 1
fi

CONFIG_LOCATION=/opt/configarr/config.yml
SECRETS_LOCATION=/opt/configarr/secrets.yml

msg_info "Setup ${APPLICATION}"
cat <<EOF >/opt/configarr/.env
ROOT_PATH=/opt/configarr
CUSTOM_REPO_ROOT=/opt/configarr/repos
CONFIG_LOCATION=$CONFIG_LOCATION
SECRETS_LOCATION=$SECRETS_LOCATION
EOF

CONFIGARR_CONFIG_TEMPLATE_URL=https://raw.githubusercontent.com/raydak-labs/configarr/refs/heads/main/examples/full/config/config.yml
CONFIGARR_SECRETS_TEMPLATE_URL=https://raw.githubusercontent.com/raydak-labs/configarr/refs/heads/main/examples/full/config/secrets.yml

download_with_progress "$CONFIGARR_CONFIG_TEMPLATE_URL" "$CONFIG_LOCATION"
download_with_progress "$CONFIGARR_SECRETS_TEMPLATE_URL" "$SECRETS_LOCATION"

msg_ok "Setup ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/configarr-task.service
[Unit]
Description=Run Configarr Task

[Service]
Type=oneshot
WorkingDirectory=/opt/configarr
ExecStart=/opt/configarr/configarr
EOF

cat <<EOF >/etc/systemd/system/configarr-task.timer
[Unit]
Description=Run Configarr every 5 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl enable -q --now configarr-task.timer configarr-task.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
