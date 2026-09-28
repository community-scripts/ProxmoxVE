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
  procps \
  dnsutils \
  python3.13
msg_ok "Installed Dependencies"

setup_uv

msg_info "Installing ArchiveBox"
mkdir -p /opt/archivebox/data
$STD adduser --system --shell /bin/bash --gecos 'Archive Box User' --group --disabled-password --home /home/archivebox archivebox
$STD uv venv --python /usr/bin/python3.13 /opt/archivebox/venv
$STD uv pip install --python /opt/archivebox/venv/bin/python archivebox
ln -sf /opt/archivebox/venv/bin/archivebox /usr/local/bin/archivebox
mkdir -p /home/archivebox/.config
chown -R archivebox:archivebox /opt/archivebox /home/archivebox
msg_ok "Installed ArchiveBox"

msg_info "Initializing ArchiveBox"
cd /opt/archivebox/data
$STD sudo -u archivebox /opt/archivebox/venv/bin/archivebox init
$STD sudo -u archivebox env \
  DJANGO_SUPERUSER_USERNAME=archivebox \
  DJANGO_SUPERUSER_EMAIL=archivebox@archivebox.local \
  DJANGO_SUPERUSER_PASSWORD=community-scripts.org \
  /opt/archivebox/venv/bin/archivebox manage createsuperuser --noinput
$STD sudo -u archivebox /opt/archivebox/venv/bin/archivebox config --set "BASE_URL=http://$(get_ip):5797" MERCURY_ENABLED=False
msg_ok "Initialized ArchiveBox"

msg_info "Installing Extractors (Patience)"
AB_RUNTIME="/tmp/archivebox-runtime-$(id -u archivebox)"
install -d -m 700 -o archivebox -g archivebox "$AB_RUNTIME"
$STD env HOME=/home/archivebox USER=archivebox LOGNAME=archivebox XDG_CONFIG_HOME=/home/archivebox/.config XDG_RUNTIME_DIR="$AB_RUNTIME" \
  /opt/archivebox/venv/bin/archivebox install
msg_ok "Installed Extractors"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/archivebox.service
[Unit]
Description=ArchiveBox Server
After=network.target

[Service]
User=archivebox
WorkingDirectory=/opt/archivebox/data
ExecStartPre=/opt/archivebox/venv/bin/archivebox init
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
