#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ffind-dev/pve-ups

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_uv

fetch_and_deploy_gh_release "pve-usv" "ffind-dev/pve-ups" "tarball"

msg_info "Setting up Application"
useradd --system --home /opt/pve-usv --shell /usr/sbin/nologin pveusv
install -d -o pveusv -g pveusv -m 0750 \
  /etc/pve-usv \
  /var/lib/pve-usv \
  /var/lib/pve-usv/agent \
  /var/lib/pve-usv/agent/queue \
  /var/lib/pve-usv/updates
chown -R pveusv:pveusv /opt/pve-usv
cd /opt/pve-usv
$STD uv venv --clear --seed venv
$STD uv pip install --python venv/bin/python .
chmod 0755 deploy/pve-usv-agent.sh
msg_ok "Set up Application"

msg_info "Creating Services"
install -m 0644 /opt/pve-usv/deploy/pve-usv.service /etc/systemd/system/pve-usv.service
install -m 0644 /opt/pve-usv/deploy/pve-usv-agent.service /etc/systemd/system/pve-usv-agent.service
install -m 0644 /opt/pve-usv/deploy/pve-usv-agent.path /etc/systemd/system/pve-usv-agent.path
install -m 0644 /opt/pve-usv/deploy/pve-usv-agent.timer /etc/systemd/system/pve-usv-agent.timer
systemctl enable -q --now pve-usv pve-usv-agent.path pve-usv-agent.timer
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
