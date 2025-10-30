#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
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
$STD apt-get install -y \
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

msg_warn "WARNING: This script will run an external installer from a third-party source (https://elixir-lang.org)."
msg_warn "The following code is NOT maintained or audited by our repository."
msg_warn "If you have any doubts or concerns, please review the installer code before proceeding:"
msg_custom "${TAB3}${GATEWAY}${BGN}${CL}" "\e[1;34m" "→  https://elixir-lang.org/install.sh"
echo
read -r -p "${TAB3}Do you want to continue? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  msg_error "Aborted by user. No changes have been made."
  exit 10
fi
curl -fsSO https://elixir-lang.org/install.sh
$STD sh install.sh elixir@latest otp@latest

msg_info "Setup Erlang and Elixir"
ERLANG_VERSION=$(ls /opt/livebook/.elixir-install/installs/otp/ | head -n1)
ELIXIR_VERSION=$(ls /opt/livebook/.elixir-install/installs/elixir/ | head -n1)
LIVEBOOK_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c16)

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
{
  echo "Livebook-Credentials"
  echo "Livebook Password: $LIVEBOOK_PASSWORD"
} >>~/livebook.creds
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

msg_info "Cleaning Up"
$STD apt autoremove -y
$STD apt autoclean -y
$STD apt clean -y
msg_ok "Cleaned Up"
