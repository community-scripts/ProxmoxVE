#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: michelroegl-brunner | Co-Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://droppedneedle.com/ | Github: https://github.com/DroppedNeedle/DroppedNeedle

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  cmake \
  pkg-config \
  ffmpeg \
  python3
msg_ok "Installed Dependencies"

RUST_PROFILE="minimal" setup_rust
NODE_VERSION="22" NODE_MODULE="pnpm@10.33.0" setup_nodejs
fetch_and_deploy_gh_release "droppedneedle" "DroppedNeedle/DroppedNeedle" "tarball"

msg_info "Building Frontend"
cd /opt/droppedneedle/frontend
export NODE_OPTIONS="--max-old-space-size=3072"
$STD pnpm install --frozen-lockfile
DROPPEDNEEDLE_BASE_PATH_PLACEHOLDER=1 $STD pnpm run build
rm -rf node_modules
msg_ok "Built Frontend"

msg_info "Building DroppedNeedle (Patience)"
cd /opt/droppedneedle
$STD cargo build --release --locked --manifest-path server/Cargo.toml --bins -p droppedneedle -p droppedneedle-tool
cp server/target/release/droppedneedle server/target/release/droppedneedle-tool /usr/local/bin/
rm -rf server/target
mkdir -p /opt/droppedneedle/backend/{config,cache,plugins,imports}
msg_ok "Built DroppedNeedle"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/droppedneedle.service
[Unit]
Description=DroppedNeedle Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/droppedneedle/backend
Environment=ROOT_APP_DIR=/opt/droppedneedle/backend
Environment=DROPPEDNEEDLE_STATIC_DIR=/opt/droppedneedle/frontend/build
Environment=PORT=8688
Environment=COMMIT_TAG=v$(<~/.droppedneedle)
# Environment=SLSKD_DOWNLOADS_PATH=<path-to-slskd-downloads>
ExecStart=/usr/local/bin/droppedneedle
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now droppedneedle
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
