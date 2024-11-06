#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y exiftool
$STD apt-get install -y ffmpeg
$STD apt-get install -y libheif1
$STD apt-get install -y libpng-dev
$STD apt-get install -y libjpeg-dev
$STD apt-get install -y libtiff-dev
$STD apt-get install -y imagemagick
$STD apt-get install -y darktable
$STD apt-get install -y rawtherapee
$STD apt-get install -y libvips42

echo 'export PATH=/usr/local:$PATH' >>~/.bashrc
export PATH=/usr/local:$PATH
msg_ok "Installed Dependencies"

msg_info "Installing PhotoPrism (Patience)"
mkdir -p /opt/photoprism/{cache,config,photos/originals,photos/import,storage,temp}
wget -q -cO - https://dl.photoprism.app/pkg/linux/amd64.tar.gz | tar -xz -C /opt/photoprism --strip-components=1
if [[ ${PCT_OSTYPE} == "ubuntu" ]]; then 
  wget -q -cO - https://dl.photoprism.app/dist/libheif/libheif-jammy-amd64-v1.17.1.tar.gz | tar -xzf - -C /usr/local --strip-components=1
else
  wget -q -cO - https://dl.photoprism.app/dist/libheif/libheif-bookworm-amd64-v1.17.1.tar.gz | tar -xzf - -C /usr/local --strip-components=1
fi
ldconfig
cat <<EOF >/opt/photoprism/config/.env
PHOTOPRISM_AUTH_MODE='password'
PHOTOPRISM_ADMIN_PASSWORD='changeme'
PHOTOPRISM_HTTP_HOST='0.0.0.0'
PHOTOPRISM_HTTP_PORT='2342'
PHOTOPRISM_SITE_CAPTION='https://Helper-Scripts.com'
PHOTOPRISM_STORAGE_PATH='/opt/photoprism/storage'
PHOTOPRISM_ORIGINALS_PATH='/opt/photoprism/photos/originals'
PHOTOPRISM_IMPORT_PATH='/opt/photoprism/photos/import'
EOF
ln -sf /opt/photoprism/bin/photoprism /usr/local/bin/photoprism
msg_ok "Installed PhotoPrism"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/photoprism.service
[Unit]
Description=PhotoPrism service
After=network.target

[Service]
Type=forking
User=root
WorkingDirectory=/opt/photoprism
EnvironmentFile=/opt/photoprism/config/.env
ExecStart=/opt/photoprism/bin/photoprism up -d
ExecStop=/opt/photoprism/bin/photoprism down

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now photoprism
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
