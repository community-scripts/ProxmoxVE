#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.photoprism.app/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y \
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

fetch_and_deploy_gh_release "photoprism" "photoprism/photoprism" "prebuild" "latest" "/opt/photoprism" "*linux-amd64.tar.gz"

msg_info "Installing PhotoPrism (Patience)"
mkdir -p /opt/photoprism/{cache,config,photos,storage,temp}
mkdir -p /opt/photoprism/photos/{originals,import}
mkdir -p /opt/photoprism_backups
LIBHEIF_URL=$(curl -fsSL "https://dl.photoprism.app/dist/libheif/" | grep -oP "libheif-$(lsb_release -cs)-amd64-v[0-9\.]+\.tar\.gz" | sort -V | tail -n 1)
curl -fsSL "https://dl.photoprism.app/dist/libheif/$LIBHEIF_URL" -o /tmp/libheif.tar.gz
tar -xzf /tmp/libheif.tar.gz -C /usr/local
ldconfig
echo "${LIBHEIF_URL}" >~/.photoprism_libheif
chmod -R 755 /opt/photoprism/photos/originals
cat <<EOF >/opt/photoprism/config/.env
# Authentication
PHOTOPRISM_ADMIN_USER='admin'
PHOTOPRISM_ADMIN_PASSWORD='changeme'
PHOTOPRISM_AUTH_MODE='password'
PHOTOPRISM_PUBLIC='false'

# Network / HTTP
PHOTOPRISM_HTTP_HOST='0.0.0.0'
PHOTOPRISM_HTTP_PORT='2342'
PHOTOPRISM_SITE_URL='http://localhost:2342/'
PHOTOPRISM_DISABLE_TLS='true'
PHOTOPRISM_DEFAULT_TLS='false'
PHOTOPRISM_HTTP_COMPRESSION='gzip'

# Features & AI
PHOTOPRISM_DISABLE_TENSORFLOW='false'
PHOTOPRISM_DISABLE_FACES='false'
PHOTOPRISM_DISABLE_CLASSIFICATION='false'
PHOTOPRISM_DISABLE_VECTORS='false'
PHOTOPRISM_DETECT_NSFW='false'
PHOTOPRISM_UPLOAD_NSFW='true'

# Paths & Storage
PHOTOPRISM_STORAGE_PATH='/opt/photoprism/storage'
PHOTOPRISM_ORIGINALS_PATH='/opt/photoprism/photos/originals'
PHOTOPRISM_IMPORT_PATH='/opt/photoprism/photos/import'
PHOTOPRISM_BACKUP_PATH='/opt/photoprism_backups'

# Database
PHOTOPRISM_DATABASE_DRIVER='sqlite'

# Behavior & Options
PHOTOPRISM_AUTO_INDEX='300'
PHOTOPRISM_AUTO_IMPORT='-1'
PHOTOPRISM_DISABLE_WEBDAV='false'
PHOTOPRISM_READONLY='false'
PHOTOPRISM_DISABLE_SETTINGS='false'
PHOTOPRISM_DISABLE_CHOWN='false'
PHOTOPRISM_EXPERIMENTAL='false'
PHOTOPRISM_INIT='https tensorflow'

# Image Processing
PHOTOPRISM_ORIGINALS_LIMIT='5000'
PHOTOPRISM_JPEG_QUALITY='85'
PHOTOPRISM_RAW_PRESETS='false'
PHOTOPRISM_DISABLE_RAW='false'

# Debug & Logging
PHOTOPRISM_DEBUG='false'
PHOTOPRISM_LOG_LEVEL='info'

# Site Info
PHOTOPRISM_SITE_CAPTION='https://Helper-Scripts.com'
PHOTOPRISM_SITE_DESCRIPTION=''
PHOTOPRISM_SITE_AUTHOR=''
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
