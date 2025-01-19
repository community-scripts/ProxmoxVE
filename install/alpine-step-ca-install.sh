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

# Finished base install.... now install and setup Step-CA

# Step 0: Set internal values
config_dir="/etc/step-ca"
passwd_file="${config_dir}/password.txt"
ca_admin_provisioner="Admin JWK"
ca_admin_subject="admin-localhost"
ca_admin_provisioner_passwd_file="${config_dir}/admin-jwk-password.txt"


# Step 1: Installing Dependencies
msg_info "Installing dependencies"
$STD apk add newt
$STD apk add openssl
msg_ok "Installed dependencies"


# Step 2: Prepare environment
msg_info "Preparing environment"
$STD echo "export STEPPATH=/etc/step-ca" > ~/.profile
$STD export STEPPATH=/etc/step-ca
msg_ok "Environment prepared"

# Step 3: Do actual install of step-ca
msg_info "Installing Alpine Step-CA"
$STD apk add step-cli step-certificates
msg_ok "Installed Alpine Step-CA"

# Step 4: Setup step-ca

# Step 4a: Prepare secrets
msg_info "Generate CA secrets"

function generatePasswordFile(){ # argument: path of file

  $STD echo "$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)" > "$1"
  chmod 600 "$1"

}

generatePasswordFile "${passwd_file}"
generatePasswordFile "${ca_admin_provisioner_passwd_file}"

msg_ok "Generated CA secrets"

# Step 4b: Configure base CA
msg_info "Initialize base CA"

# Do initialize and immediately start it for further configuration
$STD step ca init --name "${CA_NAME}" --dns localhost $CA_DNS --password-file ${passwd_file} --deployment-type standalone --address ":443" --provisioner "${ca_admin_provisioner}" --admin-subject "${ca_admin_subject}" --provisioner-password-file ${ca_admin_provisioner_passwd_file} --remote-management
$STD rc-service step-ca start

# Wait till service has started and port is available
timeout_counter=0
while ! nc -z localhost 443; do
  sleep 0.5
  
  ((timeout_counter=counter+1))
  if (( timeout_counter > 30 )); then
    msg_error "Failed to start Step-CA"
    exit
  fi
done

msg_ok "Initialized base CA"

# Step 4c: Configure CA policy if necessary
if [ -n "${CA_X509_POLICY_DNS}" ] || [ -n "${CA_X509_POLICY_IPS}" ]; then
  msg_info "Configure CA policy"

  # Ensure admin subject is added to the allow list
  $STD step ca policy authority x509 allow dns "${ca_admin_subject}" --admin-provisioner "${ca_admin_provisioner}" --admin-subject "${ca_admin_subject}" --password-file ${ca_admin_provisioner_passwd_file}

  if [ -n "${CA_X509_POLICY_DNS}" ]; then
    $STD step ca policy authority x509 allow dns ${CA_X509_POLICY_DNS} --admin-provisioner "${ca_admin_provisioner}" --admin-subject "${ca_admin_subject}" --password-file ${ca_admin_provisioner_passwd_file}
  fi
  if [ -n "${CA_X509_POLICY_IPS}" ]; then
    $STD step ca policy authority x509 allow ip ${CA_X509_POLICY_IPS} --admin-provisioner "${ca_admin_provisioner}" --admin-subject "${ca_admin_subject}" --password-file ${ca_admin_provisioner_passwd_file}
  fi

  msg_ok "Configured CA policy"
fi

# Step 4d: Configure ACME if desired
if [ "${CA_ACME}" = "yes" ]; then
  msg_info "Initialize ACME for CA"
  $STD step ca provisioner add "${CA_ACME_NAME}" --type ACME --x509-min-dur=20m --x509-max-dur=32h --x509-default-dur=24h --admin-provisioner "${ca_admin_provisioner}" --admin-subject "${ca_admin_subject}" --password-file ${ca_admin_provisioner_passwd_file}
  msg_ok "Initialized ACME for CA"
fi


# Step 4e: Restart service and enable auto-start
msg_info "Starting Alpine Step-CA"
$STD rc-service step-ca restart
$STD rc-update add step-ca default
msg_ok "Started Alpine Step-CA"

# Step 4f: Report back completion as it works from here!
msg_ok "Completed setup of CA"

# Step 4g: Extend motd with step-ca fingerprint of root CA
MOTD_FILE="/etc/motd"
if [ -f "$MOTD_FILE" ]; then
  ca_root_fingerprint=$(step certificate fingerprint ${STEPPATH}/certs/root_ca.crt)
  echo -e "\n${TAB}${DEFAULT}${YW} Fingerprint CA Root Certificate: ${GN}${ca_root_fingerprint}${CL}" >> "$MOTD_FILE"
fi
