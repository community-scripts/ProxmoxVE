#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Dictionarry-Hub/profilarr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  unzip \
  git \
  libsqlite3-0
msg_ok "Installed Dependencies"

msg_info "Installing Deno"
DENO_VERSION=$(curl -fsSL "https://api.github.com/repos/denoland/deno/releases/latest" | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
ARCH=$(uname -m)
case "$ARCH" in
aarch64) DENO_FILE="deno-aarch64-unknown-linux-gnu.zip" ;;
*) DENO_FILE="deno-x86_64-unknown-linux-gnu.zip" ;;
esac
curl -fsSL "https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/${DENO_FILE}" -o /tmp/deno.zip
$STD unzip -qo /tmp/deno.zip -d /usr/local/bin/
rm /tmp/deno.zip
chmod +x /usr/local/bin/deno
msg_ok "Installed Deno v${DENO_VERSION}"

fetch_and_deploy_gh_release "profilarr" "Dictionarry-Hub/profilarr" "tarball"
PROFILARR_VERSION=$(curl -fsSL "https://api.github.com/repos/Dictionarry-Hub/profilarr/releases/latest" | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')

msg_info "Building Profilarr v${PROFILARR_VERSION} (Patience)"
cd /opt/profilarr
cat >src/lib/shared/build.ts <<EOF
// Generated at install time. Do not hand-edit.
export type Channel = 'stable' | 'develop' | 'dev';

export interface BuildInfo {
	readonly version: string;
	readonly channel: Channel;
	readonly commit: string | null;
	readonly builtAt: string | null;
}

export const build: BuildInfo = {
	version: '${PROFILARR_VERSION}',
	channel: 'stable',
	commit: null,
	builtAt: '$(date -u +"%Y-%m-%dT%H:%M:%SZ")'
};
EOF
$STD deno install --node-modules-dir
export APP_BASE_PATH=/opt/profilarr/dist/build
export VITE_CHANNEL=stable
$STD deno run -A npm:vite build
case "$ARCH" in
aarch64) DENO_TARGET="aarch64-unknown-linux-gnu" ;;
*) DENO_TARGET="x86_64-unknown-linux-gnu" ;;
esac
$STD deno compile \
  --no-check \
  --allow-net \
  --allow-read \
  --allow-write \
  --allow-env \
  --allow-ffi \
  --allow-run \
  --allow-sys \
  --target "$DENO_TARGET" \
  --output dist/build/profilarr \
  dist/build/mod.ts
msg_ok "Built Profilarr"

msg_info "Installing Profilarr"
mkdir -p /opt/profilarr/app
cp dist/build/profilarr /opt/profilarr/app/profilarr
cp dist/build/server.js /opt/profilarr/app/server.js
cp -r dist/build/static /opt/profilarr/app/static
chmod +x /opt/profilarr/app/profilarr
mkdir -p /var/lib/profilarr/{data,logs,backups,databases}
msg_ok "Installed Profilarr"

msg_info "Creating Service"
SQLITE_PATH="/usr/lib/${ARCH}-linux-gnu/libsqlite3.so.0"
cat <<EOF >/etc/systemd/system/profilarr.service
[Unit]
Description=Profilarr - Configuration Management for Radarr/Sonarr
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/profilarr/app
Environment="PORT=6868"
Environment="HOST=0.0.0.0"
Environment="APP_BASE_PATH=/var/lib/profilarr"
Environment="DENO_SQLITE_PATH=${SQLITE_PATH}"
ExecStart=/opt/profilarr/app/profilarr
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now profilarr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
