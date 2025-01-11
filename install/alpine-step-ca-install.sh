#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: FWiegerinck
# License: MIT
# Source: https://github.com/smallstep/certificates

# Import Functions und Setup
source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Installing Dependencies
#msg_info "Installing Dependencies"
$STD apk add newt
$STD apk add openssl
#msg_ok "Installed Dependencies"

msg_info "Installing Alpine Step-CA"
$STD apk add step-cli step-certificates
msg_ok "Installed Alpine Step-CA"

# Initialize CA
CA_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
config_dir="/etc/step-ca"
log_dir="/var/log/step-ca"
error_log="${log_dir}/${RC_SVCNAME}.log"
profile_file="${config_dir}/.profile"
ca_file="${config_dir}/config/ca.json"
passwd_file="${config_dir}/password.txt"

cat <<EOF >${passwd_file}
${CA_PASS}
EOF

# Start application
msg_info "Starting Alpine Step-CA"
$STD rc-service step-ca start
$STD rc-update add step-ca default
msg_ok "Started Alpine Step-CA"

motd_ssh
customize
