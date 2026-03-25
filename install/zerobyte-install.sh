#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: community-scripts
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/nicotsx/zerobyte

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
echo "davfs2 davfs2/suid_file boolean false" | debconf-set-selections
$STD apt-get install -y \
  bzip2 \
  fuse3 \
  sshfs \
  davfs2 \
  openssh-client
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "restic" "restic/restic" "singlefile" "latest" "/usr/local/bin" "restic_*_linux_amd64.bz2"
mv /usr/local/bin/restic /usr/local/bin/restic.bz2
bzip2 -d /usr/local/bin/restic.bz2
chmod +x /usr/local/bin/restic

fetch_and_deploy_gh_release "rclone" "rclone/rclone" "prebuild" "latest" "/opt/rclone" "rclone-*-linux-amd64.zip"
ln -sf /opt/rclone/rclone /usr/local/bin/rclone

fetch_and_deploy_gh_release "shoutrrr" "nicholas-fedor/shoutrrr" "prebuild" "latest" "/opt/shoutrrr" "shoutrrr_linux_amd64_*.tar.gz"
ln -sf /opt/shoutrrr/shoutrrr /usr/local/bin/shoutrrr

msg_info "Installing Bun"
export BUN_INSTALL="/root/.bun"
curl -fsSL https://bun.sh/install | $STD bash
ln -sf /root/.bun/bin/bun /usr/local/bin/bun
ln -sf /root/.bun/bin/bunx /usr/local/bin/bunx
msg_ok "Installed Bun"

NODE_VERSION="24" setup_nodejs
fetch_and_deploy_gh_release "zerobyte" "nicotsx/zerobyte" "tarball"

msg_info "Building Zerobyte (Patience)"
cd /opt/zerobyte
export VITE_RESTIC_VERSION=$(cat ~/.restic)
export VITE_RCLONE_VERSION=$(cat ~/.rclone)
export VITE_SHOUTRRR_VERSION=$(cat ~/.shoutrrr)
export NODE_OPTIONS="--max-old-space-size=3072"
$STD bun install
$STD node ./node_modules/vite/bin/vite.js build
msg_ok "Built Zerobyte"

msg_info "Configuring Zerobyte"
mkdir -p /var/lib/zerobyte/{data,restic/cache,repositories,volumes}
APP_SECRET=$(openssl rand -hex 32)
cat <<EOF >/opt/zerobyte/.env
BASE_URL=http://${LOCAL_IP}:4096
APP_SECRET=${APP_SECRET}
PORT=4096
ZEROBYTE_DATABASE_URL=/var/lib/zerobyte/data/zerobyte.db
RESTIC_CACHE_DIR=/var/lib/zerobyte/restic/cache
ZEROBYTE_REPOSITORIES_DIR=/var/lib/zerobyte/repositories
ZEROBYTE_VOLUMES_DIR=/var/lib/zerobyte/volumes
MIGRATIONS_PATH=/opt/zerobyte/app/drizzle
NODE_ENV=production
EOF
msg_ok "Configured Zerobyte"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/zerobyte.service
[Unit]
Description=Zerobyte Backup Automation
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/zerobyte
EnvironmentFile=/opt/zerobyte/.env
ExecStart=/usr/local/bin/bun .output/server/index.mjs
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now zerobyte
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
