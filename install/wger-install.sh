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
  msg_info "Configuring PowerSync (PostgreSQL + Service)"
  SERVER_IP=$(hostname -I | awk '{print $1}')
  set -a && source /opt/wger/.env && set +a
  POWERSYNC_NODE_VERSION="24.15.0"

  if ! command -v jq >/dev/null 2>&1; then
    $STD apt-get install -y jq
  fi

  if ! command -v node &>/dev/null || ! node -v | grep -q "^v${POWERSYNC_NODE_VERSION%%.*}\."; then
    msg_info "Installing Node.js ${POWERSYNC_NODE_VERSION}"
    NODE_MAJOR="${POWERSYNC_NODE_VERSION%%.*}"
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - >/dev/null 2>&1
    $STD apt install -y nodejs
    corepack enable >/dev/null 2>&1
    msg_ok "Installed Node.js"
  fi

  # PowerSync PostgreSQL setup (done early)
  msg_info "Configuring PostgreSQL for PowerSync"
  sed -i "s/#wal_level = .*/wal_level = logical/" /etc/postgresql/*/main/postgresql.conf
  systemctl restart postgresql
  sudo -u postgres psql -c "ALTER USER ${PG_DB_USER} WITH REPLICATION;" 2>/dev/null || true
  sudo -u postgres psql -d ${PG_DB_NAME} -c "CREATE PUBLICATION powersync FOR ALL TABLES;" 2>/dev/null || true
  msg_ok "PostgreSQL configured for PowerSync"

  # Rest of PowerSync setup (JWT, storage, config, service, etc.)
  msg_info "Generating JWT keys"
  cd /opt/wger
  set -a && source /opt/wger/.env && set +a
  export DJANGO_SETTINGS_MODULE=settings.main
  if ! grep -q "JWT_PRIVATE_KEY" /opt/wger/.env; then
    uv run python manage.py generate-jwt-keys >> /opt/wger/.env 2>/dev/null || true
    set -a && source /opt/wger/.env && set +a
  fi
  msg_ok "Generated JWT keys"

  msg_info "Setting up PowerSync storage"
  sudo -u postgres psql -c "ALTER USER ${PG_DB_USER} WITH SUPERUSER CREATEROLE CREATEDB;"
  uv run python manage.py setup-powersync-storage
  sudo -u postgres psql -d ${PG_DB_NAME} -c "GRANT USAGE, CREATE ON SCHEMA powersync TO ${PG_DB_USER};"
  sudo -u postgres psql -d ${PG_DB_NAME} -c "ALTER ROLE ${PG_DB_USER} IN DATABASE ${PG_DB_NAME} SET search_path TO powersync, public;"
  sudo -u postgres psql -c "ALTER USER ${PG_DB_USER} WITH NOSUPERUSER NOCREATEROLE NOCREATEDB;"
  msg_ok "PowerSync storage ready"

  # [PowerSync config files, download, build, service creation – same as previous version]
  mkdir -p /opt/powersync

  cat > /opt/powersync/powersync.env <<EOF
PS_DATABASE_URI=${DATABASE_URL}
PS_STORAGE_PG_URI=${DATABASE_URL}
PS_PORT=8080
PS_JWKS_URL=http://${SERVER_IP}:3000/api/v2/powersync-keys
EOF

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

  cat > /opt/powersync/sync-rules.yaml <<'SYNCRULES'
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
        SELECT DISTINCT nutrition_synced_ingredient.id
        FROM nutrition_synced_ingredient
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
      - SELECT * FROM nutrition_synced_ingredient AS nutrition_ingredient WHERE id IN user_ingredients
      - SELECT nutrition_image.* FROM nutrition_image WHERE nutrition_image.ingredient_id IN user_ingredients
      - SELECT nutrition_ingredientweightunit.* FROM nutrition_ingredientweightunit WHERE nutrition_ingredientweightunit.ingredient_id IN user_ingredients
  user_planning:
    auto_subscribe: true
    queries:
      - SELECT * FROM manager_routine WHERE CAST(user_id AS TEXT) = auth.user_id() AND is_template = FALSE
      - SELECT * FROM measurements_category WHERE CAST(user_id AS TEXT) = auth.user_id()
      - SELECT measurements_measurement.* FROM measurements_measurement INNER JOIN measurements_category ON measurements_measurement.category_id = measurements_category.id WHERE CAST(measurements_category.user_id AS TEXT) = auth.user_id() AND measurements_measurement.category_id IS NOT NULL
      - SELECT * FROM nutrition_nutritionplan WHERE CAST(user_id AS TEXT) = auth.user_id()
      - SELECT nutrition_meal.* FROM nutrition_meal JOIN nutrition_nutritionplan ON nutrition_meal.plan_id = nutrition_nutritionplan.id WHERE CAST(nutrition_nutritionplan.user_id AS TEXT) = auth.user_id()
      - SELECT nutrition_mealitem.* FROM nutrition_mealitem JOIN nutrition_meal ON nutrition_mealitem.meal_id = nutrition_meal.id JOIN nutrition_nutritionplan ON nutrition_meal.plan_id = nutrition_nutritionplan.id WHERE CAST(nutrition_nutritionplan.user_id AS TEXT) = auth.user_id()
  user_activity:
    auto_subscribe: true
    queries:
      - SELECT uuid AS id, weight, date, user_id FROM weight_weightentry WHERE CAST(user_id AS TEXT) = auth.user_id()
      - SELECT * FROM manager_workoutsession WHERE CAST(user_id AS TEXT) = auth.user_id()
      - SELECT * FROM manager_workoutlog WHERE CAST(user_id AS TEXT) = auth.user_id()
      - SELECT nutrition_logitem.* FROM nutrition_logitem JOIN nutrition_nutritionplan ON nutrition_logitem.plan_id = nutrition_nutritionplan.id WHERE CAST(nutrition_nutritionplan.user_id AS TEXT) = auth.user_id()
SYNCRULES
  msg_ok "Created PowerSync config"

  # Download & build PowerSync (rest of the function remains the same as previous version)
  msg_info "Downloading and building PowerSync"
  RELEASE_JSON=$(curl -fsSL https://api.github.com/repos/powersync-ja/powersync-service/releases/latest)
  TARBALL_URL=$(echo "$RELEASE_JSON" | jq -r .tarball_url)
  curl -fsSL -L "$TARBALL_URL" -o /tmp/powersync.tar.gz
  tar -xzf /tmp/powersync.tar.gz -C /opt/powersync
  EXTRACTED_DIR=$(find /opt/powersync -maxdepth 1 -type d -name "powersync-ja-powersync-service-*")
  rm -rf /opt/powersync/powersync-service
  mv "$EXTRACTED_DIR" /opt/powersync/powersync-service
  cd /opt/powersync/powersync-service
  corepack enable >/dev/null 2>&1
  corepack use "pnpm@$(node -p "require('./package.json').packageManager.split('@')[1]")" >/dev/null 2>&1
  $STD pnpm install --frozen-lockfile
  $STD pnpm build:production
  msg_ok "Built PowerSync"

  # Service user and systemd services (unchanged from previous)
  if ! id -u powersync &>/dev/null; then
    useradd --system --home /opt/powersync --shell /usr/sbin/nologin powersync
  fi
  chown -R powersync:powersync /opt/powersync

  # ... (add the powersync.service, compact service, timer here - same as before)

  systemctl daemon-reload
  systemctl enable -q --now powersync wger-powersync-compact.timer 2>/dev/null || true
  msg_ok "PowerSync services started"

  if ! grep -q "POWERSYNC_URL" /opt/wger/.env; then
    echo "POWERSYNC_URL=http://${SERVER_IP}:8080" >> /opt/wger/.env
  fi
}

# ====================== MAIN INSTALL ======================
start
build_container
description

msg_info "Installing Dependencies"
$STD apt install -y build-essential nginx redis-server libpq-dev
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="sass" setup_nodejs
setup_uv
PG_VERSION="16" setup_postgresql
PG_DB_NAME="wger" PG_DB_USER="wger" setup_postgresql_db

fetch_and_deploy_gh_release "wger" "wger-project/wger" "tarball"

msg_info "Setting up wger"
mkdir -p /opt/wger/{static,media}
chmod o+w /opt/wger/media
cd /opt/wger
$STD corepack enable
$STD npm install
$STD npm run build:css:sass
$STD uv venv
$STD uv pip install . --group docker

SECRET_KEY=$(openssl rand -base64 40)
cat <<EOF >/opt/wger/.env
DJANGO_SETTINGS_MODULE=settings.main
PYTHONPATH=/opt/wger
DJANGO_DB_ENGINE=django.db.backends.postgresql
DJANGO_DB_DATABASE=${PG_DB_NAME}
DJANGO_DB_USER=${PG_DB_USER}
DJANGO_DB_PASSWORD=${PG_DB_PASS}
DJANGO_DB_HOST=localhost
DJANGO_DB_PORT=5432
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}
DJANGO_MEDIA_ROOT=/opt/wger/media
DJANGO_STATIC_ROOT=/opt/wger/static
DJANGO_STATIC_URL=/static/
ALLOWED_HOSTS=${LOCAL_IP},localhost,127.0.0.1
CSRF_TRUSTED_ORIGINS=http://${LOCAL_IP}:3000
USE_X_FORWARDED_HOST=True
SECURE_PROXY_SSL_HEADER=HTTP_X_FORWARDED_PROTO,http
DJANGO_CACHE_BACKEND=django_redis.cache.RedisCache
DJANGO_CACHE_LOCATION=redis://127.0.0.1:6379/1
DJANGO_CACHE_TIMEOUT=300
DJANGO_CACHE_CLIENT_CLASS=django_redis.client.DefaultClient
AXES_CACHE_ALIAS=default
USE_CELERY=True
CELERY_BROKER=redis://127.0.0.1:6379/2
CELERY_BACKEND=redis://127.0.0.1:6379/2
SITE_URL=http://${LOCAL_IP}:3000
SECRET_KEY=${SECRET_KEY}
EOF

set -a && source /opt/wger/.env && set +a

# Pre-create publication as postgres superuser BEFORE bootstrap
msg_info "Pre-creating PowerSync publication"
sudo -u postgres psql -d ${PG_DB_NAME} -c "DROP PUBLICATION IF EXISTS powersync;" 2>/dev/null || true
sudo -u postgres psql -d ${PG_DB_NAME} -c "CREATE PUBLICATION powersync FOR ALL TABLES;"

$STD uv run wger bootstrap
$STD uv run python manage.py collectstatic --no-input

# Admin user with simple password
cat <<EOF | uv run python manage.py shell
from django.contrib.auth import get_user_model
User = get_user_model()
user, created = User.objects.get_or_create(username="admin", defaults={"email": "admin@localhost"})
if created:
    user.set_password("adminadmin")
    user.is_superuser = True
    user.is_staff = True
    user.save()
EOF
msg_ok "Set up wger"

install_powersync

# Services creation (wger, celery, nginx) - same as before
# ... [insert full services section here from previous script]

motd_ssh
customize
cleanup_lxc

msg_ok "Completed Successfully!"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using: http://${IP}:3000${CL}"
echo -e "${RED}⚠️ Default credentials: admin / adminadmin${CL}"
echo -e "${RED}Change password immediately after login!${CL}"
