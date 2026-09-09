#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://jitsi.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Optional public setup. Leave the hostname empty for a LAN-only install
# (container IP, self-signed certificate) - the previous default behaviour.
if [[ -z "${var_jitsi_domain:-}" ]]; then
  read -rp "${TAB3}Public hostname (FQDN, leave empty to use the container IP): " var_jitsi_domain || true
fi
var_jitsi_domain="${var_jitsi_domain:-$LOCAL_IP}"

if [[ "$var_jitsi_domain" != "$LOCAL_IP" ]]; then
  if [[ -z "${var_jitsi_le_email:-}" ]]; then
    read -rp "${TAB3}E-mail for Let's Encrypt (leave empty for a self-signed certificate): " var_jitsi_le_email || true
  fi
  if [[ -z "${var_jitsi_public_ip:-}" ]]; then
    read -rp "${TAB3}Public IP behind NAT (leave empty to detect via STUN): " var_jitsi_public_ip || true
  fi
  if [[ -z "${var_jitsi_admin_user:-}" ]]; then
    read -rp "${TAB3}Admin user for secure domain (leave empty to let anyone create rooms): " var_jitsi_admin_user || true
  fi
  if [[ -n "${var_jitsi_admin_user:-}" && -z "${var_jitsi_admin_pass:-}" ]]; then
    read -rsp "${TAB3}Admin password (leave empty to generate): " var_jitsi_admin_pass || true
    echo
  fi
fi

msg_info "Installing Dependencies"
$STD apt install -y nginx
msg_ok "Installed Dependencies"

source /etc/os-release
setup_deb822_repo "jitsi" \
  "https://download.jitsi.org/jitsi-key.gpg.key" \
  "https://download.jitsi.org" \
  "stable/" \
  ""

msg_info "Installing Jitsi Meet"
echo "jitsi-videobridge2 jitsi-videobridge/jvb-hostname string ${var_jitsi_domain}" | debconf-set-selections
if [[ -n "${var_jitsi_le_email:-}" ]]; then
  # acme.sh (used by the packaged Let's Encrypt helper) refuses to install without cron
  $STD apt install -y cron
  echo "jitsi-meet-web-config jitsi-meet/cert-choice select Let's Encrypt certificates" | debconf-set-selections
  echo "jitsi-meet-web-config jitsi-meet/email string ${var_jitsi_le_email}" | debconf-set-selections
else
  echo "jitsi-meet-web-config jitsi-meet/cert-choice select Generate a new self-signed certificate" | debconf-set-selections
fi
echo "jitsi-meet-web-config jitsi-meet/jaas-choice boolean false" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive $STD apt install -y jitsi-meet
msg_ok "Installed Jitsi Meet"

if [[ -n "${var_jitsi_public_ip:-}" ]]; then
  msg_info "Configuring NAT mapping"
  # JVB 2.3+ reads this from jvb.conf; sip-communicator.properties is no longer used
  cat <<EOF >>/etc/jitsi/videobridge/jvb.conf
ice4j {
  harvest {
    mapping {
      static-mappings = [
        { local-address = "${LOCAL_IP}", public-address = "${var_jitsi_public_ip}" }
      ]
    }
  }
}
EOF
  systemctl restart jitsi-videobridge2
  msg_ok "Configured NAT mapping"
fi

if [[ -n "${var_jitsi_admin_user:-}" ]]; then
  msg_info "Configuring Secure Domain"
  # Only authenticated users may create rooms; guests join via the anonymous domain.
  # https://jitsi.github.io/handbook/docs/devops-guide/secure-domain/
  var_jitsi_admin_pass="${var_jitsi_admin_pass:-$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-16)}"
  sed -i "0,/authentication = \"jitsi-anonymous\"/s//authentication = \"internal_hashed\"/" \
    "/etc/prosody/conf.avail/${var_jitsi_domain}.cfg.lua"
  cat <<EOF >>"/etc/prosody/conf.avail/${var_jitsi_domain}.cfg.lua"

VirtualHost "guest.${var_jitsi_domain}"
    authentication = "anonymous"
    c2s_require_encryption = false
EOF
  cat <<EOF >>/etc/jitsi/jicofo/jicofo.conf
jicofo {
  authentication {
    enabled = true
    type = XMPP
    login-url = "${var_jitsi_domain}"
  }
}
EOF
  sed -i "s|^\s*// anonymousdomain: 'guest.example.com',|    anonymousdomain: 'guest.${var_jitsi_domain}',|" \
    "/etc/jitsi/meet/${var_jitsi_domain}-config.js"
  $STD prosodyctl register "${var_jitsi_admin_user}" "${var_jitsi_domain}" "${var_jitsi_admin_pass}"
  cat <<EOF >~/jitsi-meet.creds
Jitsi Meet Secure Domain
Admin User: ${var_jitsi_admin_user}
Admin Password: ${var_jitsi_admin_pass}
Add more users: prosodyctl register <name> ${var_jitsi_domain} <password>
EOF
  systemctl restart prosody jicofo jitsi-videobridge2
  msg_ok "Configured Secure Domain"
fi

motd_ssh
customize
cleanup_lxc
