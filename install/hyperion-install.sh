#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://hyperion-project.org/forum/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os
setup_hwaccel

msg_info "Setting up Hyperion repository"
setup_deb822_repo \
  "hyperion" \
  "https://releases.hyperion-project.org/hyperion.pub.key" \
  "https://apt.releases.hyperion-project.org" \
  "$(get_os_info codename)"
msg_ok "Set up Hyperion repository"

msg_info "Installing Hyperion"
$STD apt install -y hyperion
# The packaged hyperion@.service uses "Requisite=network.target" without ordering
# after it. In an LXC the unit's start job can be evaluated before network.target
# is active, so the strict Requisite= fails and the service does not come up after
# a reboot. Drop the Requisite= (ordering via Wants/After network-online.target in
# the base unit is kept) with a systemd override.
mkdir -p /etc/systemd/system/hyperion@.service.d
cat <<EOF >/etc/systemd/system/hyperion@.service.d/override.conf
[Unit]
Requisite=
EOF
systemctl daemon-reload
systemctl enable -q --now hyperion@root
msg_ok "Installed Hyperion"

motd_ssh
customize
cleanup_lxc
