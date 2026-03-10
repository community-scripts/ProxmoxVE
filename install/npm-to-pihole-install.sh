#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: lazarh
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/CypriotUnknown/npm-to-pihole

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  curl \
  jq \
  inotify-tools
msg_ok "Installed Dependencies"

# Skip full install if called with --update-only (from update_script)
if [[ "${1}" == "--update-only" ]]; then
  msg_info "Updating sync script"
  curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/install/npm-to-pihole-install.sh \
    | grep -A9999 '# --- BEGIN SYNC SCRIPT ---' \
    | grep -B9999 '# --- END SYNC SCRIPT ---' \
    | grep -v '# --- ' \
    > /opt/npm-to-pihole/npm-to-pihole.sh
  chmod +x /opt/npm-to-pihole/npm-to-pihole.sh
  systemctl restart npm-to-pihole
  msg_ok "Updated sync script"
  exit 0
fi

msg_info "Setting up NPM-to-PiHole"
mkdir -p /opt/npm-to-pihole

# Write default config (user must edit this)
cat <<'CONFIGEOF' >/opt/npm-to-pihole/config
# NPM-to-PiHole Configuration
# Edit these values before starting the service.

# Path to Nginx Proxy Manager's proxy_host directory.
# When running NPM in an LXC, set up a Proxmox bind mount:
#   e.g., mp0: /path/on/host/npm/data/nginx/proxy_host,mp=/mnt/npm/proxy_host
# For NPM on another host, use NFS or SFTP.
NPM_PROXY_HOST_DIR="/mnt/npm/proxy_host"

# Pi-hole URL (no trailing slash)
PIHOLE_URL="http://192.168.1.x"

# Pi-hole admin password (used to authenticate with the API)
PIHOLE_PASSWORD=""

# IP address that all synced DNS records should point to (typically NPM's IP)
TARGET_IP="192.168.1.x"

# How often to check for changes, in seconds (default: 300 = 5 minutes)
SYNC_INTERVAL=300

# Pi-hole API version: 6 (default, uses REST API) or 5 (uses custom.list file via local bind mount)
PIHOLE_VERSION=6
CONFIGEOF

msg_ok "Created default config at /opt/npm-to-pihole/config"

# Write the main sync script
# --- BEGIN SYNC SCRIPT ---
cat <<'SYNCEOF' >/opt/npm-to-pihole/npm-to-pihole.sh
#!/usr/bin/env bash
# NPM-to-PiHole sync daemon
# Reads Nginx Proxy Manager proxy_host config files and syncs server_name
# entries to Pi-hole local DNS records.

set -euo pipefail

CONFIG_FILE="/opt/npm-to-pihole/config"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: Config file not found at $CONFIG_FILE"
  exit 1
fi

# shellcheck source=/opt/npm-to-pihole/config
source "$CONFIG_FILE"

###############################################################################
# Pi-hole v6 API helpers (REST API with session token)
###############################################################################

PIHOLE_TOKEN=""

pihole6_authenticate() {
  local response
  response=$(curl -fsSL -X POST \
    --insecure \
    -H "Content-Type: application/json" \
    -d "{\"password\":\"${PIHOLE_PASSWORD}\"}" \
    "${PIHOLE_URL}/api/auth" 2>/dev/null) || {
      echo "ERROR: Failed to authenticate with Pi-hole at ${PIHOLE_URL}"
      return 1
    }
  PIHOLE_TOKEN=$(echo "$response" | jq -r '.session.sid // empty')
  if [[ -z "$PIHOLE_TOKEN" ]]; then
    echo "ERROR: Authentication failed - check PIHOLE_URL and PIHOLE_PASSWORD"
    return 1
  fi
}

pihole6_get_records() {
  curl -fsSL --insecure \
    -H "X-FTL-SID: ${PIHOLE_TOKEN}" \
    "${PIHOLE_URL}/api/dns/records" 2>/dev/null \
    | jq -r '.records[] | select(.type == "A" or .type == "CNAME") | .name' 2>/dev/null \
    || true
}

pihole6_add_record() {
  local domain="$1"
  curl -fsSL --insecure -X POST \
    -H "Content-Type: application/json" \
    -H "X-FTL-SID: ${PIHOLE_TOKEN}" \
    -d "{\"domain\":\"${domain}\",\"ip\":\"${TARGET_IP}\"}" \
    "${PIHOLE_URL}/api/dns/records" >/dev/null 2>&1
}

pihole6_remove_record() {
  local domain="$1"
  curl -fsSL --insecure -X DELETE \
    -H "Content-Type: application/json" \
    -H "X-FTL-SID: ${PIHOLE_TOKEN}" \
    -d "{\"domain\":\"${domain}\",\"ip\":\"${TARGET_IP}\"}" \
    "${PIHOLE_URL}/api/dns/records" >/dev/null 2>&1
}

pihole6_logout() {
  [[ -z "$PIHOLE_TOKEN" ]] && return
  curl -fsSL --insecure -X DELETE \
    -H "X-FTL-SID: ${PIHOLE_TOKEN}" \
    "${PIHOLE_URL}/api/auth" >/dev/null 2>&1
  PIHOLE_TOKEN=""
}

###############################################################################
# Pi-hole v5 helpers (direct custom.list file manipulation)
# Requires Pi-hole's /etc/pihole/custom.list to be bind-mounted or local.
###############################################################################

