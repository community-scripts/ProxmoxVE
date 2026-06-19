#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wger-project/wger

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# ====================== 2. Base Dependencies ======================
msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  nginx \
  redis-server \
  libpq-dev \
  jq
msg_ok "Installed Dependencies"

# ====================== 3. Tool Setup ======================
NODE_VERSION="22" NODE_MODULE="sass" setup_nodejs
setup_uv
PG_VERSION="16" setup_postgresql
PG_DB_NAME="wger" PG_DB_USER="wger" setup_postgresql_db

# ====================== 4. Application Download ======================
fetch_and_deploy_gh_release "wger" "wger-project/wger" "tarball"

# ====================== 5. Configuration ======================
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

# ====================== Critical Bootstrap Fix ======================
msg_info "Preparing PowerSync publication"
sudo -u postgres psql -d ${PG_DB_NAME} -c "DROP PUBLICATION IF EXISTS powersync;" 2>/dev/null || true
sudo -u postgres psql -d ${PG_DB_NAME} -c "CREATE PUBLICATION powersync FOR ALL TABLES;" 2>/dev/null || true
sudo -u postgres psql -c "ALTER USER ${PG_DB_USER} WITH SUPERUSER;" 2>/dev/null || true

$STD uv run wger bootstrap
$STD uv run python manage.py collectstatic --no-input

# Create admin user with default password
cat <<EOF | uv run python manage.py shell
from django.contrib.auth import get_user_model
User = get_user_model()
user, created = User.objects.get_or_create(
    username="admin",
    defaults={"email": "admin@localhost"},
)
if created:
    user.set_password("adminadmin")
    user.is_superuser = True
    user.is_staff = True
    user.save()
EOF

sudo -u postgres psql -c "ALTER USER ${PG_DB_USER} WITH NOSUPERUSER NOCREATEROLE NOCREATEDB;" 2>/dev/null || true
msg_ok "wger core setup completed"

# ====================== PowerSync Setup ======================
msg_info "Setting up PowerSync"
SERVER_IP=$(hostname -I | awk '{print $1}')

if ! command -v node &>/dev/null || ! node -v | grep -q "^v24"; then
  msg_info "Installing Node.js 24"
  curl -fsSL https://deb.nodesource.com/setup_24.x | bash - >/dev/null 2>&1
  $STD apt install -y nodejs
  corepack enable
  msg_ok "Node.js 24 installed"
fi

cd /opt/wger
export DJANGO_SETTINGS_MODULE=settings.main

if ! grep -q "JWT_PRIVATE_KEY" /opt/wger/.env; then
  uv run python manage.py generate-jwt-keys >> /opt/wger/.env
  set -a && source /opt/wger/.env && set +a
fi

sudo -u postgres psql -c "ALTER USER ${PG_DB_USER} WITH SUPERUSER CREATEROLE CREATEDB;"
$STD uv run python manage.py setup-powersync-storage
sudo -u postgres psql -d ${PG_DB_NAME} -c "GRANT USAGE, CREATE ON SCHEMA powersync TO ${PG_DB_USER};"
sudo -u postgres psql -d ${PG_DB_NAME} -c "ALTER ROLE ${PG_DB_USER} IN DATABASE ${PG_DB_NAME} SET search_path TO powersync, public;"
sudo -u postgres psql -c "ALTER USER ${PG_DB_USER} WITH NOSUPERUSER NOCREATEROLE NOCREATEDB;"

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
      - SELECT * FROM nutrition_nutritionplan WHERE CAST(user_id AS TEXT) = auth.user_id()

  user_activity:
    auto_subscribe: true
    queries:
      - SELECT uuid AS id, weight, date, user_id FROM weight_weightentry WHERE CAST(user_id AS TEXT) = auth.user_id()
      - SELECT * FROM manager_workoutsession WHERE CAST(user_id AS TEXT) = auth.user_id()
      - SELECT * FROM manager_workoutlog WHERE CAST(user_id AS TEXT) = auth.user_id()
      - SELECT * FROM nutrition_logitem WHERE plan_id IN (SELECT id FROM nutrition_nutritionplan WHERE CAST(user_id AS TEXT) = auth.user_id())
