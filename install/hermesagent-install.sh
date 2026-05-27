#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Stephen Chin (steveonjava)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://hermes-agent.nousresearch.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y git
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Creating Hermes User"
useradd -m -s /bin/bash hermes
loginctl enable-linger hermes
echo 'export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"' >>/home/hermes/.profile
msg_ok "Created Hermes User"

msg_info "Configuring Service Environment"
cat <<EOF >/etc/default/hermes
HOME=/home/hermes
PATH=/home/hermes/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
NODE_OPTIONS=${NODE_OPTIONS}
EOF
msg_ok "Configured Service Environment"

msg_warn "WARNING: This script will run an external installer from a third-party source (https://hermes-agent.nousresearch.com/)."
msg_warn "The following code is NOT maintained or audited by our repository."
msg_warn "If you have any doubts or concerns, please review the installer code before proceeding:"
msg_custom "${TAB3}${GATEWAY}${BGN}${CL}" "\e[1;34m" "→  https://hermes-agent.nousresearch.com/install.sh"
echo
read -r -p "${TAB3}Do you want to continue? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  msg_error "Aborted by user. No changes have been made."
  exit 10
fi

msg_info "Installing Hermes Agent"
$STD setsid --wait bash -c '
  set -a; source /etc/default/hermes; set +a
  bash <(curl -fsSL https://hermes-agent.nousresearch.com/install.sh) --skip-setup --hermes-home /home/hermes/.hermes --dir /home/hermes/.hermes/hermes-agent
'
chown -R hermes:hermes /home/hermes
chmod 750 /home/hermes
chmod 700 /home/hermes/.hermes
git config --system --add safe.directory /home/hermes/.hermes/hermes-agent 2>/dev/null || true
msg_ok "Installed Hermes Agent"

msg_info "Configuring API Server"
API_SERVER_KEY=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-32)
mkdir -p /home/hermes/.hermes
cat <<EOF >/home/hermes/.hermes/.env
API_SERVER_ENABLED=true
API_SERVER_HOST=0.0.0.0
API_SERVER_PORT=8642
API_SERVER_KEY=${API_SERVER_KEY}
EOF
chmod 600 /home/hermes/.hermes/.env
msg_ok "Configured API Server"

msg_info "Creating Dashboard Service"
cat <<EOF >/etc/systemd/system/hermes-dashboard.service
[Unit]
Description=Hermes Agent Web Dashboard
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=hermes
Group=hermes
UMask=0077
WorkingDirectory=/home/hermes
ExecStart=/home/hermes/.local/bin/hermes dashboard --host 127.0.0.1 --port 9119 --no-open
EnvironmentFile=/etc/default/hermes
Restart=on-failure
RestartSec=5
ProtectProc=invisible
ProcSubset=pid

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now hermes-dashboard
msg_ok "Created Dashboard Service"

msg_info "Creating Setup Helper"
cat <<'SETUP' >/usr/bin/hermes-setup
#!/usr/bin/env bash
set -a; source /etc/default/hermes; set +a
/home/hermes/.local/bin/hermes setup
chown -R hermes:hermes /home/hermes
chmod 750 /home/hermes
chmod 700 /home/hermes/.hermes
if [[ -f /home/hermes/.config/systemd/user/hermes-gateway.service ]]; then
  su - hermes -c 'systemctl --user enable --now hermes-gateway'
fi
echo "Hermes setup complete. File permissions restored."
SETUP
chmod +x /usr/bin/hermes-setup
msg_ok "Created Setup Helper"

msg_info "Configuring Login Hints"
cat <<'HINT' >/etc/profile.d/hermes-hint.sh
if [[ "$(id -u)" -eq 0 ]]; then
  echo "  Run 'hermes-setup' to configure your model provider and gateway server."
  echo "  Use 'su - hermes' (with the dash) to switch to the hermes user."
fi
HINT
msg_ok "Configured Login Hints"

motd_ssh
customize
cleanup_lxc