PIHOLE_CUSTOM_LIST="${PIHOLE_CUSTOM_LIST:-/etc/pihole/custom.list}"

pihole5_get_records() {
  if [[ ! -f "$PIHOLE_CUSTOM_LIST" ]]; then
    echo "ERROR: Pi-hole custom.list not found at $PIHOLE_CUSTOM_LIST" >&2
    return 1
  fi
  grep -oP '(?<=\s)\S+$' "$PIHOLE_CUSTOM_LIST" 2>/dev/null || true
}

pihole5_add_record() {
  local domain="$1"
  if ! grep -qF "$domain" "$PIHOLE_CUSTOM_LIST" 2>/dev/null; then
    echo "${TARGET_IP} ${domain}" >> "$PIHOLE_CUSTOM_LIST"
    pihole restartdns reload 2>/dev/null || true
  fi
}

pihole5_remove_record() {
  local domain="$1"
  sed -i "/ ${domain}$/d" "$PIHOLE_CUSTOM_LIST"
  pihole restartdns reload 2>/dev/null || true
}

###############################################################################
# NPM proxy host parsing
###############################################################################

get_npm_domains() {
  # Extract server_name entries from all proxy_host .conf files
  # Returns one domain per line (skips localhost, *.wildcard entries)
  if [[ ! -d "$NPM_PROXY_HOST_DIR" ]]; then
    echo "ERROR: NPM proxy host directory not found: $NPM_PROXY_HOST_DIR" >&2
    return 1
  fi
  grep -rh 'server_name' "${NPM_PROXY_HOST_DIR}"/*.conf 2>/dev/null \
    | grep -oP 'server_name\s+\K[^;]+' \
    | tr ' ' '\n' \
    | sed 's/;//g' \
    | grep -v '^\*\.' \
    | grep -v '^localhost$' \
    | grep -v '^_$' \
    | grep -v '^$' \
    | sort -u \
    || true
}

###############################################################################
# Sync logic
###############################################################################

do_sync() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting sync..."

  # Get current NPM domains
  local npm_domains
  npm_domains=$(get_npm_domains) || { echo "Failed to read NPM domains"; return 1; }

  if [[ -z "$npm_domains" ]]; then
    echo "No domains found in NPM proxy hosts (check NPM_PROXY_HOST_DIR)"
    return 0
  fi

  # Get current Pi-hole records and compute diff
  local pihole_domains added=0 removed=0

  if [[ "$PIHOLE_VERSION" == "6" ]]; then
    pihole6_authenticate || return 1
    pihole_domains=$(pihole6_get_records)

    # Add missing records
    while IFS= read -r domain; do
      if ! echo "$pihole_domains" | grep -qxF "$domain"; then
        pihole6_add_record "$domain" && echo "  + Added: $domain" && ((added++)) || true
      fi
    done <<< "$npm_domains"

    # Remove stale records (only those pointing to TARGET_IP, to avoid touching unrelated records)
    while IFS= read -r domain; do
      [[ -z "$domain" ]] && continue
      if ! echo "$npm_domains" | grep -qxF "$domain"; then
        pihole6_remove_record "$domain" && echo "  - Removed: $domain" && ((removed++)) || true
      fi
    done <<< "$pihole_domains"

    pihole6_logout

  else
    pihole_domains=$(pihole5_get_records) || return 1

    while IFS= read -r domain; do
      if ! echo "$pihole_domains" | grep -qxF "$domain"; then
        pihole5_add_record "$domain" && echo "  + Added: $domain" && ((added++)) || true
      fi
    done <<< "$npm_domains"

    while IFS= read -r domain; do
      [[ -z "$domain" ]] && continue
      if ! echo "$npm_domains" | grep -qxF "$domain"; then
        pihole5_remove_record "$domain" && echo "  - Removed: $domain" && ((removed++)) || true
      fi
    done <<< "$pihole_domains"
  fi

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sync complete. Added: ${added}, Removed: ${removed}"
}

###############################################################################
# Main loop
###############################################################################

echo "[$(date '+%Y-%m-%d %H:%M:%S')] NPM-to-PiHole sync daemon starting..."
echo "  NPM dir:        $NPM_PROXY_HOST_DIR"
echo "  Pi-hole URL:    $PIHOLE_URL"
echo "  Target IP:      $TARGET_IP"
echo "  Sync interval:  ${SYNC_INTERVAL}s"
echo "  Pi-hole ver:    v${PIHOLE_VERSION}"

# Run once on start
do_sync || echo "Initial sync failed - will retry on next interval"

# Then loop on interval
while true; do
  sleep "$SYNC_INTERVAL"
  do_sync || echo "Sync failed - will retry on next interval"
done
SYNCEOF
# --- END SYNC SCRIPT ---

chmod +x /opt/npm-to-pihole/npm-to-pihole.sh
msg_ok "Created sync script at /opt/npm-to-pihole/npm-to-pihole.sh"

msg_info "Creating Service"
cat <<'EOF' >/etc/systemd/system/npm-to-pihole.service
[Unit]
Description=NPM-to-PiHole DNS Sync Service
Documentation=https://github.com/community-scripts/ProxmoxVE
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/opt/npm-to-pihole/npm-to-pihole.sh
Restart=on-failure
RestartSec=30
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q npm-to-pihole
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
