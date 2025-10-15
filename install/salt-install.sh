#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/saltstack/salt

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y jq
msg_ok "Installed Dependencies"

msg_info "Setup Salt Repo"
mkdir -p /etc/apt/keyrings
curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public -o /etc/apt/keyrings/salt-archive-keyring.pgp
curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.sources -o /etc/apt/sources.list.d/salt.sources
$STD apt update
msg_ok "Setup Salt Repo"

msg_info "Installing Salt"
RELEASE=$(curl -fsSL https://api.github.com/repos/saltstack/salt/releases/latest | jq -r .tag_name | sed 's/^v//')
cat <<EOF >/etc/apt/preferences.d/salt-pin-1001
Package: salt-*
Pin: version ${RELEASE}
Pin-Priority: 1001
EOF
$STD apt install -y salt-master
echo "${RELEASE}" >/~.salt
msg_ok "Installed Salt"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
