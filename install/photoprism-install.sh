#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.photoprism.app/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y \
    curl \
    sudo \
    mc \
    exiftool \
    ffmpeg \
    libheif1 \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    imagemagick \
    darktable \
    rawtherapee \
    libvips42 \
    lsb-release

echo 'export PATH=/usr/local:$PATH' >>~/.bashrc
export PATH=/usr/local:$PATH
msg_ok "Installed Dependencies"

msg_info "Installing PhotoPrism (Patience)"
mkdir -p /opt/photoprism/{cache,config,photos,storage,temp}
mkdir -p /opt/photoprism/photos/{originals,import}
mkdir -p /opt/photoprism_backups
wget -q -cO - https://dl.photoprism.app/pkg/linux/amd64.tar.gz | tar -xz -C /opt/photoprism --strip-components=1
LIBHEIF_URL=$(wget -q -O - "https://dl.photoprism.app/dist/libheif/" | grep -oP "libheif-$(lsb_release -cs)-amd64-v[0-9\.]+\.tar\.gz" | sort -V | tail -n 1)
wget -q -cO - "https://dl.photoprism.app/dist/libheif/$LIBHEIF_URL" | tar -xzf - -C /usr/local --strip-components=1
ldconfig
chmod -R 755 /opt/photoprism/photos/originals
cat <<EOF >/opt/photoprism/config/.env
PHOTOPRISM_AUTH_MODE='password'
PHOTOPRISM_ADMIN_PASSWORD='changeme'
PHOTOPRISM_HTTP_HOST='0.0.0.0'
PHOTOPRISM_HTTP_PORT='2342'
PHOTOPRISM_SITE_CAPTION='https://Helper-Scripts.com'
PHOTOPRISM_STORAGE_PATH='/opt/photoprism/storage'
PHOTOPRISM_ORIGINALS_PATH='/opt/photoprism/photos/originals'
PHOTOPRISM_IMPORT_PATH='/opt/photoprism/photos/import'
PHOTOPRISM_BACKUP_PATH='/opt/photoprism_backups'
PHOTOPRISM_DATABASE_DRIVER='sqlite'
PHOTOPRISM_DISABLE_WEBDAV='false'
PHOTOPRISM_DISABLE_FACES='false'
PHOTOPRISM_AUTO_INDEX='300'
PHOTOPRISM_AUTO_IMPORT='-1'
PHOTOPRISM_PUBLIC='false'
PHOTOPRISM_DEBUG='false'
EOF
ln -sf /opt/photoprism/bin/photoprism /usr/local/bin/photoprism

mkdir -p /etc/photoprism/
cat <<EOF >/etc/photoprism/defaults.yml
ConfigPath: "~/.config/photoprism"
StoragePath: "/opt/photoprism/storage"
OriginalsPath: "/opt/photoprism/photos/originals"
ImportPath: "/media"
AdminUser: "admin"
AdminPassword: "changeme"
AuthMode: "password"
DatabaseDriver: "sqlite"
HttpHost: "0.0.0.0"
HttpPort: 2342
HttpCompression: "gzip"
DisableTLS: false
DefaultTLS: true
Experimental: false
DisableWebDAV: false
DisableSettings: false
DisableTensorFlow: false
DisableFaces: false
DisableClassification: false
DisableVectors: false
DisableRaw: false
RawPresets: false
JpegQuality: 85
DetectNSFW: false
UploadNSFW: true
EOF
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
