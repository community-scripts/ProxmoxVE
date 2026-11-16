#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: dkuku
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/livebook-dev/livebook

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
  ca-certificates \
  cmake \
  git \
  libncurses5-dev
msg_ok "Installed Dependencies"

msg_info "Creating livebook user"
mkdir -p /opt/livebook /data
export HOME=/opt/livebook
$STD adduser --system --group --home /opt/livebook --shell /bin/bash livebook
msg_ok "Created livebook user"

confirm_external_installer "https://elixir-lang.org" "https://elixir-lang.org/install.sh"
curl -fsSO https://elixir-lang.org/install.sh
$STD sh install.sh elixir@latest otp@latest

msg_info "Setup Erlang and Elixir"
ERLANG_VERSION=$(ls /opt/livebook/.elixir-install/installs/otp/ | head -n1)
ELIXIR_VERSION=$(ls /opt/livebook/.elixir-install/installs/elixir/ | head -n1)
LIVEBOOK_PASSWORD=$(random_password 16)

export ERLANG_BIN="/opt/livebook/.elixir-install/installs/otp/$ERLANG_VERSION/bin"
export ELIXIR_BIN="/opt/livebook/.elixir-install/installs/elixir/$ELIXIR_VERSION/bin"
export PATH="$ERLANG_BIN:$ELIXIR_BIN:$PATH"

$STD mix local.hex --force
$STD mix local.rebar --force
$STD mix escript.install hex livebook --force

cat <<EOF >/opt/livebook/.env
export HOME=/opt/livebook
export ERLANG_VERSION=$ERLANG_VERSION
export ELIXIR_VERSION=$ELIXIR_VERSION
export LIVEBOOK_PORT=8080
export LIVEBOOK_IP="::"
export LIVEBOOK_HOME=/data
export LIVEBOOK_PASSWORD="$LIVEBOOK_PASSWORD"
export ESCRIPTS_BIN=/opt/livebook/.mix/escripts
export ERLANG_BIN="/opt/livebook/.elixir-install/installs/otp/\${ERLANG_VERSION}/bin"
export ELIXIR_BIN="/opt/livebook/.elixir-install/installs/elixir/\${ELIXIR_VERSION}/bin"
export PATH="\$ESCRIPTS_BIN:\$ERLANG_BIN:\$ELIXIR_BIN:\$PATH"
EOF
cat <<EOF >~/livebook.creds
Livebook-Credentials
Livebook Password: $LIVEBOOK_PASSWORD
EOF
msg_ok "Installed Erlang $ERLANG_VERSION and Elixir $ELIXIR_VERSION"

msg_info "Installing Livebook"
cat <<EOF >/etc/systemd/system/livebook.service
[Unit]
Description=Livebook
After=network.target

[Service]
Type=exec
User=livebook
Group=livebook
WorkingDirectory=/data
EnvironmentFile=-/opt/livebook/.env
ExecStart=/bin/bash -c 'source /opt/livebook/.env && cd /opt/livebook && livebook server'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
chown -R livebook:livebook /opt/livebook /data
systemctl enable -q --now livebook
msg_ok "Installed Livebook"

motd_ssh
customize
cleanup_lxc
