#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/woodpecker-ci/woodpecker

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  git-lfs
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "woodpecker-server" "woodpecker-ci/woodpecker" "prebuild" "latest" "/opt/woodpecker" "woodpecker-server_linux_$(arch_resolve).tar.gz"
fetch_and_deploy_gh_release "woodpecker-agent" "woodpecker-ci/woodpecker" "prebuild" "latest" "/opt/woodpecker" "woodpecker-agent_linux_$(arch_resolve).tar.gz"
# The local backend clones with plugin-git from PATH; without it every workflow downloads it from the GitHub API
fetch_and_deploy_gh_release "plugin-git" "woodpecker-ci/plugin-git" "singlefile" "latest" "/usr/local/bin" "linux-$(arch_resolve)_plugin-git"

msg_info "Configuring Woodpecker CI"
mkdir -p /opt/woodpecker_data/workspaces
AGENT_SECRET=$(openssl rand -hex 32)
cat <<EOF >/opt/woodpecker_data/server.env
WOODPECKER_HOST=http://${LOCAL_IP}:8000
WOODPECKER_AGENT_SECRET=${AGENT_SECRET}
WOODPECKER_GRPC_SECRET=$(openssl rand -hex 32)
WOODPECKER_DATABASE_DRIVER=sqlite3
WOODPECKER_DATABASE_DATASOURCE=/opt/woodpecker_data/woodpecker.sqlite
WOODPECKER_OPEN=false
WOODPECKER_ADMIN=${var_forge_admin:-}
EOF
if [[ -n "${var_forge:-}" ]]; then
  cat <<EOF >>/opt/woodpecker_data/server.env
WOODPECKER_${var_forge^^}=true
WOODPECKER_${var_forge^^}_URL=${var_forge_url:-}
WOODPECKER_${var_forge^^}_CLIENT=${var_forge_client}
WOODPECKER_${var_forge^^}_SECRET=${var_forge_secret}
EOF
else
  cat <<EOF >>/opt/woodpecker_data/server.env
# Woodpecker CI signs users in through one forge. Create an OAuth app there with the
# callback URL http://${LOCAL_IP}:8000/authorize, set your forge login in WOODPECKER_ADMIN
# and fill in the block below. GitHub, Gitea, GitLab and Bitbucket use the same
# WOODPECKER_<FORGE>_* names: https://woodpecker-ci.org/docs/administration/configuration/forges/overview
# Then run: systemctl enable --now woodpecker-server woodpecker-agent
#WOODPECKER_FORGEJO=true
#WOODPECKER_FORGEJO_URL=https://forgejo.example.com
#WOODPECKER_FORGEJO_CLIENT=
#WOODPECKER_FORGEJO_SECRET=
EOF
fi
# Debian 13 keeps /tmp in RAM, so workflows are checked out on disk instead
cat <<EOF >/opt/woodpecker_data/agent.env
WOODPECKER_SERVER=localhost:9000
WOODPECKER_AGENT_SECRET=${AGENT_SECRET}
WOODPECKER_BACKEND=local
WOODPECKER_BACKEND_LOCAL_TEMP_DIR=/opt/woodpecker_data/workspaces
WOODPECKER_AGENT_CONFIG_FILE=/opt/woodpecker_data/agent.conf
EOF
chmod 600 /opt/woodpecker_data/server.env /opt/woodpecker_data/agent.env
msg_ok "Configured Woodpecker CI"

msg_info "Creating Woodpecker CI Services"
cat <<EOF >/etc/systemd/system/woodpecker-server.service
[Unit]
Description=Woodpecker CI Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/woodpecker_data
EnvironmentFile=/opt/woodpecker_data/server.env
ExecStart=/opt/woodpecker/woodpecker-server
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/woodpecker-agent.service
[Unit]
Description=Woodpecker CI Agent
After=network-online.target woodpecker-server.service
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/woodpecker_data
EnvironmentFile=/opt/woodpecker_data/agent.env
ExecStart=/opt/woodpecker/woodpecker-agent
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
if [[ -n "${var_forge:-}" ]]; then
  systemctl enable -q --now woodpecker-server woodpecker-agent
fi
msg_ok "Created Woodpecker CI Services"

motd_ssh
customize
cleanup_lxc
