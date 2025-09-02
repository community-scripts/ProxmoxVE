#!/usr/bin/env bash
# Copyright (c) 2021-2025 community-scripts ORG
# Author: FWiegerinck
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/smallstep/certificates

# Import Functions and Setup
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Install dependencies for setup dialog
msg_info "Installing Dependencies for Setup"
$STD apk add newt
msg_ok "Installed Dependencies for Setup"

# --- Interactive CA Configuration ---
whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Configure Certificate Authority" "The container is set up. Now, we need to configure the certificate authority itself." 8 78

DEFAULT_CA_NAME="HomeLab CA"
if CA_NAME=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Enter the name of your certificate authority:" 8 60 "$DEFAULT_CA_NAME" --title "Configure Certificate Authority" 3>&1 1>&2 2>&3); then
  [ -z "$CA_NAME" ] && CA_NAME="$DEFAULT_CA_NAME"
else
  exit-script
fi

CA_DNS_ENTRIES=()
DEFAULT_CA_DNS_ENTRY="${HN}.local"
if CA_PRIMARY_DNS=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Enter the primary DNS name for the CA (e.g., ca.yourdomain.com):" 8 78 "$DEFAULT_CA_DNS_ENTRY" --title "Configure Certificate Authority" 3>&1 1>&2 2>&3); then
  [ -z "$CA_PRIMARY_DNS" ] && CA_PRIMARY_DNS=$DEFAULT_CA_DNS_ENTRY
  CA_DNS_ENTRIES+=("--dns=$CA_PRIMARY_DNS")
else
  exit-script
fi

while whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "Configure Certificate Authority" --yesno "Do you want to add another DNS entry?" 8 78; do
  if dns_entry=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Enter additional DNS entry:" 8 78 --title "Configure Certificate Authority" 3>&1 1>&2 2>&3); then
    [ -n "$dns_entry" ] && CA_DNS_ENTRIES+=("--dns=$dns_entry")
  fi
done

x509_policy_dns=()
while whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "X.509 Policy" --yesno "Do you want to add an ALLOWED DNS name to the X.509 policy?\n(e.g., 'domain.local' or '*.domain.local')" 10 78; do
  if dns_entry=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "[X509 Policy] Allowed by DNS:" 8 78 --title "Configure Certificate Authority" 3>&1 1>&2 2>&3); then
    [ -n "$dns_entry" ] && x509_policy_dns+=("$dns_entry")
  else
    break
  fi
done

x509_policy_ips=()
while whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "X.509 Policy" --yesno "Do you want to add an ALLOWED IP/CIDR to the X.509 policy?\n(e.g., '192.168.1.0/24' or '10.0.0.5')" 10 78; do
  if ip_entry=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "[X509 Policy] Allowed by IP addresses/CIDR:" 8 78 --title "Configure Certificate Authority" 3>&1 1>&2 2>&3); then
    [ -n "$ip_entry" ] && x509_policy_ips+=("$ip_entry")
  else
    break
  fi
done

if (whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "Configure Certificate Authority" --yesno "Enable ACME provisioner for clients like Traefik/Caddy?" 10 78); then
  CA_ACME="yes"
  default_ca_acme_name="acme"
  if CA_ACME_NAME=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Name of ACME provider:" 8 60 "$default_ca_acme_name" --title "Configure Certificate Authority" 3>&1 1>&2 2>&3); then
    [ -z "$CA_ACME_NAME" ] && CA_ACME_NAME="$default_ca_acme_name"
  else
    exit-script
  fi
else
  CA_ACME="no"
fi

# --- Installation ---
msg_info "Installing Step CA and other dependencies"
$STD apk add step-cli step-certificates openssl
msg_ok "Installed Step CA"

msg_info "Preparing environment"
config_dir="/etc/step-ca"
passwd_file="${config_dir}/password.txt"
ca_admin_provisioner="Admin-JWK"
ca_admin_subject="admin@localhost"
ca_admin_provisioner_passwd_file="${config_dir}/admin-jwk-password.txt"
$STD mkdir -p ${config_dir}
$STD echo "export STEPPATH=${config_dir}" >>~/.profile
export STEPPATH=${config_dir}
msg_ok "Environment prepared"

