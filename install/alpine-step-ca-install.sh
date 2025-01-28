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

motd_ssh
customize

config_dir="/etc/step-ca"
passwd_file="${config_dir}/password.txt"
ca_admin_provisioner="Admin JWK"
ca_admin_subject="admin-localhost"
ca_admin_provisioner_passwd_file="${config_dir}/admin-jwk-password.txt"

msg_info "Installing dependencies"
$STD apk add newt
$STD apk add openssl
msg_ok "Installed dependencies"

msg_info "Preparing environment"
$STD echo "export STEPPATH=/etc/step-ca" >> ~/.profile
$STD export STEPPATH=/etc/step-ca
msg_ok "Environment prepared"

msg_info "Installing Alpine Step-CA"
$STD apk add step-cli step-certificates
msg_ok "Installed Alpine Step-CA"

msg_info "Generate CA secrets"

function generatePasswordFile(){
  $STD echo "$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)" > "$1"
  chmod 600 "$1"
}

generatePasswordFile "${passwd_file}"
generatePasswordFile "${ca_admin_provisioner_passwd_file}"

msg_ok "Generated CA secrets"

msg_info "Initialize base CA"

$STD step ca init --name "${CA_NAME}" --dns localhost $CA_DNS --password-file ${passwd_file} --deployment-type standalone --address ":443" --provisioner "${ca_admin_provisioner}" --admin-subject "${ca_admin_subject}" --provisioner-password-file ${ca_admin_provisioner_passwd_file} --remote-management
$STD rc-service step-ca start

timeout_counter=0
while ! nc -z localhost 443; do
  sleep 0.5

  ((timeout_counter=timeout_counter+1))
  if (( timeout_counter > 30 )); then
    msg_error "Failed to start Step-CA"
    exit
  fi
done

msg_ok "Initialized base CA"

if [ -n "${CA_X509_POLICY_DNS}" ] || [ -n "${CA_X509_POLICY_IPS}" ]; then
  msg_info "Configure CA policy"

  $STD step ca policy authority x509 allow dns "${ca_admin_subject}" --admin-provisioner "${ca_admin_provisioner}" --admin-subject "${ca_admin_subject}" --password-file ${ca_admin_provisioner_passwd_file}

  if [ -n "${CA_X509_POLICY_DNS}" ]; then
    $STD step ca policy authority x509 allow dns ${CA_X509_POLICY_DNS} --admin-provisioner "${ca_admin_provisioner}" --admin-subject "${ca_admin_subject}" --password-file ${ca_admin_provisioner_passwd_file}
  fi
  if [ -n "${CA_X509_POLICY_IPS}" ]; then
    $STD step ca policy authority x509 allow ip ${CA_X509_POLICY_IPS} --admin-provisioner "${ca_admin_provisioner}" --admin-subject "${ca_admin_subject}" --password-file ${ca_admin_provisioner_passwd_file}
  fi

  msg_ok "Configured CA policy"
fi

if [ "${CA_ACME}" = "yes" ]; then
  msg_info "Initialize ACME for CA"
  $STD step ca provisioner add "${CA_ACME_NAME}" --type ACME --x509-min-dur=20m --x509-max-dur=32h --x509-default-dur=24h --admin-provisioner "${ca_admin_provisioner}" --admin-subject "${ca_admin_subject}" --password-file ${ca_admin_provisioner_passwd_file}
  msg_ok "Initialized ACME for CA"
fi

msg_info "Starting Alpine Step-CA"
$STD rc-service step-ca restart
$STD rc-update add step-ca default
msg_ok "Started Alpine Step-CA"

msg_ok "Completed setup of CA"

ca_root_fingerprint=$(step certificate fingerprint ${STEPPATH}/certs/root_ca.crt)
$STD echo "echo \"Fingerprint CA Root Certificate: ${ca_root_fingerprint}\" " >> ~/.profile