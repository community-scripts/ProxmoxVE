#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wger-project/wger

APP="wger"
var_tags="${var_tags:-management;fitness}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function install_powersync() {
  msg_info "Checking PowerSync installation"
  SERVER_IP=$(hostname -I | awk '{print $1}')
  set -a && source /opt/wger/.env && set +a

  if docker ps -a --format '{{.Names}}' | grep -q "^powersync$"; then
    msg_info "Updating PowerSync"
    docker pull journeyapps/powersync-service:latest
    docker stop powersync
    docker rm powersync
    docker run -d \
      -p 8080:8080 \
      -v /opt/powersync/powersync.yaml:/app/powersync.yaml \
      -v /opt/powersync/sync-rules.yaml:/app/sync-rules.yaml \
      --network host \
      --restart=always \
      --name powersync \
      journeyapps/powersync-service:latest
    msg_ok "Updated PowerSync"
    return
  fi

  msg_info "Installing Docker"
  apt update
  apt install -y docker.io
  systemctl enable docker
  msg_ok "Installed Docker"

  msg_info "Configuring PostgreSQL for PowerSync"
  sed -i "s/#wal_level = .*/wal_level = logical/" /etc/postgresql/*/main/postgresql.conf
  systemctl restart postgresql
  sudo -u postgres psql -c "ALTER USER wger WITH REPLICATION;"
  msg_ok "Configured PostgreSQL"

  msg_info "Generating JWT keys"
  cd /opt/wger
  export DJANGO_SETTINGS_MODULE=settings.main
  if ! grep -q "JWT_PRIVATE_KEY" /opt/wger/.env; then
    uv run python manage.py generate-jwt-keys >> /opt/wger/.env
  fi
  msg_ok "Generated JWT keys"

  msg_info "Creating PowerSync config"
  mkdir -p /opt/powersync

  cat > /opt/powersync/powersync.yaml <<EOF
replication:
  connections:
    - type: postgresql
      uri: ${DATABASE_URL}
      sslmode: disable

storage:
  type: postgresql
  uri: ${DATABASE_URL}
  sslmode: disable

port: 8080

sync_rules:
  path: /app/sync-rules.yaml

client_auth:
  jwks_uri: http://${SERVER_IP}:3000/api/v2/auth/jwks/

api:
  tokens:
    - $(openssl rand -hex 32)
EOF

  cat > /opt/powersync/sync-rules.yaml <<EOF
bucket_definitions:
  global:
    data:
      - SELECT * FROM core_user
EOF
  msg_ok "Created PowerSync config"

  msg_info "Starting PowerSync container"
  docker run -d \
    -p 8080:8080 \
    -v /opt/powersync/powersync.yaml:/app/powersync.yaml \
    -v /opt/powersync/sync-rules.yaml:/app/sync-rules.yaml \
    --network host \
    --restart=always \
    --name powersync \
    journeyapps/powersync-service:latest
  msg_ok "Started PowerSync"

  msg_info "Updating wger .env with PowerSync URL"
  if ! grep -q "POWERSYNC_URL" /opt/wger/.env; then
    echo "POWERSYNC_URL=http://${SERVER_IP}:8080" >> /opt/wger/.env
  fi
  msg_ok "Updated PowerSync URL in wger .env"
}


function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/wger ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "wger" "wger-project/wger"; then
    msg_info "Stopping Service"
    systemctl stop redis-server nginx celery celery-beat wger
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/wger/media /opt/wger_media_backup
    cp /opt/wger/.env /opt/wger_env_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wger" "wger-project/wger" "tarball"

    msg_info "Restoring Data"
    cp -r /opt/wger_media_backup/. /opt/wger/media
    cp /opt/wger_env_backup /opt/wger/.env
    rm -rf /opt/wger_media_backup /opt/wger_env_backup

    msg_ok "Restored Data"

    msg_info "Updating wger"
    cd /opt/wger
    set -a && source /opt/wger/.env && set +a
    export DJANGO_SETTINGS_MODULE=settings.main
    
    sudo -u postgres psql -c "ALTER USER wger WITH SUPERUSER;"
    sudo -u postgres psql -c "ALTER USER wger WITH REPLICATION;"
    
    $STD uv pip install .
    $STD npm install
    $STD npm run build:css:sass
    $STD uv run python manage.py migrate
    $STD uv run python manage.py collectstatic --no-input

    sudo -u postgres psql -c "ALTER USER wger WITH NOSUPERUSER;"
    
    msg_ok "Updated wger"

    msg_info "Starting Services"
    systemctl start redis-server nginx celery celery-beat wger
    msg_ok "Started Services"
    msg_ok "Updated Successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
