#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: TechHutTV
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://netbird.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setting up NetBird Repository"
setup_deb822_repo \
	"netbird" \
	"https://pkgs.netbird.io/debian/public.key" \
	"https://pkgs.netbird.io/debian" \
	"stable"
msg_ok "Set up NetBird Repository"

msg_info "Installing NetBird"
$STD apt install -y netbird
msg_ok "Installed NetBird"

msg_info "Enabling NetBird Service"
$STD systemctl enable -q --now netbird
msg_ok "Enabled NetBird Service"

echo ""
echo ""
echo -e "${BL}NetBird Deployment Type${CL}"
echo "─────────────────────────────────────────"
echo "Are you using NetBird Managed or Self-Hosted?"
echo ""
echo " 1) NetBird Managed (default) - Use NetBird's managed service"
echo " 2) Self-Hosted - Use your own NetBird management server"
echo ""

read -r -p "${TAB3}Select deployment type [1]: " DEPLOYMENT_TYPE
DEPLOYMENT_TYPE="${DEPLOYMENT_TYPE:-1}"

NETBIRD_MGMT_URL=""
case "$DEPLOYMENT_TYPE" in
  1)
    msg_ok "Using NetBird Managed service"
    ;;
  2)
    echo ""
    echo -e "${BL}Self-Hosted Configuration${CL}"
    echo "─────────────────────────────────────────"
    echo "Enter your NetBird management server URL."
    echo "Example: https://management.example.com"
    echo ""
    read -r -p "Management URL: " NETBIRD_MGMT_URL

    if [[ -z "$NETBIRD_MGMT_URL" ]]; then
      msg_warn "No management URL provided. Run 'netbird up --management-url <url>' to connect."
    else
      NETBIRD_MGMT_URL="${NETBIRD_MGMT_URL%/}"
      msg_ok "Management URL configured: ${NETBIRD_MGMT_URL}"
    fi
    ;;
  *)
    msg_warn "Invalid selection. Using NetBird Managed service."
    ;;
esac

echo ""
echo ""
echo -e "${BL}NetBird Connection Setup${CL}"
echo "─────────────────────────────────────────"
echo "Choose how to connect to your NetBird network:"
echo ""
if [[ "$DEPLOYMENT_TYPE" == "1" ]]; then
  echo " 1) Setup Key (default) - Use a pre-generated setup key"
  echo " 2) SSO Login - Authenticate via browser with your identity provider"
  echo " 3) Skip - Configure later with 'netbird up'"
else
  echo " 1) Setup Key (default) - Use a pre-generated setup key"
  echo " 2) Skip - Configure later with 'netbird up'"
fi
echo ""

read -r -p "Select authentication method [1]: " AUTH_METHOD
AUTH_METHOD="${AUTH_METHOD:-1}"

if [[ "$DEPLOYMENT_TYPE" == "1" ]]; then
  case "$AUTH_METHOD" in
    1)
      echo ""
      echo "Enter your NetBird setup key from the NetBird dashboard."
      echo ""
      read -r -p "Setup key: " NETBIRD_SETUP_KEY
      echo ""

      if [[ -z "$NETBIRD_SETUP_KEY" ]]; then
        msg_warn "No setup key provided. Run 'netbird up -k <key>' to connect."
      else
        msg_info "Connecting to NetBird with setup key"
        if $STD netbird up -k "$NETBIRD_SETUP_KEY"; then
          msg_ok "Connected to NetBird"
        else
          msg_warn "Connection failed. Run 'netbird up -k <key>' to retry."
        fi
      fi
      ;;
    2)
      echo ""
      echo -e "${BL}SSO Authentication${CL}"
      echo "─────────────────────────────────────────"
      echo "A login URL will appear below."
      echo "Copy the URL and open it in your browser to authenticate."
      echo ""

      msg_info "Starting SSO login"
      netbird login 2>&1 || true
      echo ""

      msg_info "Connecting to NetBird"
      if $STD netbird up; then
        msg_ok "Connected to NetBird"
      else
        msg_warn "Connection failed. Run 'netbird up' to retry."
      fi
      ;;
    3)
      msg_ok "Skipped. Run 'netbird up' to connect."
      ;;
    *)
      msg_warn "Invalid selection. Run 'netbird up' to connect."
      ;;
  esac
else
  case "$AUTH_METHOD" in
    1)
      echo ""
      echo "Enter your NetBird setup key from the NetBird dashboard."
      echo ""
      read -r -p "Setup key: " NETBIRD_SETUP_KEY
      echo ""

      if [[ -z "$NETBIRD_SETUP_KEY" ]]; then
        if [[ -z "$NETBIRD_MGMT_URL" ]]; then
          msg_warn "No setup key provided. Run 'netbird up -k <key> --management-url <url>' to connect."
        else
          msg_warn "No setup key provided. Run 'netbird up -k <key> --management-url $NETBIRD_MGMT_URL' to connect."
        fi
      else
        if [[ -z "$NETBIRD_MGMT_URL" ]]; then
          msg_error "Management URL is required for self-hosted deployments. Please configure it first."
        else
          msg_info "Connecting to NetBird with setup key"
          if $STD netbird up -k "$NETBIRD_SETUP_KEY" --management-url "$NETBIRD_MGMT_URL"; then
            msg_ok "Connected to NetBird"
          else
            msg_warn "Connection failed. Run 'netbird up -k <key> --management-url $NETBIRD_MGMT_URL' to retry."
          fi
        fi
      fi
      ;;
    2)
      if [[ -z "$NETBIRD_MGMT_URL" ]]; then
        msg_ok "Skipped. Run 'netbird up --management-url <url>' to connect."
      else
        msg_ok "Skipped. Run 'netbird up --management-url $NETBIRD_MGMT_URL' to connect."
      fi
      ;;
    *)
      if [[ -z "$NETBIRD_MGMT_URL" ]]; then
        msg_warn "Invalid selection. Run 'netbird up --management-url <url>' to connect."
      else
        msg_warn "Invalid selection. Run 'netbird up --management-url $NETBIRD_MGMT_URL' to connect."
      fi
      ;;
  esac
fi

motd_ssh
customize
cleanup_lxc
