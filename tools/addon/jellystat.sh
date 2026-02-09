#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/CyferShepard/Jellystat

if ! command -v curl &>/dev/null; then
  printf "\r\e[2K%b" '\033[93m Setup Source \033[m' >&2
  apt-get update >/dev/null 2>&1
  apt-get install -y curl >/dev/null 2>&1
fi
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# ==============================================================================
# CONFIGURATION
# ==============================================================================
APP="Jellystat"
APP_TYPE="addon"
INSTALL_PATH="/opt/jellystat"
CONFIG_PATH="/opt/jellystat/.env"
DEFAULT_PORT=3000

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

# ==============================================================================
# HEADER
# ==============================================================================
function header_info {
  clear
  cat <<"EOF"
       __     ____           __        __
      / /__  / / /_  _______/ /_____ _/ /_
 __  / / _ \/ / / / / / ___/ __/ __ `/ __/
/ /_/ /  __/ / / /_/ (__  ) /_/ /_/ / /_
\____/\___/_/_/\__, /____/\__/\__,_/\__/
              /____/
EOF
}

# ==============================================================================
# OS DETECTION
# ==============================================================================
if [[ -f "/etc/alpine-release" ]]; then
  msg_error "Alpine is not supported for ${APP}. Use Debian/Ubuntu."
  exit 1
elif [[ -f "/etc/debian_version" ]]; then
  OS="Debian"
  SERVICE_PATH="/etc/systemd/system/jellystat.service"
else
  echo -e "${CROSS} Unsupported OS detected. Exiting."
  exit 1
fi

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling ${APP}"
  systemctl disable --now jellystat.service &>/dev/null || true
  rm -f "$SERVICE_PATH"
  rm -rf "$INSTALL_PATH"
  rm -f "/usr/local/bin/update_jellystat"
  rm -f "$HOME/.jellystat"
  msg_ok "${APP} has been uninstalled"

  # Ask about PostgreSQL database removal
  echo ""
  echo -n "${TAB}Also remove PostgreSQL database 'jellystat'? (y/N): "
  read -r db_prompt
  if [[ "${db_prompt,,}" =~ ^(y|yes)$ ]]; then
    if command -v psql &>/dev/null; then
      msg_info "Removing PostgreSQL database and user"
      $STD sudo -u postgres psql -c "DROP DATABASE IF EXISTS jellystat;" &>/dev/null || true
      $STD sudo -u postgres psql -c "DROP USER IF EXISTS jellystat;" &>/dev/null || true
      msg_ok "Removed PostgreSQL database 'jellystat' and user 'jellystat'"
    else
      msg_warn "PostgreSQL not found - database may have been removed already"
    fi
  else
    msg_warn "PostgreSQL database was NOT removed. Remove manually if needed:"
    echo -e "${TAB}  sudo -u postgres psql -c \"DROP DATABASE jellystat;\""
    echo -e "${TAB}  sudo -u postgres psql -c \"DROP USER jellystat;\""
  fi
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  if check_for_gh_release "jellystat" "CyferShepard/Jellystat"; then
    msg_info "Stopping service"
    systemctl stop jellystat.service &>/dev/null || true
    msg_ok "Stopped service"

    msg_info "Backing up configuration"
    cp "$CONFIG_PATH" /tmp/jellystat.env.bak 2>/dev/null || true
    msg_ok "Backed up configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "jellystat" "CyferShepard/Jellystat" "tarball" "latest" "$INSTALL_PATH"

    msg_info "Restoring configuration"
    cp /tmp/jellystat.env.bak "$CONFIG_PATH" 2>/dev/null || true
    rm -f /tmp/jellystat.env.bak
    msg_ok "Restored configuration"

    msg_info "Installing dependencies"
    cd "$INSTALL_PATH"
    $STD npm install
    msg_ok "Installed dependencies"

    msg_info "Building ${APP}"
    $STD npm run build
    msg_ok "Built ${APP}"

    msg_info "Starting service"
    systemctl start jellystat
    msg_ok "Started service"
    msg_ok "Updated successfully"
    exit
  fi
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  # Setup Node.js (only installs if not present or different version)
  if command -v node &>/dev/null; then
    msg_ok "Node.js already installed ($(node -v))"
  else
    NODE_VERSION="22" setup_nodejs
  fi

  # Setup PostgreSQL (only installs if not present)
  if command -v psql &>/dev/null; then
    msg_ok "PostgreSQL already installed"
  else
    PG_VERSION="17" setup_postgresql
  fi

  # Create database and user (skip if already exists)
  local DB_NAME="jellystat"
  local DB_USER="jellystat"
  local DB_PASS

  msg_info "Setting up PostgreSQL database"

  # Check if database already exists
  if sudo -u postgres psql -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    msg_warn "Database '${DB_NAME}' already exists - skipping creation"
    echo -n "${TAB}Enter existing database password for '${DB_USER}': "
    read -rs DB_PASS
    echo ""
  else
    # Generate new password
    DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c16)

    # Check if user exists, create if not
    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" 2>/dev/null | grep -q 1; then
      msg_info "User '${DB_USER}' exists, updating password"
      $STD sudo -u postgres psql -c "ALTER USER ${DB_USER} WITH PASSWORD '${DB_PASS}';" || {
        msg_error "Failed to update PostgreSQL user"
        return 1
      }
    else
      $STD sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';" || {
        msg_error "Failed to create PostgreSQL user"
        return 1
      }
    fi

    # Create database (use template0 for UTF8 encoding compatibility)
    $STD sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} WITH OWNER ${DB_USER} ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' TEMPLATE template0;" || {
      msg_error "Failed to create PostgreSQL database"
      return 1
    }
    $STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};" || {
      msg_error "Failed to grant privileges"
      return 1
    }

    # Grant schema permissions (required for PostgreSQL 15+)
    $STD sudo -u postgres psql -d "${DB_NAME}" -c "GRANT ALL ON SCHEMA public TO ${DB_USER};" || true

    # Configure pg_hba.conf for password authentication on localhost
    local PG_HBA
    PG_HBA=$(sudo -u postgres psql -tAc "SHOW hba_file;" 2>/dev/null | tr -d ' ')
    if [[ -n "$PG_HBA" && -f "$PG_HBA" ]]; then
      # Check if md5/scram-sha-256 auth is already configured for local connections
      if ! grep -qE "^host\s+${DB_NAME}\s+${DB_USER}\s+127.0.0.1" "$PG_HBA"; then
        msg_info "Configuring PostgreSQL authentication"
        # Add password auth for jellystat user on localhost (before the default rules)
        sed -i "/^# IPv4 local connections:/a host    ${DB_NAME}    ${DB_USER}    127.0.0.1/32    scram-sha-256" "$PG_HBA"
        sed -i "/^# IPv4 local connections:/a host    ${DB_NAME}    ${DB_USER}    ::1/128         scram-sha-256" "$PG_HBA"
        # Reload PostgreSQL to apply changes
        systemctl reload postgresql
        msg_ok "Configured PostgreSQL authentication"
      fi
    fi

    msg_ok "Created PostgreSQL database '${DB_NAME}'"
  fi

  # Generate JWT Secret
  local JWT_SECRET
  JWT_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c32)

  # Force fresh download by removing version cache
  rm -f "$HOME/.jellystat"
  fetch_and_deploy_gh_release "jellystat" "CyferShepard/Jellystat" "tarball" "latest" "$INSTALL_PATH"

  msg_info "Installing dependencies"
  cd "$INSTALL_PATH"
  $STD npm install
  msg_ok "Installed dependencies"

  msg_info "Building ${APP}"
  $STD npm run build
  msg_ok "Built ${APP}"

  msg_info "Creating configuration"
  cat <<EOF >"$CONFIG_PATH"
# Jellystat Configuration
# Database
POSTGRES_USER=${DB_USER}
POSTGRES_PASSWORD=${DB_PASS}
POSTGRES_IP=localhost
POSTGRES_PORT=5432
POSTGRES_DB=${DB_NAME}

# Security
JWT_SECRET=${JWT_SECRET}

# Server
JS_LISTEN_IP=0.0.0.0
JS_BASE_URL=/
TZ=$(cat /etc/timezone 2>/dev/null || echo "UTC")

# Optional: GeoLite for IP Geolocation
# JS_GEOLITE_ACCOUNT_ID=
# JS_GEOLITE_LICENSE_KEY=

# Optional: Master Override (if you forget your password)
# JS_USER=admin
# JS_PASSWORD=admin

# Optional: Minimum playback duration to record (seconds)
# MINIMUM_SECONDS_TO_INCLUDE_PLAYBACK=1

# Optional: Self-signed certificates
REJECT_SELF_SIGNED_CERTIFICATES=true
EOF
  chmod 600 "$CONFIG_PATH"
  msg_ok "Created configuration"

  msg_info "Creating service"
  cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=Jellystat - Statistics for Jellyfin
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_PATH}/backend
EnvironmentFile=${CONFIG_PATH}
ExecStart=/usr/bin/node ${INSTALL_PATH}/backend/server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable --now jellystat &>/dev/null
  msg_ok "Created and started service"

  # Create update script (simple wrapper that calls this addon with type=update)
  msg_info "Creating update script"
  cat <<'UPDATEEOF' >/usr/local/bin/update_jellystat
#!/usr/bin/env bash
# Jellystat Update Script
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/jellystat.sh)"
UPDATEEOF
  chmod +x /usr/local/bin/update_jellystat
  msg_ok "Created update script (/usr/local/bin/update_jellystat)"

  # Save credentials
  local CREDS_FILE="/root/jellystat.creds"
  cat <<EOF >"$CREDS_FILE"
Jellystat Credentials
=====================
Database User: ${DB_USER}
Database Password: ${DB_PASS}
Database Name: ${DB_NAME}
JWT Secret: ${JWT_SECRET}

Web UI: http://${LOCAL_IP}:${DEFAULT_PORT}
EOF
  chmod 600 "$CREDS_FILE"

  echo ""
  msg_ok "${APP} is reachable at: ${BL}http://${LOCAL_IP}:${DEFAULT_PORT}${CL}"
  msg_ok "Credentials saved to: ${BL}${CREDS_FILE}${CL}"
  echo ""
  msg_warn "On first access, you'll need to configure your Jellyfin server connection."
}

# ==============================================================================
# MAIN
# ==============================================================================

# Handle type=update (called from update script)
if [[ "${type:-}" == "update" ]]; then
  header_info
  if [[ -d "$INSTALL_PATH" && -f "$INSTALL_PATH/package.json" ]]; then
    update
  else
    msg_error "${APP} is not installed. Nothing to update."
    exit 1
  fi
  exit 0
fi

header_info
get_lxc_ip

# Check if already installed
if [[ -d "$INSTALL_PATH" && -f "$INSTALL_PATH/package.json" ]]; then
  msg_warn "${APP} is already installed."
  echo ""

  echo -n "${TAB}Uninstall ${APP}? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    uninstall
    exit 0
  fi

  echo -n "${TAB}Update ${APP}? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    update
    exit 0
  fi

  msg_warn "No action selected. Exiting."
  exit 0
fi

# Fresh installation
msg_warn "${APP} is not installed."
echo ""
echo -e "${TAB}${INFO} This will install:"
echo -e "${TAB}  - Node.js 22"
echo -e "${TAB}  - PostgreSQL 17"
echo -e "${TAB}  - Jellystat"
echo ""

echo -n "${TAB}Install ${APP}? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "Installation cancelled. Exiting."
  exit 0
fi
