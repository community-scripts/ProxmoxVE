#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/terry90/soulbeet

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
  pkg-config \
  libssl-dev
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs
PYTHON_VERSION="3.11" setup_uv
RUST_PROFILE="minimal" setup_rust
fetch_and_deploy_gh_release "soulbeet" "terry90/soulbeet" "tarball"
# dx has to match the dioxus version Soulbeet is locked to
fetch_and_deploy_gh_release "dioxus-cli" "DioxusLabs/dioxus" "prebuild" "v$(awk -F'"' '/^name = "dioxus"$/{getline; print $2}' /opt/soulbeet/Cargo.lock)" "/usr/local/bin" "dx-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.tar.gz"

msg_info "Installing beets"
UV_TOOL_BIN_DIR=/usr/local/bin $STD uv tool install --python 3.11 --constraints /opt/soulbeet/build/requirements-beets.txt beets --with requests --with musicbrainzngs
msg_ok "Installed beets"

msg_info "Building Soulbeet (Patience)"
cd /opt/soulbeet
# Upstream drops the lockfile too: it pins Tailwind's native binding for the platform it was generated on
rm -f package-lock.json
$STD npm install
$STD npx @tailwindcss/cli -i ./web/assets/input.css -o ./web/assets/tailwind.css
# dx probes cargo +nightly only to size its progress bar; rustup would download a whole nightly toolchain for that
RUSTUP_AUTO_INSTALL=0 $STD dx bundle --package web --release
mv /opt/soulbeet/target/dx/web/release/web /opt/soulbeet/server
rm -rf /opt/soulbeet/target /opt/soulbeet/node_modules ~/.cargo/registry ~/.cargo/git ~/.npm
msg_ok "Built Soulbeet"

msg_info "Configuring Soulbeet"
mkdir -p /opt/soulbeet_data/{downloads,music,beets-plugins}
cat <<EOF >/opt/soulbeet_data/.env
DATABASE_URL=sqlite:/opt/soulbeet_data/soulbeet.db
SECRET_KEY=$(openssl rand -hex 32)
DOWNLOAD_PATH=/opt/soulbeet_data/downloads
BEETS_CONFIG=/opt/soulbeet_data/beets_config.yaml
IP=0.0.0.0
PORT=9765
#NAVIDROME_URL=http://<navidrome-ip>:4533
#BEETS_ALBUM_MODE=true
EOF
chmod 600 /opt/soulbeet_data/.env
cat <<'EOF' >/opt/soulbeet_data/beets_config.yaml
plugins: musicbrainz
pluginpath: /opt/soulbeet_data/beets-plugins
directory: /opt/soulbeet_data/music
import:
  copy: no
  move: yes
  resume: no
  duplicate_action: remove
paths:
  default: $albumartist/$album%aunique{}/$track $title
  singleton: $albumartist/$album%aunique{}/$title
match:
  strong_rec_thresh: 0.10
  max_rec:
    missing_tracks: low
musicbrainz:
  searchlimit: 20
  extra_tags: [catalognum, country, label, media, year]
EOF
msg_ok "Configured Soulbeet"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/soulbeet.service
[Unit]
Description=Soulbeet
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/soulbeet/server
EnvironmentFile=/opt/soulbeet_data/.env
ExecStart=/opt/soulbeet/server/server
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now soulbeet
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
