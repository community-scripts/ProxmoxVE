#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://archivebox.io/ | Github: https://github.com/ArchiveBox/ArchiveBox

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  git \
  libssl-dev \
  libldap2-dev \
  libsasl2-dev \
  procps \
  dnsutils \
  ripgrep \
  chromium
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="@postlight/parser@latest,single-file-cli@latest" setup_nodejs
# ArchiveBox drops privileges on import, so its interpreter may not sit in root's home.
export UV_PYTHON_INSTALL_DIR="/opt/archivebox/python"
PYTHON_VERSION="3.13" setup_uv

msg_info "Installing ArchiveBox"
mkdir -p /opt/archivebox/{data,.npm,.cache,.local}
$STD adduser --system --shell /bin/bash --gecos 'Archive Box User' --group --disabled-password --home /home/archivebox archivebox
# A venv, not --system: the system interpreter is 3.11 and silently caps us at 0.7.4.
$STD uv venv --python 3.13 /opt/archivebox/venv
$STD uv pip install --python /opt/archivebox/venv/bin/python archivebox playwright
$STD /opt/archivebox/venv/bin/playwright install-deps chromium
ln -sf /opt/archivebox/venv/bin/archivebox /usr/local/bin/archivebox
chown -R archivebox:archivebox /opt/archivebox
chmod -R 755 /opt/archivebox/data
msg_ok "Installed ArchiveBox"

msg_info "Initializing ArchiveBox"
cd /opt/archivebox/data
$STD sudo -u archivebox /opt/archivebox/venv/bin/archivebox init
$STD sudo -u archivebox env \
  DJANGO_SUPERUSER_USERNAME=admin \
  DJANGO_SUPERUSER_EMAIL=admin@archivebox.local \
  DJANGO_SUPERUSER_PASSWORD=community-scripts.org \
  /opt/archivebox/venv/bin/archivebox manage createsuperuser --noinput
msg_ok "Initialized ArchiveBox"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/archivebox.service
[Unit]
Description=ArchiveBox Server
After=network.target

[Service]
User=archivebox
WorkingDirectory=/opt/archivebox/data
ExecStart=/opt/archivebox/venv/bin/archivebox server 0.0.0.0:5797
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now archivebox
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
