#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/documenso/documenso

APP="Documenso"
var_tags="${var_tags:-document}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/documenso ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  # Detect installation type and handle accordingly
  if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^documenso$"; then
    # Docker-based installation - simple update
    msg_info "Updating ${APP}"
    $STD docker pull documenso/documenso:latest
    $STD docker stop documenso
    $STD docker rm documenso

    # Restart with same config
    $STD docker run -d \
      --name documenso \
      --restart unless-stopped \
      --network host \
      --log-driver journald \
      --env-file /opt/documenso/.env \
      -v /opt/documenso/certs/cert.p12:/opt/documenso/cert.p12:ro \
      documenso/documenso:latest

    $STD docker image prune -f
    docker inspect documenso --format '{{.Config.Image}}' | cut -d: -f2 >/opt/documenso/.version
    msg_ok "Updated ${APP}"
  elif [[ -f /etc/systemd/system/documenso.service ]] && grep -q "turbo" /etc/systemd/system/documenso.service 2>/dev/null; then
    # Old source-based installation - migrate to Docker
    msg_warn "Legacy source-based installation detected"
    msg_info "Starting migration to Docker (your data will be preserved)"
    migrate_to_docker
    msg_ok "Migration complete"
  else
    msg_error "Unknown installation type"
    exit 1
  fi

  exit
}

function migrate_to_docker() {
  # ============================================
  # STEP 1: Extract existing configuration
  # ============================================
  msg_info "Extracting existing configuration"

  OLD_ENV="/opt/documenso/.env"

  # Critical: These MUST be preserved or data becomes unreadable
  NEXTAUTH_SECRET=$(grep "^NEXTAUTH_SECRET=" "$OLD_ENV" | cut -d'=' -f2- | tr -d "'" | tr -d '"')
  ENCRYPTION_KEY=$(grep "^NEXT_PRIVATE_ENCRYPTION_KEY=" "$OLD_ENV" | cut -d'=' -f2- | tr -d "'" | tr -d '"')
  ENCRYPTION_SECONDARY_KEY=$(grep "^NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY=" "$OLD_ENV" | cut -d'=' -f2- | tr -d "'" | tr -d '"')

  # Database connection - reuse existing URL directly
  DATABASE_URL=$(grep "^NEXT_PRIVATE_DATABASE_URL=" "$OLD_ENV" | cut -d'=' -f2- | tr -d "'" | tr -d '"')
  DIRECT_DATABASE_URL=$(grep "^NEXT_PRIVATE_DIRECT_DATABASE_URL=" "$OLD_ENV" | cut -d'=' -f2- | tr -d "'" | tr -d '"')
  # Fall back to DATABASE_URL if DIRECT not set
  DIRECT_DATABASE_URL=${DIRECT_DATABASE_URL:-$DATABASE_URL}

  # Optional: Extract SMTP if configured
  SMTP_HOST=$(grep "^NEXT_PRIVATE_SMTP_HOST=" "$OLD_ENV" 2>/dev/null | cut -d'=' -f2- | tr -d "'" | tr -d '"')
  SMTP_PORT=$(grep "^NEXT_PRIVATE_SMTP_PORT=" "$OLD_ENV" 2>/dev/null | cut -d'=' -f2- | tr -d "'" | tr -d '"')
  SMTP_USER=$(grep "^NEXT_PRIVATE_SMTP_USERNAME=" "$OLD_ENV" 2>/dev/null | cut -d'=' -f2- | tr -d "'" | tr -d '"')
  SMTP_PASS=$(grep "^NEXT_PRIVATE_SMTP_PASSWORD=" "$OLD_ENV" 2>/dev/null | cut -d'=' -f2- | tr -d "'" | tr -d '"')
  SMTP_FROM_NAME=$(grep "^NEXT_PRIVATE_SMTP_FROM_NAME=" "$OLD_ENV" 2>/dev/null | cut -d'=' -f2- | tr -d "'" | tr -d '"')
  SMTP_FROM_ADDR=$(grep "^NEXT_PRIVATE_SMTP_FROM_ADDRESS=" "$OLD_ENV" 2>/dev/null | cut -d'=' -f2- | tr -d "'" | tr -d '"')

  msg_ok "Extracted existing configuration"

  # ============================================
  # STEP 2: Validate critical values
  # ============================================
  if [[ -z "$NEXTAUTH_SECRET" ]] || [[ -z "$ENCRYPTION_KEY" ]] || [[ -z "$DATABASE_URL" ]]; then
    msg_error "Failed to extract critical configuration from .env"
    msg_error "Please check /opt/documenso/.env exists and contains required values"
    exit 1
  fi

  # ============================================
  # STEP 3: Stop old service
  # ============================================
  msg_info "Stopping existing Documenso service"
  systemctl stop documenso 2>/dev/null || true
  systemctl disable documenso 2>/dev/null || true
  msg_ok "Stopped existing service"

  # ============================================
  # STEP 4: Backup old installation
  # ============================================
  msg_info "Creating backup"
  BACKUP_DIR="/opt/documenso-source-backup-$(date +%Y%m%d_%H%M%S)"
  mv /opt/documenso "$BACKUP_DIR"

  # Also backup credentials if they exist
  [[ -f ~/documenso.creds ]] && cp ~/documenso.creds "${BACKUP_DIR}/"

  msg_ok "Backup created at $BACKUP_DIR"

  # ============================================
  # STEP 5: Install Docker (if not present)
  # ============================================
  if ! command -v docker &>/dev/null; then
    msg_info "Installing Docker"

    setup_deb822_repo \
      "docker" \
      "https://download.docker.com/linux/$(get_os_info id)/gpg" \
      "https://download.docker.com/linux/$(get_os_info id)" \
      "$(get_os_info codename)" \
      "stable" \
      "$(dpkg --print-architecture)"

    $STD apt-get update
    $STD apt-get install -y \
      docker-ce \
      docker-ce-cli \
      containerd.io \
      docker-compose-plugin

    msg_ok "Installed Docker"
  else
    msg_ok "Docker already installed"
  fi

  # ============================================
  # STEP 6: Generate certificate (old installs didn't have one)
  # ============================================
  msg_info "Generating signing certificate"
  mkdir -p /opt/documenso/certs

  CERT_PASSPHRASE=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | cut -c1-12)

  openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /tmp/documenso.key \
    -out /tmp/documenso.crt \
    -subj "/C=US/ST=Self-Hosted/L=Proxmox/O=Documenso/CN=documenso.local" 2>/dev/null

  openssl pkcs12 -export -legacy \
    -out /opt/documenso/certs/cert.p12 \
    -inkey /tmp/documenso.key \
    -in /tmp/documenso.crt \
    -passout "pass:${CERT_PASSPHRASE}" 2>/dev/null

  rm -f /tmp/documenso.key /tmp/documenso.crt
  chmod 644 /opt/documenso/certs/cert.p12
  msg_ok "Generated signing certificate"

  # ============================================
  # STEP 7: Create environment file
  # ============================================
  msg_info "Creating Docker configuration"
  LOCAL_IP=$(hostname -I | awk '{print $1}')

  cat <<EOF >/opt/documenso/.env
