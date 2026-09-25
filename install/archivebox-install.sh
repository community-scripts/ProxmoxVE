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
# ArchiveBox resolves these through its env provider, so it never has to reach for apt itself.
$STD apt-get install -y \
  git \
  procps \
  dnsutils \
  chromium \
  ripgrep \
  tesseract-ocr \
  tesseract-ocr-eng \
  imagemagick \
  ffmpeg \
  unzip \
  wget \
  python3.13
msg_ok "Installed Dependencies"

# No NODE_MODULE: 0.9 pulls single-file and readability itself, and postlight-parser is gone.
NODE_VERSION="22" setup_nodejs
setup_uv

msg_info "Installing ArchiveBox"
mkdir -p /opt/archivebox/data
$STD adduser --system --shell /bin/bash --gecos 'Archive Box User' --group --disabled-password --home /home/archivebox archivebox
# The distro interpreter: a uv-managed one lands where the service user cannot execute it.
$STD uv venv --python /usr/bin/python3.13 /opt/archivebox/venv
$STD uv pip install --python /opt/archivebox/venv/bin/python archivebox
ln -sf /opt/archivebox/venv/bin/archivebox /usr/local/bin/archivebox
chown -R archivebox:archivebox /opt/archivebox
msg_ok "Installed ArchiveBox"

msg_info "Initializing ArchiveBox"
cd /opt/archivebox/data
$STD sudo -u archivebox /opt/archivebox/venv/bin/archivebox init
$STD sudo -u archivebox env \
  DJANGO_SUPERUSER_USERNAME=admin \
  DJANGO_SUPERUSER_EMAIL=admin@archivebox.local \
  DJANGO_SUPERUSER_PASSWORD=community-scripts.org \
  /opt/archivebox/venv/bin/archivebox manage createsuperuser --noinput
# Without a pinned canonical URL the admin greets every visitor with a red banner.
$STD sudo -u archivebox /opt/archivebox/venv/bin/archivebox config --set "BASE_URL=http://$(get_ip):5797"
msg_ok "Initialized ArchiveBox"

msg_info "Installing Extractors"
# One unreachable extractor must not sink the install: @postlight/parser pulls a git
# dependency that npm refuses, and readability covers the same job.
if $STD sudo -u archivebox /opt/archivebox/venv/bin/archivebox install; then
  msg_ok "Installed Extractors"
else
  msg_warn "Some extractors stayed unavailable - ArchiveBox runs without them"
fi

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
