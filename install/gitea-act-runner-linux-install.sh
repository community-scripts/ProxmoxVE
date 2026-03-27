#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: KohanMathers
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gitea.com/gitea/act_runner

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
apt-get install -y --no-install-recommends \
  curl \
  ca-certificates \
  git \
  sudo &>/dev/null
msg_ok "Installed Dependencies"

msg_info "Fetching latest act_runner release"
RELEASE=$(curl -s https://gitea.com/api/v1/repos/gitea/act_runner/releases/latest \
  | grep -o '"tag_name":"[^"]*"' | cut -d'"' -f4)
VERSION="${RELEASE#v}"
ARCH=$(dpkg --print-architecture)
msg_ok "Latest release: ${RELEASE}"

msg_info "Downloading act_runner (${ARCH})"
mkdir -p /opt/act_runner
curl -fsSL "https://gitea.com/gitea/act_runner/releases/download/${RELEASE}/act_runner-${VERSION}-linux-${ARCH}" \
  -o /opt/act_runner/act_runner
chmod +x /opt/act_runner/act_runner
msg_ok "Downloaded act_runner"

echo ""
echo -e "${YW}--- Gitea Act Runner Configuration ---${CL}"
echo ""

read -rp "  Enter your Gitea instance URL (e.g. https://git.example.com): " GITEA_URL
while [[ -z "$GITEA_URL" ]]; do
  echo -e "${RD}  URL cannot be empty.${CL}"
  read -rp "  Enter your Gitea instance URL: " GITEA_URL
done

read -rp "  Enter your runner registration token: " RUNNER_TOKEN
while [[ -z "$RUNNER_TOKEN" ]]; do
  echo -e "${RD}  Token cannot be empty.${CL}"
  read -rp "  Enter your runner registration token: " RUNNER_TOKEN
done

read -rp "  Enter a name for this runner [default: act-runner]: " RUNNER_NAME
RUNNER_NAME="${RUNNER_NAME:-act-runner}"

read -rp "  Enter runner labels (comma-separated) [default: ubuntu-latest,ubuntu-22.04,linux]: " RUNNER_LABELS
RUNNER_LABELS="${RUNNER_LABELS:-ubuntu-latest,ubuntu-22.04,linux}"

echo ""
msg_info "Generating config"
/opt/act_runner/act_runner generate-config > /opt/act_runner/config.yaml
msg_ok "Config generated"

msg_info "Registering runner with Gitea"
/opt/act_runner/act_runner register \
  --no-interactive \
  --instance "${GITEA_URL}" \
  --token "${RUNNER_TOKEN}" \
  --name "${RUNNER_NAME}" \
  --labels "${RUNNER_LABELS}" \
  --config /opt/act_runner/config.yaml &>/dev/null
msg_ok "Runner registered as '${RUNNER_NAME}'"

msg_info "Creating systemd service"
cat >/etc/systemd/system/act_runner.service <<EOF
[Unit]
Description=Gitea Act Runner
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/act_runner
ExecStart=/opt/act_runner/act_runner daemon --config /opt/act_runner/config.yaml
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
msg_ok "Created systemd service"

msg_info "Enabling and starting act_runner service"
systemctl enable -q act_runner
systemctl start act_runner
msg_ok "act_runner service started"

motd_ssh
customize

echo ""
msg_ok "${APP} Installation Complete"
echo -e "  ${YW}Runner Name:${CL}   ${BGN}${RUNNER_NAME}${CL}"
echo -e "  ${YW}Gitea URL:${CL}     ${BGN}${GITEA_URL}${CL}"
echo -e "  ${YW}Labels:${CL}        ${BGN}${RUNNER_LABELS}${CL}"
echo -e "  ${YW}Config:${CL}        ${BGN}/opt/act_runner/config.yaml${CL}"
echo -e "  ${YW}Logs:${CL}          ${BGN}journalctl -u act_runner -f${CL}"
