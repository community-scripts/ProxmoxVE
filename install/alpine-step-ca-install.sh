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

msg_info "Preparing environment"
$STD echo "export STEPPATH=/etc/step-ca" > ~/.profile
msg_ok "Environment prepared"

msg_info "Installing Alpine Step-CA"
$STD apk add step-cli step-certificates
msg_ok "Installed Alpine Step-CA"

# Initialize CA
config_dir="/etc/step-ca"
log_dir="/var/log/step-ca"
profile_file="${config_dir}/.profile"
ca_file="${config_dir}/config/ca.json"
passwd_file="${config_dir}/password.txt"

msg_info "Generate CA secret"
CA_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
$STD cat <<EOF >${passwd_file}
${CA_PASS}
EOF
msg_ok "Generated CA secret in ${passwd_file} - ${CA_PASS}"


msg_info "Initialize CA"
DNS_FLAT=""
for DNS_ENTRY in ${CA_DNS[*]}; do
  DNS_FLAT="$DNS_FLAT --dns=\"$DNS_ENTRY\""
done
$STD step ca init --name="$CA_NAME" $DNS_FLAT --password-file=/etc/step-ca/password.txt --acme --deployment-type=standalone --address=0.0.0.0:443 --provisioner=acme
$STD step ca provisioner update acme --x509-min-dur=20m --x509-max-dur=32h --x509-default-dur=24h
msg_ok "Finished initialization of CA"

# Start application
msg_info "Starting Alpine Step-CA"
$STD rc-service step-ca start
$STD rc-update add step-ca default
msg_ok "Started Alpine Step-CA"

motd_ssh
customize
