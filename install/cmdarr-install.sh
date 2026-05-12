#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: cjarvis
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/DeviantEng/Cmdarr
# Description: Installs Cmdarr, a modular music automation platform for self-hosted media workflows

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  ca-certificates \
  gnupg
msg_ok "Installed Dependencies"

msg_info "Installing Node.js"
NODE_VERSION="24" setup_nodejs
msg_ok "Installed Node.js"

msg_info "Installing uv and Python 3.14"
$STD curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 sh
export PATH="/root/.local/bin:$PATH"
export UV_PYTHON_INSTALL_DIR="/opt/uv-python"
$STD uv python install 3.14
chmod -R 755 /opt/uv-python
msg_ok "Installed Python 3.14"

msg_info "Installing ${APP}"
useradd -r -s /usr/sbin/nologin cmdarr
RELEASE=$(curl -sL https://api.github.com/repos/DeviantEng/Cmdarr/tags | python3 -c "import json,sys;d=json.load(sys.stdin);print(d[0]['name'] if d else '')")
if [[ -z "${RELEASE}" ]]; then
  msg_error "Failed to fetch latest version (GitHub API rate limit?)"
  exit 1
fi
mkdir -p /opt/cmdarr
$STD curl -fsSL "https://github.com/DeviantEng/Cmdarr/archive/refs/tags/${RELEASE}.tar.gz" -o /tmp/cmdarr.tar.gz
tar -xzf /tmp/cmdarr.tar.gz --strip-components=1 -C /opt/cmdarr
rm -f /tmp/cmdarr.tar.gz
cd /opt/cmdarr || exit
$STD uv venv --python 3.14 .venv
$STD uv pip install --python .venv/bin/python -r requirements.txt
cd frontend && $STD npm ci && $STD npm run build && cd ..
mkdir -p /opt/cmdarr/data
echo "${RELEASE}" >/opt/cmdarr_version.txt
chown -R cmdarr:cmdarr /opt/cmdarr
msg_ok "Installed ${APP} ${RELEASE}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/cmdarr.service
[Unit]
Description=Cmdarr - Music Automation Platform
After=network.target

[Service]
Type=simple
User=cmdarr
Group=cmdarr
WorkingDirectory=/opt/cmdarr
ExecStart=/opt/cmdarr/.venv/bin/python run_fastapi.py
Restart=on-failure
TimeoutStopSec=320
EnvironmentFile=-/opt/cmdarr/.env

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now cmdarr
msg_ok "Created Service"

msg_info "Cleaning up"
$STD npm cache clean --force
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize
cleanup_lxc
