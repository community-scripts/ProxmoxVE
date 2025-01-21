#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: FWiegerinck
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/smallstep/certificates

APP="Alpine-Step-CA"
var_tags="alpine;step-ca"
var_cpu="1"
var_ram="512"
var_disk="1024"
var_os="alpine"
var_version="3.20"
var_unprivileged="0"

DEFAULT_CA_NAME="HomeLab CA"

header_info "$APP"
base_settings
variables
color
catch_errors

function update_script() {
   if ! apk -e info newt >/dev/null 2>&1; then
    apk add -q newt
  fi
  while true; do
    CHOICE=$(
      whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --menu "Select option" 11 58 1 \
        "1" "Check for Step CA Updates" 3>&2 2>&1 1>&3
    )
    exit_status=$?
    if [ $exit_status == 1 ]; then
      clear
      exit-script
    fi
    header_info
    case $CHOICE in
    1)
      apk update && apk upgrade
      exit
      ;;
    esac
  done
}

function ca_settings() {

  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Configure Certificate Authority" "Now that we defined the container we need to configure the certificate authority." 8 58
  
  if CA_NAME=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Name of certificate authority" 8 58 "$DEFAULT_CA_NAME" --title "Configure Certificate Authority" 3>&1 1>&2 2>&3); then
    if [ -z "$CA_NAME" ]; then
      CA_NAME="$DEFAULT_CA_NAME"
    fi
  else
    exit
  fi

  CA_DNS_ENTRIES=()
  DEFAULT_CA_DNS_ENTRY="${HN}.local"
  if CA_PRIMARY_DNS=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "DNS entry of Certificate Authority" 8 58 "$DEFAULT_CA_DNS_ENTRY" --title "Configure Certificate Authority" 3>&1 1>&2 2>&3); then
    if [ -z "$CA_PRIMARY_DNS" ]; then
      CA_PRIMARY_DNS=$DEFAULT_CA_DNS_ENTRY
    fi
    CA_DNS_ENTRIES+=("--dns=$CA_PRIMARY_DNS")
  else
    exit
  fi

  while whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "Configure Certificate Authority" --yesno "Do you want to add another DNS entry?" 10 72  ; do
    if dns_entry=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "DNS entry of Certificate Authority" 8 58 "" --title "Configure Certificate Authority" 3>&1 1>&2 2>&3); then
      if [ -n "$dns_entry" ]; then
        CA_DNS_ENTRIES+=(" --dns=$dns_entry")
      fi
    fi
  done

  x509_policy_dns=()
  while true; do
    if dns_entry=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "[X509 Policy] Allowed by DNS. Use full ('domain.local') or wildcard ('*.local') DNS:" 8 58 "" --title "Configure Certificate Authority" 3>&1 1>&2 2>&3); then
      if [ -n "$dns_entry" ]; then
        x509_policy_dns+=("$dns_entry")
      else
        break
      fi
    else
      exit
    fi
  done

  x509_policy_ips=()
  while true; do
    if ip_entry=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "[X509 Policy] Allowed by IP addresses. Use single address ('192.168.1.169' or '::1') or CIDR address ranges ('192.168.1.0/24' or '2001:0db8::/120'):" 8 58 "" --title "Configure Certificate Authority" 3>&1 1>&2 2>&3); then
      if [ -n "$ip_entry" ]; then
        x509_policy_ips+=("$ip_entry")
      else
        break
      fi
    else
      exit
    fi
  done

  if (whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "Configure Certificate Authority" --yesno "Enable ACME?" 10 58); then
    CA_ACME="yes"
    
    default_ca_acme_name="acme"
    if CA_ACME_NAME=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Name of ACME provider" 8 58 "$default_ca_acme_name" --title "Configure Certificate Authority" 3>&1 1>&2 2>&3); then
      if [ -z "$CA_ACME_NAME" ]; then
        CA_ACME_NAME="$default_ca_acme_name"
      fi
    else
      exit
    fi

  else
    CA_ACME="no"
  fi

  if [ "$VERBOSE" = "yes" ]; then
    echo -e "${DEFAULT}${BOLD}${DGN}Name of CA: ${BGN}$CA_NAME${CL}"
    echo -e "${DEFAULT}${BOLD}${DGN}DNS entries of CA:${CL}"
    for DNS_ENTRY in ${CA_DNS_ENTRIES[*]}; do
      echo -e "  - $DNS_ENTRY"
    done
    echo -e "${DEFAULT}${BOLD}${DGN}X509 Policy - allow:{CL}"
    echo -e "  - DNS entries: ${x509_policy_dns[*]}"
    echo -e "  - IP addresses: ${x509_policy_ips[*]}"

    echo -e "${DEFAULT}${BOLD}${DGN}Enable ACME: ${BGN}$CA_ACME${CL}"
    if [ "${CA_ACME}" = "yes" ]; then
      echo -e "  - Name of provider: ${CA_ACME_NAME}"
    fi
  fi

  export CA_NAME
  export CA_PRIMARY_DNS
  export CA_DNS=${CA_DNS_ENTRIES[*]}
  export CA_X509_POLICY_DNS=${x509_policy_dns[*]}
  export CA_X509_POLICY_IPS=${x509_policy_ips[*]}
  export CA_ACME
  export CA_ACME_NAME
}

start
ca_settings
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
if [ "${CA_ACME}" = "yes" ]; then
  echo -e "  ACME should be reachable at URL: https://${CA_PRIMARY_DNS}/acme/{$CA_ACME_NAME}/directory"
fi
