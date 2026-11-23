#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Nicolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://anubis.techaro.lol/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "anubis" "TecharoHQ/anubis" "binary"

msg_info "Configuring Anubis"
cp /usr/share/doc/anubis/botPolicies.yaml /etc/anubis/main.botPolicies.yaml
cat <<EOF >/etc/anubis/main.env
BIND=:8923
BIND_NETWORK=tcp
METRICS_BIND=:9090
METRICS_BIND_NETWORK=tcp
DIFFICULTY=4
SERVE_ROBOTS_TXT=0
COOKIE_SECURE=false
USE_REMOTE_ADDRESS=true
POLICY_FNAME=/etc/anubis/main.botPolicies.yaml
ED25519_PRIVATE_KEY_HEX=$(openssl rand -hex 32)
TARGET=${var_anubis_target:-http://localhost:3000}
EOF
systemctl enable -q --now anubis@main
msg_ok "Configured Anubis"

motd_ssh
customize
cleanup_lxc
