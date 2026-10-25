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
$STD apt install -y \
  git \
  libatomic1
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Creating Hermes User"
useradd -m -s /bin/bash hermes
loginctl enable-linger hermes
echo 'export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"' >>/home/hermes/.profile
msg_ok "Created Hermes User"

msg_info "Configuring Service Environment"
cat <<EOF >/etc/default/hermes
PATH=/home/hermes/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
NODE_OPTIONS=${NODE_OPTIONS}
GATEWAY_HEALTH_URL=http://127.0.0.1:8642/health
EOF
msg_ok "Configured Service Environment"

confirm_external_installer "https://hermes-agent.nousresearch.com/" "https://hermes-agent.nousresearch.com/install.sh"

msg_info "Installing Hermes Agent"
curl_with_retry "https://hermes-agent.nousresearch.com/install.sh" /tmp/hermes-install.sh ||
  curl_with_retry "https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh" /tmp/hermes-install.sh
chmod 644 /tmp/hermes-install.sh
$STD setsid --wait runuser -l hermes -c '
  set -a; source /etc/default/hermes; set +a
  export npm_config_yes=true
  bash /tmp/hermes-install.sh --skip-setup --hermes-home ~/.hermes --dir ~/.hermes/hermes-agent
'
rm -f /tmp/hermes-install.sh
chmod 750 /home/hermes
chmod 700 /home/hermes/.hermes
msg_ok "Installed Hermes Agent"

msg_info "Configuring API Server"
API_SERVER_KEY=$(random_password 32)
cat <<EOF >/home/hermes/.hermes/.env
API_SERVER_ENABLED=true
API_SERVER_HOST=0.0.0.0
API_SERVER_PORT=8642
API_SERVER_KEY=${API_SERVER_KEY}
EOF
chown hermes:hermes /home/hermes/.hermes/.env
chmod 600 /home/hermes/.hermes/.env
msg_ok "Configured API Server"

msg_info "Creating Dashboard Service"
mkdir -p /home/hermes/.config/systemd/user
cat <<EOF >/home/hermes/.config/systemd/user/hermes-dashboard.service
[Unit]
Description=Hermes Agent Web Dashboard
After=network-online.target

[Service]
Type=simple
UMask=0077
WorkingDirectory=%h
EnvironmentFile=/etc/default/hermes
ExecStart=%h/.local/bin/hermes dashboard --host 127.0.0.1 --port 9119 --no-open
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
chown -R hermes:hermes /home/hermes/.config
$STD runuser -l hermes -c 'systemctl --user daemon-reload && systemctl --user enable --now hermes-dashboard'
msg_ok "Created Dashboard Service"

msg_info "Creating Setup Helper"
cat <<'SETUP' >/usr/bin/hermes-setup
#!/usr/bin/env bash
su - hermes -c 'set -a; source /etc/default/hermes; set +a; hermes setup'
if [[ -f /home/hermes/.config/systemd/user/hermes-gateway.service ]]; then
  su - hermes -c 'systemctl --user enable --now hermes-gateway'
fi
echo "Hermes setup complete."
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