SYNCRULES
msg_ok "PowerSync config created"

msg_info "Downloading and Building PowerSync"
RELEASE_JSON=$(curl -fsSL https://api.github.com/repos/powersync-ja/powersync-service/releases/latest)
TARBALL_URL=$(echo "$RELEASE_JSON" | jq -r .tarball_url)
curl -fsSL -L "$TARBALL_URL" -o /tmp/powersync.tar.gz
tar -xzf /tmp/powersync.tar.gz -C /opt/powersync
EXTRACTED_DIR=$(find /opt/powersync -maxdepth 1 -type d -name "powersync-ja-powersync-service-*" | head -1)
rm -rf /opt/powersync/powersync-service
mv "$EXTRACTED_DIR" /opt/powersync/powersync-service
cd /opt/powersync/powersync-service
corepack use "pnpm@$(node -p "require('./package.json').packageManager.split('@')[1]")" >/dev/null 2>&1
$STD pnpm install --frozen-lockfile
$STD pnpm build:production
msg_ok "Built PowerSync"

msg_info "Creating PowerSync service user"
if ! id -u powersync &>/dev/null; then
  useradd --system --home /opt/powersync --shell /usr/sbin/nologin powersync
fi
chown -R powersync:powersync /opt/powersync
msg_ok "Created PowerSync service user"

if ! grep -q "POWERSYNC_URL" /opt/wger/.env; then
  echo "POWERSYNC_URL=http://${SERVER_IP}:8080" >> /opt/wger/.env
fi
msg_ok "PowerSync setup completed"

# ====================== 8. Services ======================
msg_info "Creating Config and Services"
cat <<EOF >/etc/systemd/system/wger.service
[Unit]
Description=wger Web Application
After=network.target postgresql.service redis-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/wger
EnvironmentFile=/opt/wger/.env
ExecStart=/opt/wger/.venv/bin/gunicorn --bind 127.0.0.1:8000 --workers 3 --threads 2 --timeout 120 wger.wsgi:application
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/celery.service
[Unit]
Description=wger Celery Worker
After=network.target postgresql.service redis-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/wger
EnvironmentFile=/opt/wger/.env
ExecStart=/opt/wger/.venv/bin/celery -A wger worker -l info
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /var/lib/wger/celery
chmod 700 /var/lib/wger/celery
cat <<EOF >/etc/systemd/system/celery-beat.service
[Unit]
Description=wger Celery Beat Scheduler
After=network.target postgresql.service redis-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/wger
EnvironmentFile=/opt/wger/.env
ExecStart=/opt/wger/.venv/bin/celery -A wger beat -l info --schedule /var/lib/wger/celery/celerybeat-schedule
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/powersync.service
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

cat <<EOF >/etc/systemd/system/wger-powersync-compact.service
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

cat <<EOF >/etc/systemd/system/wger-powersync-compact.timer
[Unit]
Description=Run wger PowerSync Compaction Daily

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true
RandomizedDelaySec=15min

[Install]
WantedBy=timers.target
EOF

cat <<EOF >/etc/nginx/sites-available/wger
server {
    listen 3000;
    server_name _;
    client_max_body_size 100M;

    location /static/ {
        alias /opt/wger/static/;
    }

    location /media/ {
        alias /opt/wger/media/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
    }
}
EOF

ln -sf /etc/nginx/sites-available/wger /etc/nginx/sites-enabled/wger
rm -f /etc/nginx/sites-enabled/default

systemctl daemon-reload
systemctl enable -q --now redis-server nginx wger celery celery-beat powersync wger-powersync-compact.timer
systemctl restart nginx
msg_ok "Services created"

# ====================== Final ======================
motd_ssh
customize
cleanup_lxc

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
echo ""
echo -e "${RED}⚠️  Default credentials: admin / adminadmin${CL}"
echo -e "${RED}   Change the password immediately after first login!${CL}"
