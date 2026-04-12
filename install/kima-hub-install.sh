#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Chevron7Locked/kima-hub

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  build-essential \
  git \
  openssl \
  ffmpeg \
  python3 \
  python3-pip \
  python3-dev \
  python3-numpy \
  redis-server
msg_ok "Installed Dependencies"

PG_VERSION="16" PG_MODULES="pgvector" setup_postgresql
PG_DB_NAME="kima" PG_DB_USER="kima" PG_DB_GRANT_SUPERUSER="true" setup_postgresql_db
NODE_VERSION="20" setup_nodejs

msg_info "Configuring Redis"
systemctl enable -q --now redis-server
msg_ok "Configured Redis"

fetch_and_deploy_gh_release "kima-hub" "Chevron7Locked/kima-hub" "tarball"

msg_info "Installing Python Dependencies"
export PIP_BREAK_SYSTEM_PACKAGES=1
$STD pip3 install --no-cache-dir \
  tensorflow \
  essentia-tensorflow \
  redis \
  psycopg2-binary \
  laion-clap \
  torch \
  torchaudio \
  librosa \
  transformers \
  pgvector \
  python-dotenv \
  requests
msg_ok "Installed Python Dependencies"

msg_info "Downloading Essentia ML Models"
mkdir -p /opt/kima-hub/models
cd /opt/kima-hub/models
curl -fsSL -o msd-musicnn-1.pb "https://essentia.upf.edu/models/autotagging/msd/msd-musicnn-1.pb"
curl -fsSL -o mood_happy-msd-musicnn-1.pb "https://essentia.upf.edu/models/classification-heads/mood_happy/mood_happy-msd-musicnn-1.pb"
curl -fsSL -o mood_sad-msd-musicnn-1.pb "https://essentia.upf.edu/models/classification-heads/mood_sad/mood_sad-msd-musicnn-1.pb"
curl -fsSL -o mood_relaxed-msd-musicnn-1.pb "https://essentia.upf.edu/models/classification-heads/mood_relaxed/mood_relaxed-msd-musicnn-1.pb"
curl -fsSL -o mood_aggressive-msd-musicnn-1.pb "https://essentia.upf.edu/models/classification-heads/mood_aggressive/mood_aggressive-msd-musicnn-1.pb"
curl -fsSL -o mood_party-msd-musicnn-1.pb "https://essentia.upf.edu/models/classification-heads/mood_party/mood_party-msd-musicnn-1.pb"
curl -fsSL -o mood_acoustic-msd-musicnn-1.pb "https://essentia.upf.edu/models/classification-heads/mood_acoustic/mood_acoustic-msd-musicnn-1.pb"
curl -fsSL -o mood_electronic-msd-musicnn-1.pb "https://essentia.upf.edu/models/classification-heads/mood_electronic/mood_electronic-msd-musicnn-1.pb"
curl -fsSL -o danceability-msd-musicnn-1.pb "https://essentia.upf.edu/models/classification-heads/danceability/danceability-msd-musicnn-1.pb"
curl -fsSL -o voice_instrumental-msd-musicnn-1.pb "https://essentia.upf.edu/models/classification-heads/voice_instrumental/voice_instrumental-msd-musicnn-1.pb"
msg_ok "Downloaded Essentia ML Models"

msg_info "Downloading CLAP Model"
curl -fsSL -o /opt/kima-hub/models/music_audioset_epoch_15_esc_90.14.pt "https://huggingface.co/lukewys/laion_clap/resolve/main/music_audioset_epoch_15_esc_90.14.pt"
msg_ok "Downloaded CLAP Model"

msg_info "Building Backend"
cd /opt/kima-hub/backend
$STD npm ci
$STD npm run build
msg_ok "Built Backend"

msg_info "Configuring Backend"
SESSION_SECRET=$(openssl rand -hex 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
cat <<EOF >/opt/kima-hub/backend/.env
NODE_ENV=production
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}
REDIS_URL=redis://localhost:6379
PORT=3006
MUSIC_PATH=/music
TRANSCODE_CACHE_PATH=/opt/kima-hub/cache/transcodes
SESSION_SECRET=${SESSION_SECRET}
SETTINGS_ENCRYPTION_KEY=${ENCRYPTION_KEY}
INTERNAL_API_SECRET=$(openssl rand -hex 16)
EOF
msg_ok "Configured Backend"

msg_info "Running Database Migrations"
cd /opt/kima-hub/backend
$STD npx prisma generate
$STD npx prisma migrate deploy
msg_ok "Ran Database Migrations"

msg_info "Building Frontend"
cd /opt/kima-hub/frontend
$STD npm ci
export NEXT_PUBLIC_BACKEND_URL=http://127.0.0.1:3006
$STD npm run build
msg_ok "Built Frontend"

msg_info "Configuring Frontend"
cat <<EOF >/opt/kima-hub/frontend/.env
NODE_ENV=production
BACKEND_URL=http://localhost:3006
PORT=3030
EOF
msg_ok "Configured Frontend"

msg_info "Creating Directories"
mkdir -p /opt/kima-hub/cache/transcodes
mkdir -p /music
msg_ok "Created Directories"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/kima-backend.service
[Unit]
Description=Kima Hub Backend
After=network.target postgresql.service redis-server.service
Wants=postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/kima-hub/backend
EnvironmentFile=/opt/kima-hub/backend/.env
ExecStart=/usr/bin/node /opt/kima-hub/backend/dist/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/kima-frontend.service
[Unit]
Description=Kima Hub Frontend
After=network.target kima-backend.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/kima-hub/frontend
EnvironmentFile=/opt/kima-hub/frontend/.env
ExecStart=/usr/bin/npm start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/kima-analyzer.service
[Unit]
Description=Kima Hub Audio Analyzer (Essentia)
After=network.target postgresql.service redis-server.service kima-backend.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/kima-hub/services/audio-analyzer
Environment=DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}
Environment=REDIS_URL=redis://localhost:6379
Environment=MUSIC_PATH=/music
Environment=BATCH_SIZE=10
Environment=SLEEP_INTERVAL=5
Environment=NUM_WORKERS=2
Environment=THREADS_PER_WORKER=1
ExecStart=/usr/bin/python3 /opt/kima-hub/services/audio-analyzer/analyzer.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/kima-analyzer-clap.service
[Unit]
Description=Kima Hub CLAP Audio Analyzer
After=network.target postgresql.service redis-server.service kima-backend.service kima-analyzer.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/kima-hub/services/audio-analyzer-clap
Environment=DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}
Environment=REDIS_URL=redis://localhost:6379
Environment=BACKEND_URL=http://localhost:3006
Environment=MUSIC_PATH=/music
Environment=SLEEP_INTERVAL=5
Environment=NUM_WORKERS=1
ExecStart=/usr/bin/python3 /opt/kima-hub/services/audio-analyzer-clap/analyzer.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now kima-backend kima-frontend kima-analyzer kima-analyzer-clap
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
