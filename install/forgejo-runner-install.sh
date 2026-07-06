#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Simon Friedrich (lengschder97)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://forgejo.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_yq

# Get required configuration — skip prompts if already set (generated/unattended mode)
if [[ -z "${var_forgejo_instance:-}" ]]; then
  read -r -p "${TAB3}Forgejo Instance URL (e.g. https://codeberg.org): " var_forgejo_instance
  var_forgejo_instance="${var_forgejo_instance:-https://codeberg.org}"
fi

if [[ -z "${var_forgejo_runner_uuid:-}" ]]; then
  read -r -p "${TAB3}Forgejo Runner UUID: " var_forgejo_runner_uuid
fi

if [[ -z "${var_forgejo_runner_uuid:-}" ]]; then
  msg_error "No runner UUID provided. Cannot continue."
  exit 1
fi

if [[ -z "${var_forgejo_runner_token:-}" ]]; then
  read -r -p "${TAB3}Forgejo Runner Token: " var_forgejo_runner_token
fi

if [[ -z "${var_forgejo_runner_token:-}" ]]; then
  msg_error "No runner registration token provided. Cannot continue."
  exit 1
fi

# Runner labels — default is always included; additional labels are appended
DEFAULT_RUNNER_LABELS="linux-amd64:docker://node:22-bookworm"
if [[ -z "${var_runner_labels:-}" ]]; then
  read -r -p "${TAB3}Additional runner labels (comma-separated, or leave blank for default only): " var_runner_labels
fi
if [[ -n "${var_runner_labels:-}" ]]; then
  RUNNER_LABELS="${DEFAULT_RUNNER_LABELS},${var_runner_labels}"
else
  RUNNER_LABELS="${DEFAULT_RUNNER_LABELS}"
fi

export FORGEJO_INSTANCE="$var_forgejo_instance"
export FORGEJO_RUNNER_TOKEN="$var_forgejo_runner_token"
export FORGEJO_RUNNER_UUID="$var_forgejo_runner_uuid"
export RUNNER_LABELS

msg_info "Installing dependencies"
$STD apt install -y \
  git \
  podman podman-docker
msg_ok "Installed dependencies"

msg_info "Enabling Podman socket"
systemctl enable --now podman.socket
msg_ok "Enabled Podman socket"

msg_info "Installing Forgejo Runner"
RUNNER_VERSION=$(curl -fsSL https://data.forgejo.org/api/v1/repos/forgejo/runner/releases/latest | jq -r .name | sed 's/^v//')
curl -fsSL "https://code.forgejo.org/forgejo/runner/releases/download/v${RUNNER_VERSION}/forgejo-runner-${RUNNER_VERSION}-linux-$(arch_resolve)" -o /usr/local/bin/forgejo-runner
chmod +x /usr/local/bin/forgejo-runner
echo "${RUNNER_VERSION}" >~/.forgejo-runner
msg_ok "Installed Forgejo Runner"

msg_info "Registering Forgejo Runner"
export DOCKER_HOST="unix:///run/podman/podman.sock"

msg_info "Generating Forgejo Runner Configuration"
mkdir -p /etc/forgejo-runner
CONFIG_FILE="/etc/forgejo-runner/config.yaml"
forgejo-runner generate-config > $CONFIG_FILE
yq -i '
  .container.docker_host = strenv(DOCKER_HOST) |
  .server.connections.forgejo.url = strenv(FORGEJO_INSTANCE) |
  .server.connections.forgejo.uuid = strenv(FORGEJO_RUNNER_UUID) |
  .server.connections.forgejo.token = strenv(FORGEJO_RUNNER_TOKEN) |
  .server.connections.forgejo.labels = (strenv(RUNNER_LABELS) | split(",") | map(select(length > 0)))
  ' $CONFIG_FILE
msg_ok "Generated Forgejo Runner Configuration"


msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/forgejo-runner.service
[Unit]
Description=Forgejo Runner
Documentation=https://forgejo.org/docs/latest/admin/actions/
After=podman.socket
Requires=podman.socket

[Service]
User=root
WorkingDirectory=/root
Environment=DOCKER_HOST=unix:///run/podman/podman.sock
ExecStart=/usr/local/bin/forgejo-runner daemon -c $CONFIG_FILE
Restart=on-failure
RestartSec=10
TimeoutSec=0

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now forgejo-runner
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
