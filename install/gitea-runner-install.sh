#!/usr/bin/env bash

# Copyright (c) 2021-2026 remz1337
# Author: remz1337
# License: MIT | https://github.com/remz1337/ProxmoxVE/raw/remz/LICENSE
# Source: https://gitea.com/gitea/act_runner/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
    curl \
    jq \
    git \
    build-essential \
    sudo
msg_ok "Installed Dependencies"

# --- Fetch Latest Binary ---
msg_info "Fetching act_runner Binary"
API_URL="https://gitea.com/api/v1/repos/gitea/act_runner/releases/latest"
DOWNLOAD_URL=$(curl -s $API_URL | jq -r '.assets[] | select(.name | contains("linux-amd64")) | .browser_download_url' | head -n 1)

curl -L -o /usr/local/bin/act_runner "$DOWNLOAD_URL"
chmod +x /usr/local/bin/act_runner
msg_ok "Downloaded act_runner"

# --- Configure Environment ---
msg_info "Configuring Environment"
if ! getent passwd gitea >/dev/null; then
  adduser --system --group --disabled-password --shell /bin/bash --home /var/lib/act_runner gitea
fi

# Add sudo permissions for the gitea user
echo "gitea ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/gitea
chmod 440 /etc/sudoers.d/gitea

mkdir -p /var/lib/act_runner
chown -R gitea:gitea /var/lib/act_runner
msg_ok "Configured Environment & Sudoers"

# --- Interactive Registration ---
echo -e "\n${GN}--- Gitea Runner Registration ---${CL}"
read -p "Enter Gitea Instance URL: " GITEA_URL
read -p "Enter Registration Token: " GITEA_TOKEN
read -p "Enter Runner Name (default: $(hostname)): " RUNNER_NAME
RUNNER_NAME=${RUNNER_NAME:-$(hostname)}

# --- Generate and Patch Config ---
msg_info "Generating Config"
cd /var/lib/act_runner
sudo -u gitea act_runner generate-config > /var/lib/act_runner/config.yaml

# Patch the labels into the config file since CLI labels are ignored with -c
sed -i 's/labels: \[\]/labels: ["debian-latest:host", "debian-12:host", "linux:host"]/' /var/lib/act_runner/config.yaml
msg_ok "Configured Host Labels"

# --- Register ---
msg_info "Registering Runner..."
# cd into directory to ensure .runner is created with correct permissions
sudo -u gitea act_runner register \
  --instance "$GITEA_URL" \
  --token "$GITEA_TOKEN" \
  --name "$RUNNER_NAME" \
  --config /var/lib/act_runner/config.yaml \
  --no-interactive
msg_ok "Runner Registered Successfully"

# --- Create Service ---
msg_info "Creating Systemd Service"
cat <<EOF >/etc/systemd/system/act_runner.service
[Unit]
Description=Gitea act_runner (Host Mode)
After=network.target

[Service]
ExecStart=/usr/local/bin/act_runner daemon --config /var/lib/act_runner/config.yaml
WorkingDirectory=/var/lib/act_runner
User=gitea
Group=gitea
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable -q --now act_runner
msg_ok "Created and Started act_runner.service"

# --- Cleanup ---
motd_ssh
customize
cleanup_lxc

msg_ok "Installation Complete!"
echo -e "Use ${BL}runs-on: debian-latest${CL} in your YAML files."
echo -e "Actions can now use ${BL}sudo apt install ...${CL} without a password."