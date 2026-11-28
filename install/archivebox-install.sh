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
$STD apt install -y \
  libatomic1 \
  chromium
msg_ok "Installed Dependencies"

export UV_PYTHON_INSTALL_DIR="/opt/archivebox/python"
PYTHON_VERSION="3.13" setup_uv

msg_info "Installing ArchiveBox"
ARCHIVEBOX_VERSION="${var_appversion:-$(get_latest_github_release "ArchiveBox/ArchiveBox")}"
mkdir -p /opt/archivebox/data
$STD uv venv --python 3.13 /opt/archivebox/.venv
$STD uv pip install --python /opt/archivebox/.venv/bin/python "archivebox==${ARCHIVEBOX_VERSION#v}"
ln -sf /opt/archivebox/.venv/bin/archivebox /usr/local/bin/archivebox
cat <<EOF >~/.archivebox
${ARCHIVEBOX_VERSION#v}
EOF
msg_ok "Installed ArchiveBox"

msg_info "Initializing ArchiveBox"
cd /opt/archivebox/data
$STD archivebox init
ADMIN_PASS=$(random_password 20)
DJANGO_SUPERUSER_USERNAME=archivebox DJANGO_SUPERUSER_EMAIL=archivebox@archivebox.local DJANGO_SUPERUSER_PASSWORD="$ADMIN_PASS" $STD archivebox manage createsuperuser --noinput
$STD archivebox config --set "BASE_URL=http://${LOCAL_IP}:8000"
cat <<EOF >~/archivebox.creds
ArchiveBox Credentials
Username: archivebox
Password: ${ADMIN_PASS}
EOF
msg_ok "Initialized ArchiveBox"

msg_info "Installing ArchiveBox Extractors"
# 0.9.77 counts page cache as used memory under a cgroup limit and refuses to run (ArchiveBox#1966)
echo 1G 2>/dev/null >/sys/fs/cgroup/memory.reclaim || true
$STD archivebox install
msg_ok "Installed ArchiveBox Extractors"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/archivebox.service
[Unit]
Description=ArchiveBox Server
After=network.target

[Service]
WorkingDirectory=/opt/archivebox/data
ExecStartPre=-/bin/sh -c "echo 1G 2>/dev/null >/sys/fs/cgroup/memory.reclaim"
ExecStart=/opt/archivebox/.venv/bin/archivebox server 0.0.0.0:8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now archivebox
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
