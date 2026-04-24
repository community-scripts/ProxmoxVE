#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ShaneIsrael/fireshare

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os
setup_hwaccel

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  build-essential \
  cmake \
  pkg-config \
  yasm \
  nasm \
  libx264-dev \
  libx265-dev \
  libvpx-dev \
  libaom-dev \
  libopus-dev \
  libvorbis-dev \
  libass-dev \
  libfreetype6-dev \
  libmp3lame-dev \
  nginx-extras \
  supervisor \
  libldap2-dev \
  libsasl2-dev \
  libssl-dev \
  libffi-dev \
  libc-dev
msg_ok "Installed Dependencies"

NODE_VERSION=24 setup_nodejs
PYTHON_VERSION=3.14 setup_uv

fetch_and_deploy_gh_release "fireshare" "ShaneIsrael/fireshare" "tarball"

msg_info "Compiling SVT-AV1 (Patience)"
cd /tmp
$STD git clone --depth 1 --branch v1.8.0 https://gitlab.com/AOMediaCodec/SVT-AV1.git
cd SVT-AV1/Build
$STD cmake .. -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release
$STD make -j$(nproc)
$STD make install
msg_ok "Compiled SVT-AV1"

msg_info "Installing NVDEC headers"
cd /tmp
$STD git clone --depth 1 --branch n12.1.14.0 https://github.com/FFmpeg/nv-codec-headers.git
cd nv-codec-headers
$STD make install
$STD ldconfig
msg_ok "Installed NVDEC headers"

msg_info "Compiling ffmpeg (Patience)"
cd /tmp
curl -fsSL https://ffmpeg.org/releases/ffmpeg-6.1.tar.xz -o "ffmpeg-6.1.tar.xz"
$STD tar -xf ffmpeg-6.1.tar.xz
cd ffmpeg-6.1
$STD ./configure \
  --prefix=/usr/local \
  --enable-gpl \
  --enable-version3 \
  --enable-nonfree \
  --enable-ffnvcodec \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx \
  --enable-libaom \
  --enable-libopus \
  --enable-libvorbis \
  --enable-libmp3lame \
  --enable-libass \
  --enable-libfreetype \
  --enable-libsvtav1 \
  --disable-debug \
  --disable-doc
$STD make -j$(nproc)
$STD make install
$STD ldconfig
msg_ok "Compiled ffmpeg"

msg_info "Configuring Fireshare (Patience)"
ADMIN_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
SECRET=$(openssl rand -base64 48)
mkdir -p /opt/fireshare-{data,videos,images,processed}
cd /opt/fireshare
$STD uv venv
$STD .venv/bin/python -m ensurepip --upgrade
$STD .venv/bin/python -m pip install --upgrade --break-system-packages pip
ln -sf /usr/local/bin/ffmpeg /usr/bin/ffmpeg
ln -sf /usr/local/bin/ffprobe /usr/bin/ffprobe
echo "/usr/local/lib" >/etc/ld.so.conf.d/usr-local.conf
echo "/usr/local/cuda/lib64" >>/etc/ld.so.conf.d/usr-local.conf
echo "/usr/local/nvidia/lib" >>/etc/ld.so.conf.d/nvidia.conf
echo "/usr/local/nvidia/lib64" >>/etc/ld.so.conf.d/nvidia.conf
ldconfig
$STD .venv/bin/python -m pip install --no-cache-dir --break-system-packages --ignore-installed app/server
cp .venv/bin/fireshare /usr/local/bin/fireshare
export FLASK_APP="/opt/fireshare/app/server/fireshare:create_app()"
export DATA_DIRECTORY=/opt/fireshare-data
export IMAGE_DIRECTORY=/opt/fireshare-images
export VIDEO_DIRECTORY=/opt/fireshare-videos
export PROCESSED_DIRECTORY=/opt/fireshare-processed
$STD uv run flask db upgrade

cat <<EOF >/opt/fireshare/fireshare.env
FLASK_APP="/opt/fireshare/app/server/fireshare:create_app()"
DOMAIN=
ENVIRONMENT=production
DATA_DIRECTORY=/opt/fireshare-data
IMAGE_DIRECTORY=/opt/fireshare-images
VIDEO_DIRECTORY=/opt/fireshare-videos
PROCESSED_DIRECTORY=/opt/fireshare-processed
TEMPLATE_PATH=/opt/fireshare/app/server/fireshare/templates
SECRET_KEY=${SECRET}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
TZ=UTC
LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/lib:/usr/local/cuda/lib64:\$LD_LIBRARY_PATH
PATH=/usr/local/bin:$PATH
ENABLE_TRANSCODING=
TRANSCODE_GPU=
NVIDIA_DRIVER_CAPABILITIES=
EOF

cd /opt/fireshare/app/client
$STD npm install
$STD npm run build
systemctl stop nginx
cp /opt/fireshare/app/nginx/prod.conf /etc/nginx/nginx.conf
sed -i 's|root /processed/|root /opt/fireshare-processed/|g' /etc/nginx/nginx.conf
sed -i 's/^user[[:space:]]\+nginx;/user  root;/' /etc/nginx/nginx.conf
sed -i 's|root[[:space:]]\+/app/build;|root /opt/fireshare/app/client/build;|' /etc/nginx/nginx.conf
systemctl start nginx

cat <<EOF >~/fireshare.creds
Fireshare Admin Credentials
========================
Username: admin
Password: ${ADMIN_PASSWORD}
EOF
msg_ok "Configured Fireshare"

msg_info "Creating services"
cat <<EOF >/etc/systemd/system/fireshare.service
[Unit]
Description=Fireshare Service
After=network.target

[Service]
WorkingDirectory=/opt/fireshare/app/server
ExecStart=/opt/fireshare/.venv/bin/gunicorn --bind=127.0.0.1:5000 "fireshare:create_app(init_schedule=True)" --workers 3 --threads 3 --preload
Restart=always
EnvironmentFile=/opt/fireshare/fireshare.env

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now fireshare
msg_ok "Created services"

motd_ssh
customize
cleanup_lxc
