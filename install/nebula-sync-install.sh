#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: gabriel403
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/lovelaze/nebula-sync

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

INSTALL_PATH="/opt/nebula-sync"
ENV_PATH="/opt/nebula-sync/.env"
SERVICE_PATH="/etc/systemd/system/nebula-sync.service"

msg_info "Installing Dependencies"
$STD apt install -y curl wget
msg_ok "Installed Dependencies"

msg_info "Downloading Nebula-Sync"
mkdir -p "$INSTALL_PATH"
cd "$INSTALL_PATH"

# Get latest release
LATEST_RELEASE=$(curl -fsSL https://api.github.com/repos/lovelaze/nebula-sync/releases/latest | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
ARCH=$(uname -m)
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64) ARCH="arm64" ;;
  armv7l) ARCH="armv7" ;;
  *) msg_error "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Download binary
VERSION_NO_V="${LATEST_RELEASE#v}"
BINARY_URL="https://github.com/lovelaze/nebula-sync/releases/download/${LATEST_RELEASE}/nebula-sync_${VERSION_NO_V}_linux_${ARCH}.tar.gz"
curl -fSL -o nebula-sync.tar.gz "$BINARY_URL" || {
  msg_error "Failed to download Nebula-Sync binary from ${BINARY_URL}"
  exit 1
}
tar -xzf nebula-sync.tar.gz
rm nebula-sync.tar.gz
chmod +x nebula-sync
msg_ok "Downloaded Nebula-Sync ${LATEST_RELEASE}"

# Gather configuration from user
echo ""
echo -e "${BL}Nebula-Sync Configuration${CL}"
echo "─────────────────────────────────────────"
echo "Enter details for your Pi-hole instances."
echo "The Primary is your source instance, Replica will sync from it."
echo ""

