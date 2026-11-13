#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MrNRod
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Viren070/AIOStreams | Docs: https://docs.aiostreams.viren070.me/

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
  python3 \
  libmimalloc3
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "aiostreams" "Viren070/AIOStreams" "tarball" "latest" "" "" "v"
AIOSTREAMS_TAG="v$(cat ~/.aiostreams)"

PNPM_VERSION=$(sed -n 's/.*"packageManager": "pnpm@\([^"+]*\).*/\1/p' /opt/aiostreams/package.json)
NODE_VERSION="24" NODE_MODULE="pnpm@${PNPM_VERSION:-11.0.8}" setup_nodejs

msg_info "Configuring Application"
mkdir -p /opt/aiostreams_data
cp /opt/aiostreams/.env.sample /opt/aiostreams_data/.env
SECRET_KEY=$(openssl rand -hex 32)
sed -i \
  -e "s|^BASE_URL=.*|BASE_URL=http://${LOCAL_IP}:3000|" \
  -e "s|^SECRET_KEY=.*|SECRET_KEY=${SECRET_KEY}|" \
  -e "s|^# PORT=3000|PORT=3000|" \
  -e "s|^DATABASE_URI=sqlite://./data/db.sqlite|DATABASE_URI=sqlite:///opt/aiostreams_data/db.sqlite|" \
  /opt/aiostreams_data/.env
msg_ok "Configured Application"

msg_info "Building AIOStreams (Patience)"
cd /opt/aiostreams
export NODE_OPTIONS="--max-old-space-size=3072"
$STD pnpm install --frozen-lockfile
$STD pnpm run build
unset NODE_OPTIONS
cp -r /opt/aiostreams/packages/server/src/static /opt/aiostreams/packages/server/dist/static
msg_ok "Built AIOStreams"

msg_info "Generating Version Metadata"
mkdir -p /opt/aiostreams/resources
AIOSTREAMS_VERSION=$(jq -r '.version' /opt/aiostreams/package.json)
AIOSTREAMS_DESC=$(jq -r '.description' /opt/aiostreams/package.json)
AIOSTREAMS_COMMIT_INFO=$(curl -fsSL "https://api.github.com/repos/Viren070/AIOStreams/commits/${AIOSTREAMS_TAG}" 2>/dev/null)
AIOSTREAMS_COMMIT=$(jq -r '.sha // empty' <<<"${AIOSTREAMS_COMMIT_INFO}")
AIOSTREAMS_COMMIT=$(jq -r '.sha[0:8] // empty' <<<"${AIOSTREAMS_COMMIT_INFO}")
cat <<EOF >/opt/aiostreams/resources/metadata.json
{
  "version": "${AIOSTREAMS_VERSION}",
  "description": $(jq -Rn --arg d "${AIOSTREAMS_DESC}" '$d'),
  "tag": "${AIOSTREAMS_TAG}",
  "channel": "stable",
  "commitHash": "${AIOSTREAMS_COMMIT:-unknown}",
  "buildTime": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
  "commitTime": "${AIOSTREAMS_COMMIT_TIME:-$(date -u +%Y-%m-%dT%H:%M:%S.000Z)}"
}
EOF
msg_ok "Generated Version Metadata"

msg_info "Creating Service"
MIMALLOC_LIB=$(dpkg -L libmimalloc3 | grep -E '/libmimalloc\.so\.[0-9]+$' | head -1)
cat <<EOF >/etc/systemd/system/aiostreams.service
[Unit]
Description=AIOStreams
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/aiostreams
EnvironmentFile=/opt/aiostreams_data/.env
Environment="NODE_OPTIONS=--max-semi-space-size=8 --expose-gc"
Environment="LD_PRELOAD=${MIMALLOC_LIB}"
ExecStart=/usr/bin/node /opt/aiostreams/packages/server/dist/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now aiostreams
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
