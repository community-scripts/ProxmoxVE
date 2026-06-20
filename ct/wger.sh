#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/Soppster1029/ProxmoxVE/main/misc/build.func)
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

function install_powersync_if_missing() {
  if [[ -f /etc/systemd/system/powersync.service ]]; then
    msg_info "PowerSync already provisioned, skipping first-time setup"
    return
  fi

  msg_info "First-time PowerSync provisioning"
  SERVER_IP=$(hostname -I | awk '{print $1}')
  set -a && source /opt/wger/.env && set +a

  msg_info "Configuring PostgreSQL for PowerSync"
  sed -i "s/^#*wal_level = .*/wal_level = logical/" /etc/postgresql/*/main/postgresql.conf
  systemctl restart postgresql
  $STD sudo -u postgres psql -c "ALTER USER wger WITH SUPERUSER CREATEROLE CREATEDB REPLICATION;"
  $STD sudo -u postgres psql -d wger -c "DROP PUBLICATION IF EXISTS powersync;" 2>/dev/null || true
  $STD sudo -u postgres psql -d wger -c "CREATE PUBLICATION powersync FOR ALL TABLES;" 2>/dev/null || true
  msg_ok "Configured PostgreSQL"

  msg_info "Generating JWT keys"
  cd /opt/wger
  set -a && source /opt/wger/.env && set +a
  export DJANGO_SETTINGS_MODULE=settings.main
  if ! grep -q "JWT_PRIVATE_KEY" /opt/wger/.env; then
    uv run python manage.py generate-jwt-keys >> /opt/wger/.env
    set -a && source /opt/wger/.env && set +a
  fi
  msg_ok "Generated JWT keys"

  msg_info "Setting up PowerSync storage"
  $STD uv run python manage.py setup-powersync-storage
  $STD sudo -u postgres psql -d wger -c "GRANT USAGE, CREATE ON SCHEMA powersync TO wger;"
  $STD sudo -u postgres psql -d wger -c "ALTER ROLE wger IN DATABASE wger SET search_path TO powersync, public;"
  $STD sudo -u postgres psql -c "ALTER USER wger WITH NOSUPERUSER NOCREATEROLE NOCREATEDB;"
  msg_ok "Set up PowerSync storage"

  msg_info "Creating PowerSync config"
  mkdir -p /opt/powersync

  # Only create config files if they don't exist (preserve user changes)
  if [[ ! -f /opt/powersync/powersync.env ]]; then
    cat > /opt/powersync/powersync.env <<EOF
PS_DATABASE_URI=${DATABASE_URL}
PS_STORAGE_PG_URI=${DATABASE_URL}
PS_PORT=8080
PS_JWKS_URL=http://${SERVER_IP}:3000/api/v2/powersync-keys
EOF
  fi

  if [[ ! -f /opt/powersync/powersync.yaml ]]; then
    cat > /opt/powersync/powersync.yaml <<'EOF'
telemetry:
  disable_telemetry_sharing: true
  prometheus_port: 9090
replication:
  connections:
    - type: postgresql
      uri: !env PS_DATABASE_URI
      sslmode: disable
storage:
  type: postgresql
  uri: !env PS_STORAGE_PG_URI
  sslmode: disable
port: !env PS_PORT
sync_rules:
  path: sync-rules.yaml
client_auth:
  allow_local_jwks: true
  jwks_uri: !env PS_JWKS_URL
  audience:
    - "powersync"
EOF
  fi

  if [[ ! -f /opt/powersync/sync-rules.yaml ]]; then
    cat > /opt/powersync/sync-rules.yaml <<'SYNCRULES'
# Note that changes to this file are not watched.
# The service needs to be restarted for changes to take effect.
config:
  edition: 3

streams:
  core:
    auto_subscribe: true
    queries:
      - SELECT * FROM core_language
      - SELECT * FROM core_license
      - SELECT * FROM core_repetitionunit
      - SELECT * FROM core_weightunit
      - SELECT * FROM exercises_exercise
      - SELECT * FROM exercises_translation
      - SELECT * FROM exercises_alias
      - SELECT * FROM exercises_exercisecomment
      - SELECT * FROM exercises_muscle
      - SELECT * FROM exercises_exercise_muscles
      - SELECT * FROM exercises_exercise_muscles_secondary
      - SELECT * FROM exercises_equipment
      - SELECT * FROM exercises_exercise_equipment
      - SELECT * FROM exercises_exercisecategory
      - SELECT * FROM exercises_exerciseimage
      - SELECT * FROM exercises_exercisevideo

  user_profile:
    auto_subscribe: true
    queries:
      - SELECT * FROM core_userprofile WHERE CAST(user_id AS TEXT) = auth.user_id()
      - SELECT * FROM gallery_image WHERE CAST(user_id AS TEXT) = auth.user_id()

  user_ingredients:
    auto_subscribe: true
    with:
      user_ingredients: |
        SELECT DISTINCT nutrition_synced_ingredient.id FROM nutrition_synced_ingredient
        WHERE nutrition_synced_ingredient.id IN (
          SELECT nutrition_logitem.ingredient_id FROM nutrition_logitem
          JOIN nutrition_nutritionplan ON nutrition_logitem.plan_id = nutrition_nutritionplan.id
          WHERE CAST(nutrition_nutritionplan.user_id AS TEXT) = auth.user_id())
        OR nutrition_synced_ingredient.id IN (
          SELECT nutrition_mealitem.ingredient_id FROM nutrition_mealitem
          JOIN nutrition_meal ON nutrition_mealitem.meal_id = nutrition_meal.id
          JOIN nutrition_nutritionplan ON nutrition_meal.plan_id = nutrition_nutritionplan.id
          WHERE CAST(nutrition_nutritionplan.user_id AS TEXT) = auth.user_id())
    queries:
      - SELECT * FROM nutrition_synced_ingredient WHERE id IN user_ingredients
      - SELECT * FROM nutrition_image WHERE ingredient_id IN user_ingredients
      - SELECT * FROM nutrition_ingredientweightunit WHERE ingredient_id IN user_ingredients

  user_planning:
    auto_subscribe: true
    queries:
      - SELECT * FROM manager_routine WHERE CAST(user_id AS TEXT) = auth.user_id() AND is_template = FALSE
      - SELECT * FROM measurements_category WHERE CAST(user_id AS TEXT) = auth.user_id()
      - |
        SELECT measurements_measurement.*
        FROM measurements_measurement
        INNER JOIN measurements_category
          ON measurements_measurement.category_id = measurements_category.id
        WHERE CAST(measurements_category.user_id AS TEXT) = auth.user_id()
          AND measurements_measurement.category_id IS NOT NULL
      - SELECT * FROM nutrition_nutritionplan WHERE CAST(user_id AS TEXT) = auth.user_id()
      - |
        SELECT nutrition_meal.*
        FROM nutrition_meal
        JOIN nutrition_nutritionplan
          ON nutrition_meal.plan_id = nutrition_nutritionplan.id
        WHERE CAST(nutrition_nutritionplan.user_id AS TEXT) = auth.user_id()
      - |
        SELECT nutrition_mealitem.*
        FROM nutrition_mealitem
        JOIN nutrition_meal
          ON nutrition_mealitem.meal_id = nutrition_meal.id
        JOIN nutrition_nutritionplan
          ON nutrition_meal.plan_id = nutrition_nutritionplan.id
        WHERE CAST(nutrition_nutritionplan.user_id AS TEXT) = auth.user_id()

  user_activity:
    auto_subscribe: true
    queries:
      - SELECT uuid AS id, weight, date, user_id FROM weight_weightentry WHERE CAST(user_id AS TEXT) = auth.user_id()
      - SELECT * FROM manager_workoutsession WHERE CAST(user_id AS TEXT) = auth.user_id()
      - SELECT * FROM manager_workoutlog WHERE CAST(user_id AS TEXT) = auth.user_id()
      - |
        SELECT nutrition_logitem.*
        FROM nutrition_logitem
        JOIN nutrition_nutritionplan
          ON nutrition_logitem.plan_id = nutrition_nutritionplan.id
        WHERE CAST(nutrition_nutritionplan.user_id AS TEXT) = auth.user_id()
SYNCRULES
  fi
  msg_ok "Created PowerSync config"

  msg_info "Creating PowerSync service user"
  if ! id -u powersync &>/dev/null; then
    useradd --system --home /opt/powersync --shell /usr/sbin/nologin powersync
  fi
  chown -R powersync:powersync /opt/powersync
  msg_ok "Created PowerSync service user"

  msg_info "Creating PowerSync systemd service"
 
  if [[ ! -f /etc/systemd/system/powersync.service ]]; then
    cat > /etc/systemd/system/powersync.service <<EOF
[Unit]
Description=PowerSync Service
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=powersync
Group=powersync
WorkingDirectory=/opt/powersync/powersync-service
EnvironmentFile=/opt/powersync/powersync.env
Environment=NODE_ENV=production
Environment=POWERSYNC_CONFIG_PATH=/opt/powersync/powersync.yaml
Environment=NODE_OPTIONS=--max-old-space-size=1024
ExecStart=/usr/bin/node service/lib/entry.js start
Restart=always
RestartSec=5
TimeoutStartSec=120
LimitNOFILE=65535
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
  fi
  msg_ok "Created PowerSync systemd service"

  msg_info "Creating PowerSync compaction timer"
  if [[ ! -f /opt/powersync/powersync-compact.yaml ]]; then
    cat > /opt/powersync/powersync-compact.yaml <<'EOF'
telemetry:
  disable_telemetry_sharing: true

replication:
  connections:
    - type: postgresql
      uri: !env PS_DATABASE_URI
      sslmode: disable

storage:
  type: postgresql
  uri: !env PS_STORAGE_PG_URI
  sslmode: disable

port: !env PS_PORT

sync_rules:
  path: sync-rules.yaml

client_auth:
  allow_local_jwks: true
  jwks_uri: !env PS_JWKS_URL
  audience:
    - "powersync"
EOF
  fi

  if [[ ! -f /etc/systemd/system/wger-powersync-compact.service ]]; then
    cat > /etc/systemd/system/wger-powersync-compact.service <<'EOF'
[Unit]
Description=wger PowerSync Bucket Compaction
After=powersync.service
Requires=powersync.service

[Service]
Type=oneshot
User=powersync
Group=powersync
WorkingDirectory=/opt/powersync/powersync-service
EnvironmentFile=/opt/powersync/powersync.env
Environment=NODE_ENV=production
Environment=POWERSYNC_CONFIG_PATH=/opt/powersync/powersync-compact.yaml
Environment=PS_PORT=8081
Environment=NODE_OPTIONS=--max-old-space-size=1024
ExecStart=/usr/bin/node service/lib/entry.js compact
TimeoutStartSec=1800
Restart=on-failure
RestartSec=60
StandardOutput=journal
StandardError=journal
EOF
  fi

  if [[ ! -f /etc/systemd/system/wger-powersync-compact.timer ]]; then
    cat > /etc/systemd/system/wger-powersync-compact.timer <<EOF
[Unit]
Description=Run wger PowerSync Compaction Daily

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true
RandomizedDelaySec=15min

[Install]
WantedBy=timers.target
EOF
  fi

  systemctl daemon-reload || msg_warn "systemctl daemon-reload failed for PowerSync units"
  systemctl enable -q powersync wger-powersync-compact.timer 2>/dev/null || msg_warn "Failed to enable PowerSync units"
  msg_ok "Created PowerSync compaction timer"

  msg_info "Updating wger .env with PowerSync URL"
  if ! grep -q "POWERSYNC_URL" /opt/wger/.env; then
    echo "POWERSYNC_URL=http://${SERVER_IP}:8080" >> /opt/wger/.env
  fi
  msg_ok "Updated PowerSync URL in wger .env"
}

function update_powersync() {
  msg_info "Updating PowerSync"
  systemctl stop powersync 2>/dev/null || true

  if ! command -v jq >/dev/null 2>&1; then
    $STD apt-get install -y jq >/dev/null 2>&1
  fi

  CLEAN_INSTALL=1 fetch_and_deploy_gh_release "powersync" "powersync-ja/powersync-service" "tarball" "latest" "/opt/powersync/powersync-service"
  cd /opt/powersync/powersync-service
  corepack use "pnpm@$(node -p "require('./package.json').packageManager.split('@')[1]")" >/dev/null 2>&1
  $STD pnpm install --frozen-lockfile
  $STD pnpm build:production
  msg_ok "Updated PowerSync"
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
    systemctl stop powersync 2>/dev/null || true
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/wger/media /opt/wger_media_backup
    cp /opt/wger/.env /opt/wger_env_backup
    mkdir -p /opt/wger_powersync_backup
    cp -r /opt/powersync/*.env /opt/powersync/*.yaml /opt/wger_powersync_backup/ 2>/dev/null || true
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wger" "wger-project/wger" "tarball"

    msg_info "Restoring Data"
    cp -r /opt/wger_media_backup/. /opt/wger/media
    cp /opt/wger_env_backup /opt/wger/.env
    mkdir -p /opt/powersync
    cp -r /opt/wger_powersync_backup/. /opt/powersync/ 2>/dev/null || true
    rm -rf /opt/wger_media_backup /opt/wger_env_backup /opt/wger_powersync_backup
    msg_ok "Restored Data"

    msg_info "Updating wger"
    cd /opt/wger
    set -a && source /opt/wger/.env && set +a
    export DJANGO_SETTINGS_MODULE=settings.main
    $STD sudo -u postgres psql -c "ALTER USER wger WITH SUPERUSER;"
    $STD sudo -u postgres psql -c "ALTER USER wger WITH REPLICATION;"
    $STD uv pip install .
    $STD npm install
    $STD npm run build:css:sass
    $STD uv run python manage.py migrate
    $STD uv run python manage.py collectstatic --no-input
    $STD sudo -u postgres psql -c "ALTER USER wger WITH NOSUPERUSER;"
    msg_ok "Updated wger"

    msg_info "Fixing nginx proxy header"
    sed -i 's/proxy_set_header Host \$host;/proxy_set_header Host \$http_host;/' /etc/nginx/sites-enabled/wger
    msg_ok "Fixed nginx proxy header"

    msg_info "Ensuring Node.js 24 for PowerSync"
    CURRENT_NODE_MAJOR=$(node -v | sed 's/^v//' | cut -d. -f1)
    if [[ "$CURRENT_NODE_MAJOR" -lt 24 ]]; then
      curl -fsSL https://deb.nodesource.com/setup_24.x | bash - >/dev/null 2>&1
      $STD apt-get install -y nodejs
    fi
    msg_ok "Node.js $(node -v) ready"

    install_powersync_if_missing
    update_powersync

    msg_info "Starting Services"
    systemctl start redis-server nginx celery celery-beat wger
    systemctl start powersync wger-powersync-compact.timer
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
msg_warn "Initial credentials:"
echo "Username: admin"
echo "Password: adminadmin"
msg_warn "Change the password immediately after first login!"