msg_info "Generating CA secrets"
openssl rand -base64 24 >"${passwd_file}"
openssl rand -base64 24 >"${ca_admin_provisioner_passwd_file}"
chmod 600 "${passwd_file}" "${ca_admin_provisioner_passwd_file}"
msg_ok "Generated CA secrets"

msg_info "Initializing Certificate Authority"
CA_DNS_ARGS=$(printf " %s" "${CA_DNS_ENTRIES[@]}")
$STD step ca init --name "${CA_NAME}" ${CA_DNS_ARGS} --password-file "${passwd_file}" \
  --deployment-type standalone --address ":443" --provisioner "${ca_admin_provisioner}" \
  --admin-subject "${ca_admin_subject}" --provisioner-password-file "${ca_admin_provisioner_passwd_file}" --remote-management
msg_ok "Initialized Certificate Authority"

msg_info "Starting Step CA Service to apply policies"
$STD rc-service step-ca start
timeout_counter=0
while ! nc -z localhost 443; do
  sleep 1
  ((timeout_counter = timeout_counter + 1))
  if ((timeout_counter > 30)); then
    msg_error "Failed to start Step-CA in time for configuration."
    exit 1
  fi
done
msg_ok "Step CA Service is running"

if [ ${#x509_policy_dns[@]} -gt 0 ] || [ ${#x509_policy_ips[@]} -gt 0 ]; then
  msg_info "Configuring CA X.509 policy"
  $STD step ca policy authority x509 allow dns "${ca_admin_subject}" --admin-provisioner "${ca_admin_provisioner}" --admin-subject "${ca_admin_subject}" --password-file "${ca_admin_provisioner_passwd_file}"
  if [ ${#x509_policy_dns[@]} -gt 0 ]; then
    $STD step ca policy authority x509 allow dns "${x509_policy_dns[*]}" --admin-provisioner "${ca_admin_provisioner}" --admin-subject "${ca_admin_subject}" --password-file "${ca_admin_provisioner_passwd_file}"
  fi
  if [ ${#x509_policy_ips[@]} -gt 0 ]; then
    $STD step ca policy authority x509 allow ip "${x509_policy_ips[*]}" --admin-provisioner "${ca_admin_provisioner}" --admin-subject "${ca_admin_subject}" --password-file "${ca_admin_provisioner_passwd_file}"
  fi
  msg_ok "Configured CA X.509 policy"
fi

if [ "${CA_ACME}" = "yes" ]; then
  msg_info "Initializing ACME provisioner for CA"
  $STD step ca provisioner add "${CA_ACME_NAME}" --type ACME --x509-min-dur=20m --x509-max-dur=32h --x509-default-dur=24h --admin-provisioner "${ca_admin_provisioner}" --admin-subject "${ca_admin_subject}" --password-file "${ca_admin_provisioner_passwd_file}"
  msg_ok "Initialized ACME provisioner"
fi

msg_info "Enabling Step CA Service on boot"
$STD rc-service step-ca restart
$STD rc-update add step-ca default
msg_ok "Step CA Service is now enabled and running"

# --- Finalization ---
motd_ssh
customize

msg_ok "Completed setup of Step CA"

ca_root_fingerprint=$(step certificate fingerprint ${STEPPATH}/certs/root_ca.crt)
echo "export CA_FINGERPRINT=${ca_root_fingerprint}" >>~/.profile
cat <<EOF >>/etc/motd
- Your CA root fingerprint is: ${ca_root_fingerprint}
  (To show again on login, run: echo \$CA_FINGERPRINT)
- To add to your local trust store, run:
  step ca bootstrap --ca-url https://${CA_PRIMARY_DNS} --fingerprint ${ca_root_fingerprint}

EOF
if [ "${CA_ACME}" = "yes" ]; then
  echo "- ACME directory URL: https://${CA_PRIMARY_DNS}/acme/${CA_ACME_NAME}/directory" >>/etc/motd
fi
