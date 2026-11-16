#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ) | Co-Author: 007hacky007
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/FoldingAtHome/fah-client-bastet

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

if [[ -z "${var_fah_token:-}" ]]; then
  var_fah_token=$(prompt_password "Folding@home account token (Enter to skip):" "" 120)
fi
if [[ -z "${var_fah_machine_name:-}" ]]; then
  var_fah_machine_name=$(prompt_input "Folding@home machine name:" "$(hostname)" 60)
fi
if [[ ${#var_fah_machine_name} -gt 64 || "$var_fah_machine_name" == *[\<\>\;\&\'\"]* ]]; then
  msg_warn "Machine name must be 1-64 characters without <>;&'\" - using $(hostname)"
  var_fah_machine_name=$(hostname)
fi

msg_info "Configuring Folding@home"
mkdir -p /etc/fah-client
cat <<EOF >/etc/fah-client/config.xml
<config>
  <account-token v="${var_fah_token}"/>
  <machine-name v="${var_fah_machine_name}"/>
</config>
EOF
msg_ok "Configured Folding@home"

fetch_and_deploy_from_url "https://download.foldingathome.org/releases/public/fah-client/$(arch_resolve "debian-10-64bit" "debian-stable-arm64")/release/latest.deb"

setup_hwaccel "fah-client"

# The client detects GPUs only at startup, so restart it after setup_hwaccel.
msg_info "Starting Folding@home"
systemctl enable -q fah-client
safe_service_restart fah-client
msg_ok "Started Folding@home"

motd_ssh
customize
cleanup_lxc