# Documenso Environment Configuration (Migrated)
PORT=3000

# Preserved from existing installation
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
NEXT_PRIVATE_ENCRYPTION_KEY=${ENCRYPTION_KEY}
NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY=${ENCRYPTION_SECONDARY_KEY}

# Database connection (unchanged)
NEXT_PRIVATE_DATABASE_URL=${DATABASE_URL}
NEXT_PRIVATE_DIRECT_DATABASE_URL=${DIRECT_DATABASE_URL}

# URLs
NEXT_PUBLIC_WEBAPP_URL=http://${LOCAL_IP}:3000

# Storage
NEXT_PUBLIC_UPLOAD_TRANSPORT=database

# SMTP
NEXT_PRIVATE_SMTP_TRANSPORT=smtp-auth
NEXT_PRIVATE_SMTP_FROM_NAME=${SMTP_FROM_NAME:-Documenso}
NEXT_PRIVATE_SMTP_FROM_ADDRESS=${SMTP_FROM_ADDR:-noreply@documenso.local}
EOF

  # Add SMTP settings if configured
  if [[ -n "$SMTP_HOST" ]]; then
    cat <<EOF >>/opt/documenso/.env
NEXT_PRIVATE_SMTP_HOST=${SMTP_HOST}
NEXT_PRIVATE_SMTP_PORT=${SMTP_PORT:-587}
NEXT_PRIVATE_SMTP_USERNAME=${SMTP_USER}
NEXT_PRIVATE_SMTP_PASSWORD=${SMTP_PASS}
EOF
  fi

  # Add certificate settings
  cat <<EOF >>/opt/documenso/.env

# Certificate
NEXT_PRIVATE_SIGNING_LOCAL_FILE_PATH=/opt/documenso/cert.p12
NEXT_PRIVATE_SIGNING_PASSPHRASE=${CERT_PASSPHRASE}
EOF

  chmod 600 /opt/documenso/.env
  msg_ok "Created Docker configuration"

  # ============================================
  # STEP 8: Update credentials file
  # ============================================
  msg_info "Updating credentials file"
  {
    echo "Documenso Credentials (Migrated)"
    echo "================================"
    echo ""
    echo "Web URL: http://${LOCAL_IP}:3000"
    echo ""
    echo "Database: Unchanged (see .env)"
    echo ""
    echo "Certificate Passphrase: ${CERT_PASSPHRASE}"
    echo ""
    echo "Backup Location: ${BACKUP_DIR}"
    echo "Configuration: /opt/documenso/.env"
    echo ""
    echo "Migration completed: $(date)"
  } >~/documenso.creds
  msg_ok "Updated credentials file"

  # ============================================
  # STEP 9: Start Documenso
  # ============================================
  msg_info "Starting Documenso"
  $STD docker pull documenso/documenso:latest
  $STD docker run -d \
    --name documenso \
    --restart unless-stopped \
    --network host \
    --log-driver journald \
    --env-file /opt/documenso/.env \
    -v /opt/documenso/certs/cert.p12:/opt/documenso/cert.p12:ro \
    documenso/documenso:latest

  # Wait for container to be ready
  sleep 5

  if docker ps | grep -q documenso; then
    docker inspect documenso --format '{{.Config.Image}}' | cut -d: -f2 >/opt/documenso/.version
    msg_ok "Started Documenso"
  else
    msg_error "Failed to start Documenso container"
    msg_error "Check logs with: docker logs documenso"
    exit 1
  fi

  # ============================================
  # STEP 10: Cleanup old systemd service file
  # ============================================
  rm -f /etc/systemd/system/documenso.service
  systemctl daemon-reload

  echo ""
  msg_ok "Migration completed successfully!"
  echo ""
  echo "Your data has been preserved:"
  echo "  - All users and accounts"
  echo "  - All documents and signatures"
  echo "  - Database untouched"
  echo ""
  echo "What changed:"
  echo "  - Application now runs in Docker container"
  echo "  - Signing certificate has been generated"
  echo "  - Old source code backed up to: ${BACKUP_DIR}"
  echo ""
  echo "You can safely delete the backup after verifying everything works:"
  echo "  rm -rf ${BACKUP_DIR}"
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