# Primary instance
echo -e "${YW}── Primary (Source) Pi-hole Instance ──${CL}"
read -rp "${TAB3}Primary Pi-hole URL/IP (e.g., http://192.168.1.1 or 192.168.1.1): " PRIMARY_URL_INPUT
PRIMARY_URL_INPUT="${PRIMARY_URL_INPUT:-http://192.168.1.1}"
# Add http:// if no protocol specified
[[ ! "$PRIMARY_URL_INPUT" =~ ^https?:// ]] && PRIMARY_URL_INPUT="http://${PRIMARY_URL_INPUT}"
# Remove trailing slash
PRIMARY_URL_INPUT="${PRIMARY_URL_INPUT%/}"
read -rsp "${TAB3}Primary Pi-hole API Password: " PRIMARY_PASSWORD_INPUT
echo ""
if [[ -z "$PRIMARY_PASSWORD_INPUT" ]]; then
  msg_error "Primary API password cannot be empty!"
  exit 1
fi

# Replica instance
echo ""
echo -e "${YW}── Replica Pi-hole Instance ──${CL}"
read -rp "${TAB3}Replica Pi-hole URL/IP (e.g., http://192.168.1.2 or 192.168.1.2): " REPLICAS_URL_INPUT
REPLICAS_URL_INPUT="${REPLICAS_URL_INPUT:-http://192.168.1.2}"
# Add http:// if no protocol specified
[[ ! "$REPLICAS_URL_INPUT" =~ ^https?:// ]] && REPLICAS_URL_INPUT="http://${REPLICAS_URL_INPUT}"
# Remove trailing slash
REPLICAS_URL_INPUT="${REPLICAS_URL_INPUT%/}"
read -rsp "${TAB3}Replica Pi-hole API Password: " REPLICAS_PASSWORD_INPUT
echo ""
if [[ -z "$REPLICAS_PASSWORD_INPUT" ]]; then
  msg_error "Replica API password cannot be empty!"
  exit 1
fi

# Sync options
echo ""
echo -e "${BL}Sync Options${CL}"
echo "─────────────────────────────────────────"
echo "What should Nebula-Sync synchronize?"
echo ""
echo " 1) Sync all settings (default)"
echo " 2) Custom selection"
echo ""
read -r -p "${TAB3}Select sync mode [1]: " SYNC_MODE
SYNC_MODE="${SYNC_MODE:-1}"

FULL_SYNC="true"
if [[ "$SYNC_MODE" == "2" ]]; then
  FULL_SYNC="false"
  echo ""
  echo -e "${BL}Custom Sync Selection${CL}"
  echo "─────────────────────────────────────────"
  echo "Select which items to synchronize (y/n):"
  echo ""
  
  read -rp "${TAB3}Sync DNS configuration? [y/N]: " SYNC_CONFIG_DNS_INPUT
  SYNC_CONFIG_DNS="${SYNC_CONFIG_DNS_INPUT:-n}"
  [[ "$SYNC_CONFIG_DNS" =~ ^[yY] ]] && SYNC_CONFIG_DNS="true" || SYNC_CONFIG_DNS="false"
  
  read -rp "${TAB3}Sync DHCP configuration? [y/N]: " SYNC_CONFIG_DHCP_INPUT
  SYNC_CONFIG_DHCP="${SYNC_CONFIG_DHCP_INPUT:-n}"
  [[ "$SYNC_CONFIG_DHCP" =~ ^[yY] ]] && SYNC_CONFIG_DHCP="true" || SYNC_CONFIG_DHCP="false"
  
  read -rp "${TAB3}Sync NTP configuration? [y/N]: " SYNC_CONFIG_NTP_INPUT
  SYNC_CONFIG_NTP="${SYNC_CONFIG_NTP_INPUT:-n}"
  [[ "$SYNC_CONFIG_NTP" =~ ^[yY] ]] && SYNC_CONFIG_NTP="true" || SYNC_CONFIG_NTP="false"
  
  read -rp "${TAB3}Sync Resolver configuration? [y/N]: " SYNC_CONFIG_RESOLVER_INPUT
  SYNC_CONFIG_RESOLVER="${SYNC_CONFIG_RESOLVER_INPUT:-n}"
  [[ "$SYNC_CONFIG_RESOLVER" =~ ^[yY] ]] && SYNC_CONFIG_RESOLVER="true" || SYNC_CONFIG_RESOLVER="false"
  
  read -rp "${TAB3}Sync Database configuration? [y/N]: " SYNC_CONFIG_DATABASE_INPUT
  SYNC_CONFIG_DATABASE="${SYNC_CONFIG_DATABASE_INPUT:-n}"
  [[ "$SYNC_CONFIG_DATABASE" =~ ^[yY] ]] && SYNC_CONFIG_DATABASE="true" || SYNC_CONFIG_DATABASE="false"
  
  read -rp "${TAB3}Sync Miscellaneous settings? [y/N]: " SYNC_CONFIG_MISC_INPUT
  SYNC_CONFIG_MISC="${SYNC_CONFIG_MISC_INPUT:-n}"
  [[ "$SYNC_CONFIG_MISC" =~ ^[yY] ]] && SYNC_CONFIG_MISC="true" || SYNC_CONFIG_MISC="false"
  
  read -rp "${TAB3}Sync Debug settings? [y/N]: " SYNC_CONFIG_DEBUG_INPUT
  SYNC_CONFIG_DEBUG="${SYNC_CONFIG_DEBUG_INPUT:-n}"
  [[ "$SYNC_CONFIG_DEBUG" =~ ^[yY] ]] && SYNC_CONFIG_DEBUG="true" || SYNC_CONFIG_DEBUG="false"
  
  read -rp "${TAB3}Sync DHCP leases? [y/N]: " SYNC_GRAVITY_DHCP_LEASES_INPUT
  SYNC_GRAVITY_DHCP_LEASES="${SYNC_GRAVITY_DHCP_LEASES_INPUT:-n}"
  [[ "$SYNC_GRAVITY_DHCP_LEASES" =~ ^[yY] ]] && SYNC_GRAVITY_DHCP_LEASES="true" || SYNC_GRAVITY_DHCP_LEASES="false"
  
  read -rp "${TAB3}Sync Groups? [y/N]: " SYNC_GRAVITY_GROUP_INPUT
  SYNC_GRAVITY_GROUP="${SYNC_GRAVITY_GROUP_INPUT:-n}"
  [[ "$SYNC_GRAVITY_GROUP" =~ ^[yY] ]] && SYNC_GRAVITY_GROUP="true" || SYNC_GRAVITY_GROUP="false"
  
  read -rp "${TAB3}Sync Ad Lists? [y/N]: " SYNC_GRAVITY_AD_LIST_INPUT
  SYNC_GRAVITY_AD_LIST="${SYNC_GRAVITY_AD_LIST_INPUT:-n}"
  [[ "$SYNC_GRAVITY_AD_LIST" =~ ^[yY] ]] && SYNC_GRAVITY_AD_LIST="true" || SYNC_GRAVITY_AD_LIST="false"
  
  read -rp "${TAB3}Sync Ad Lists by Group? [y/N]: " SYNC_GRAVITY_AD_LIST_BY_GROUP_INPUT
  SYNC_GRAVITY_AD_LIST_BY_GROUP="${SYNC_GRAVITY_AD_LIST_BY_GROUP_INPUT:-n}"
  [[ "$SYNC_GRAVITY_AD_LIST_BY_GROUP" =~ ^[yY] ]] && SYNC_GRAVITY_AD_LIST_BY_GROUP="true" || SYNC_GRAVITY_AD_LIST_BY_GROUP="false"
  
  read -rp "${TAB3}Sync Domain Lists? [y/N]: " SYNC_GRAVITY_DOMAIN_LIST_INPUT
  SYNC_GRAVITY_DOMAIN_LIST="${SYNC_GRAVITY_DOMAIN_LIST_INPUT:-n}"
  [[ "$SYNC_GRAVITY_DOMAIN_LIST" =~ ^[yY] ]] && SYNC_GRAVITY_DOMAIN_LIST="true" || SYNC_GRAVITY_DOMAIN_LIST="false"
  
  read -rp "${TAB3}Sync Domain Lists by Group? [y/N]: " SYNC_GRAVITY_DOMAIN_LIST_BY_GROUP_INPUT
  SYNC_GRAVITY_DOMAIN_LIST_BY_GROUP="${SYNC_GRAVITY_DOMAIN_LIST_BY_GROUP_INPUT:-n}"
  [[ "$SYNC_GRAVITY_DOMAIN_LIST_BY_GROUP" =~ ^[yY] ]] && SYNC_GRAVITY_DOMAIN_LIST_BY_GROUP="true" || SYNC_GRAVITY_DOMAIN_LIST_BY_GROUP="false"
  
  read -rp "${TAB3}Sync Clients? [y/N]: " SYNC_GRAVITY_CLIENT_INPUT
  SYNC_GRAVITY_CLIENT="${SYNC_GRAVITY_CLIENT_INPUT:-n}"
  [[ "$SYNC_GRAVITY_CLIENT" =~ ^[yY] ]] && SYNC_GRAVITY_CLIENT="true" || SYNC_GRAVITY_CLIENT="false"
  
  read -rp "${TAB3}Sync Clients by Group? [y/N]: " SYNC_GRAVITY_CLIENT_BY_GROUP_INPUT
  SYNC_GRAVITY_CLIENT_BY_GROUP="${SYNC_GRAVITY_CLIENT_BY_GROUP_INPUT:-n}"
  [[ "$SYNC_GRAVITY_CLIENT_BY_GROUP" =~ ^[yY] ]] && SYNC_GRAVITY_CLIENT_BY_GROUP="true" || SYNC_GRAVITY_CLIENT_BY_GROUP="false"
fi

# Sync interval
echo ""
read -rp "${TAB3}Sync interval (cron expression, default: 0 */2 * * *): " SYNC_INTERVAL_INPUT
SYNC_INTERVAL="${SYNC_INTERVAL_INPUT:-0 */2 * * *}"

msg_info "Creating configuration"
# Validate required variables are set
if [[ -z "$PRIMARY_URL_INPUT" ]] || [[ -z "$PRIMARY_PASSWORD_INPUT" ]] || [[ -z "$REPLICAS_URL_INPUT" ]] || [[ -z "$REPLICAS_PASSWORD_INPUT" ]]; then
  msg_error "Missing required configuration values!"
  exit 1
fi

# nebula-sync expects PRIMARY and REPLICAS in format: http://hostname|password
# Write .env file in the format nebula-sync expects
# Use printf to safely handle special characters in passwords
{
  printf "PRIMARY=%s|%s\n" "$PRIMARY_URL_INPUT" "$PRIMARY_PASSWORD_INPUT"
  printf "REPLICAS=%s|%s\n" "$REPLICAS_URL_INPUT" "$REPLICAS_PASSWORD_INPUT"
  printf "CRON=%s\n" "$SYNC_INTERVAL"
  printf "FULL_SYNC=%s\n" "$FULL_SYNC"
  printf "CLIENT_SKIP_TLS_VERIFICATION=true\n"
} > "$ENV_PATH"

# Add individual sync flags if custom mode
if [[ "$FULL_SYNC" == "false" ]]; then
  cat <<EOF >>"$ENV_PATH"
SYNC_CONFIG_DNS=${SYNC_CONFIG_DNS}
SYNC_CONFIG_DHCP=${SYNC_CONFIG_DHCP}
SYNC_CONFIG_NTP=${SYNC_CONFIG_NTP}
SYNC_CONFIG_RESOLVER=${SYNC_CONFIG_RESOLVER}
SYNC_CONFIG_DATABASE=${SYNC_CONFIG_DATABASE}
SYNC_CONFIG_MISC=${SYNC_CONFIG_MISC}
SYNC_CONFIG_DEBUG=${SYNC_CONFIG_DEBUG}
SYNC_GRAVITY_DHCP_LEASES=${SYNC_GRAVITY_DHCP_LEASES}
SYNC_GRAVITY_GROUP=${SYNC_GRAVITY_GROUP}
SYNC_GRAVITY_AD_LIST=${SYNC_GRAVITY_AD_LIST}
SYNC_GRAVITY_AD_LIST_BY_GROUP=${SYNC_GRAVITY_AD_LIST_BY_GROUP}
SYNC_GRAVITY_DOMAIN_LIST=${SYNC_GRAVITY_DOMAIN_LIST}
SYNC_GRAVITY_DOMAIN_LIST_BY_GROUP=${SYNC_GRAVITY_DOMAIN_LIST_BY_GROUP}
SYNC_GRAVITY_CLIENT=${SYNC_GRAVITY_CLIENT}
SYNC_GRAVITY_CLIENT_BY_GROUP=${SYNC_GRAVITY_CLIENT_BY_GROUP}
EOF
fi

chmod 600 "$ENV_PATH"
# Verify .env file was created and has content
if [[ ! -f "$ENV_PATH" ]] || [[ ! -s "$ENV_PATH" ]]; then
  msg_error "Failed to create .env file at $ENV_PATH"
  exit 1
fi
# Verify required variables are in the file
if ! grep -q "^PRIMARY=" "$ENV_PATH" || ! grep -q "^REPLICAS=" "$ENV_PATH"; then
  msg_error ".env file is missing required variables"
  exit 1
fi
msg_ok "Created configuration"

msg_info "Creating wrapper script"
# Create a wrapper script that properly sources the .env file
cat <<'EOFWRAPPER' >"${INSTALL_PATH}/nebula-sync-wrapper.sh"
#!/bin/bash
set -e
ENV_FILE="/opt/nebula-sync/.env"
BINARY="/opt/nebula-sync/nebula-sync"

# Load environment variables from .env file
if [[ -f "$ENV_FILE" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    # Only process lines that look like KEY=VALUE
    if [[ "$line" =~ ^[A-Z_][A-Z0-9_]*= ]]; then
      key="${line%%=*}"
      value="${line#*=}"
      export "$key"="$value"
    fi
  done < "$ENV_FILE"
fi

# Execute nebula-sync
exec "$BINARY" run
EOFWRAPPER
chmod +x "${INSTALL_PATH}/nebula-sync-wrapper.sh"
msg_ok "Created wrapper script"

msg_info "Creating service"
cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=Nebula-Sync - Pi-hole Configuration Synchronization
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_PATH}
ExecStart=${INSTALL_PATH}/nebula-sync-wrapper.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

# Verify the service can read the environment file
msg_info "Verifying service configuration"
if [[ -f "$ENV_PATH" ]]; then
  # Test that environment variables can be loaded
  set +u  # Allow unset variables for verification
  set -a
  source "$ENV_PATH" 2>/dev/null || true
  set +a
  if [[ -z "${PRIMARY:-}" ]] || [[ -z "${REPLICAS:-}" ]]; then
    msg_warn "Environment variables not loading correctly from $ENV_PATH"
    msg_info "File contents:"
    cat "$ENV_PATH" | head -5
  else
    msg_ok "Environment variables verified"
  fi
  set -u  # Re-enable unset variable checking
else
  msg_error ".env file not found at $ENV_PATH"
  exit 1
fi

systemctl enable --now nebula-sync &>/dev/null
msg_ok "Created and started service"

# Create update script
msg_info "Creating update script"
cat <<'UPDATEEOF' >/usr/local/bin/update_nebula-sync
#!/usr/bin/env bash
# Nebula-Sync Update Script
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
load_functions

INSTALL_PATH="/opt/nebula-sync"
ENV_PATH="/opt/nebula-sync/.env"

if [[ ! -f "$INSTALL_PATH/nebula-sync" ]]; then
  msg_error "Nebula-Sync installation not found!"
  exit 1
fi

msg_info "Stopping service"
systemctl stop nebula-sync.service &>/dev/null || true
msg_ok "Stopped service"

msg_info "Backing up configuration"
cp "$ENV_PATH" /tmp/nebula-sync.env.bak 2>/dev/null || true
msg_ok "Backed up configuration"

msg_info "Detecting latest Nebula-Sync release"
LATEST_RELEASE=$(curl -fsSL https://api.github.com/repos/lovelaze/nebula-sync/releases/latest | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
ARCH=$(uname -m)
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64) ARCH="arm64" ;;
  armv7l) ARCH="armv7" ;;
  *) msg_error "Unsupported architecture: $ARCH"; exit 1 ;;
esac
msg_ok "Detected Nebula-Sync ${LATEST_RELEASE}"

msg_info "Downloading Nebula-Sync"
cd "$INSTALL_PATH"
VERSION_NO_V="${LATEST_RELEASE#v}"
BINARY_URL="https://github.com/lovelaze/nebula-sync/releases/download/${LATEST_RELEASE}/nebula-sync_${VERSION_NO_V}_linux_${ARCH}.tar.gz"
curl -fSL -o nebula-sync.tar.gz "$BINARY_URL" || {
  msg_error "Failed to download Nebula-Sync binary from ${BINARY_URL}"
  exit 1
}
tar -xzf nebula-sync.tar.gz
rm nebula-sync.tar.gz
chmod +x nebula-sync
msg_ok "Downloaded Nebula-Sync"

msg_info "Restoring configuration"
cp /tmp/nebula-sync.env.bak "$ENV_PATH" 2>/dev/null || true
rm -f /tmp/nebula-sync.env.bak
msg_ok "Restored configuration"

msg_info "Saving version"
echo "${LATEST_RELEASE}" > "/opt/nebula-sync_version.txt"
msg_ok "Saved version"

msg_info "Starting service"
systemctl start nebula-sync.service
msg_ok "Started service"
msg_ok "Updated successfully!"
UPDATEEOF

chmod +x /usr/local/bin/update_nebula-sync
msg_ok "Created update script"

# Save version for update checks
echo "$LATEST_RELEASE" > "/opt/nebula-sync_version.txt"

motd_ssh
customize
cleanup_lxc
