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
$STD export STEPPATH=/etc/step-ca

if [ "$VERBOSE" = "yes" ]; then
  env #Display environment details
fi

x509_policy_dns=($(echo "${CA_X509_POLICY_DNS}" | tr ' ' '\n'))
x509_policy_ips=($(echo "${CA_X509_POLICY_IPS}" | tr ' ' '\n'))

msg_ok "Environment prepared"

msg_info "Installing Alpine Step-CA"
$STD apk add step-cli step-certificates
msg_ok "Installed Alpine Step-CA"

# Initialize CA
config_dir="/etc/step-ca"
passwd_file="${config_dir}/password.txt"

msg_info "Generate CA secrets"
CA_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
$STD cat <<EOF >${passwd_file}
${CA_PASS}
EOF
msg_ok "Generated CA secrets"


msg_info "Initialize base CA"
$STD step ca init --name "${CA_NAME}" $CA_DNS --password-file ${passwd_file} --deployment-type standalone --address ":443" --provisioner admin

#for dns_entry in "${x509_policy_dns[@]}"; do
#  $STD step ca policy authority x509 allow dns "${dns_entry}"
#done
#for ip_entry in "${x509_policy_ips[@]}"; do
#  $STD step ca policy authority x509 allow ip ${ip_entry}
#done

if [ "${CA_ACME}" = "yes" ]; then
  msg_info "Initialize ACME for CA"
  $STD step ca provisioner add ${CA_ACME_NAME} --type ACME --x509-min-dur=20m --x509-max-dur=32h --x509-default-dur=24h
fi
msg_ok "Finished initialization of CA"

# Start application
msg_info "Starting Alpine Step-CA"
$STD rc-service step-ca start
$STD rc-update add step-ca default
msg_ok "Started Alpine Step-CA"

motd_ssh

# add fingerprint to motd
ca_root_fingerprint=$(step certificate fingerprint ${STEPPATH}/certs/root_ca.crt)
echo -e "${TAB}${DEFAULT}${YW} Fingerprint CA Root Certificate: ${GN}${ca_root_fingerprint}${CL}" >> /etc/motd

customize
