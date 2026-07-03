#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: nnsense
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/kieraneglin/pinchflat

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
  elixir \
  erlang-dev \
  erlang-inets \
  erlang-os-mon \
  erlang-runtime-tools \
  erlang-syntax-tools \
  erlang-xmerl \
  git \
  libsqlite3-dev \
  locales \
  openssh-client \
  openssl \
  pipx \
  pkg-config \
  procps \
  python3-mutagen \
  zip
msg_ok "Installed Dependencies"

NODE_VERSION="24" NODE_MODULE="yarn" setup_nodejs
FFMPEG_TYPE="binary" setup_ffmpeg
setup_hwaccel
fetch_and_deploy_gh_release "deno" "denoland/deno" "prebuild" "latest" "/usr/local/bin" "deno-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.zip"
fetch_and_deploy_gh_release "yt-dlp" "yt-dlp/yt-dlp" "singlefile" "latest" "/usr/local/bin" "yt-dlp_$(arch_resolve "linux" "linux_aarch64")"

msg_info "Installing Apprise"
export PIPX_HOME=/opt/pipx
export PIPX_BIN_DIR=/usr/local/bin
$STD pipx install apprise
msg_ok "Installed Apprise"

fetch_and_deploy_gh_release "pinchflat" "kieraneglin/pinchflat" "tarball" "latest" "/opt/pinchflat-src"

msg_info "Configuring Pinchflat"
CONFIG_PATH="/opt/pinchflat/config"
DOWNLOADS_PATH="/opt/pinchflat/downloads"
mkdir -p \
  /etc/elixir_tzdata_data \
  /etc/yt-dlp/plugins \
  /opt/pinchflat/app \
  "$CONFIG_PATH/db" \
  "$CONFIG_PATH/extras" \
  "$CONFIG_PATH/logs" \
  "$CONFIG_PATH/metadata" \
  "$DOWNLOADS_PATH"
ln -sfn "$CONFIG_PATH" /config
ln -sfn "$DOWNLOADS_PATH" /downloads
chmod ugo+rw /etc/elixir_tzdata_data /etc/yt-dlp /etc/yt-dlp/plugins

cat <<EOF >/opt/pinchflat/.env
LANG=en_US.UTF-8
LANGUAGE=en_US:en
LC_ALL=en_US.UTF-8
MIX_ENV=prod
PHX_SERVER=true
PORT=8945
RUN_CONTEXT=selfhosted
CONFIG_PATH=${CONFIG_PATH}
MEDIA_PATH=${DOWNLOADS_PATH}
TZ_DATA_PATH=/etc/elixir_tzdata_data
SECRET_KEY_BASE=$(openssl rand -base64 48)
EOF
msg_ok "Configured Pinchflat"

msg_info "Building Pinchflat"
cd /opt/pinchflat-src
export MIX_ENV=prod
export ERL_FLAGS="+JPperf true"
$STD mix local.hex --force
$STD mix local.rebar --force
$STD mix deps.get --only prod
$STD mix deps.compile
$STD yarn --cwd assets install
$STD mix assets.deploy
$STD mix compile
$STD mix release --overwrite
rm -rf /opt/pinchflat/app
cp -r _build/prod/rel/pinchflat /opt/pinchflat/app
msg_ok "Built Pinchflat"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/pinchflat.service
[Unit]
Description=Pinchflat
After=network.target

[Service]
Type=simple
EnvironmentFile=/opt/pinchflat/.env
WorkingDirectory=/opt/pinchflat/app
UMask=0022
ExecStartPre=/opt/pinchflat/app/bin/check_file_permissions
ExecStartPre=/opt/pinchflat/app/bin/migrate
ExecStart=/opt/pinchflat/app/bin/pinchflat start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now pinchflat
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
