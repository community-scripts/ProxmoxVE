#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: ekke85 | MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Dispatcharr/Dispatcharr

APP="Dispatcharr"
var_tags="${var_tags:-media;arr}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
var_gpu="${var_gpu:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d "/opt/dispatcharr" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  setup_uv
  NODE_VERSION="24" setup_nodejs
  if [[ -f "/etc/nginx/sites-available/dispatcharr.conf" ]] && ! grep -q "real_forwarded_proto" "/etc/nginx/sites-available/dispatcharr.conf"; then
    msg_info "Migrating Nginx Configuration"
    cat <<EOF >"/etc/nginx/sites-available/dispatcharr.conf"
map \$http_x_forwarded_proto \$real_forwarded_proto {
    ""      \$scheme;
    default \$http_x_forwarded_proto;
}

map \$http_x_forwarded_port \$real_forwarded_port {
    ""      \$server_port;
    default \$http_x_forwarded_port;
}

server {
    listen 9191;
    server_name _;
    client_max_body_size 100M;

    # Serve static assets with correct MIME types
    location /assets/ {
        alias /opt/dispatcharr/frontend/dist/assets/;
        expires 30d;
        add_header Cache-Control "public, immutable";

        # Explicitly set MIME types for webpack-built assets
        types {
            text/javascript js;
            text/css css;
            image/png png;
            image/svg+xml svg svgz;
            font/woff2 woff2;
            font/woff woff;
            font/ttf ttf;
        }
    }

    location /static/ {
        alias /opt/dispatcharr/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias /opt/dispatcharr/media/;
    }

    location /ws/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$real_forwarded_proto;
    }

    # All other requests proxy to uWSGI
    location / {
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$real_forwarded_proto;
        proxy_set_header X-Forwarded-Port \$real_forwarded_port;
        proxy_pass http://127.0.0.1:5656;
    }
}
EOF
    systemctl reload nginx
    msg_ok "Migrated Nginx Configuration"
  fi

  ensure_dependencies vlc-bin vlc-plugin-base

  if check_for_gh_release "Dispatcharr" "Dispatcharr/Dispatcharr"; then
    msg_info "Stopping Services"
    systemctl stop dispatcharr-celery
    systemctl stop dispatcharr-celerybeat
    systemctl stop dispatcharr-daphne
    systemctl stop dispatcharr
    msg_ok "Stopped Services"

    msg_info "Creating Backup"
    BACKUP_FILE="/opt/dispatcharr_backup_$(date +%F_%H-%M-%S).tar.gz"
    if [[ -f /opt/dispatcharr/start-gunicorn.sh ]]; then
      rm -f /opt/dispatcharr/start-gunicorn.sh
    fi
    create_backup /opt/dispatcharr/.env /opt/dispatcharr/start-celery.sh /opt/dispatcharr/start-celerybeat.sh /opt/dispatcharr/start-daphne.sh
    if [[ -f /opt/dispatcharr/.env ]]; then
      set -o allexport
      source /opt/dispatcharr/.env
      set +o allexport
      if [[ -n "$POSTGRES_DB" ]] && [[ -n "$POSTGRES_USER" ]] && [[ -n "$POSTGRES_PASSWORD" ]]; then
        PGPASSWORD=$POSTGRES_PASSWORD pg_dump -U "$POSTGRES_USER" -h "${POSTGRES_HOST:-localhost}" -p "${POSTGRES_PORT:-5432}" "$POSTGRES_DB" >/tmp/dispatcharr_db_$(date +%F).sql
        msg_info "Database backup created"
      fi
    fi
    $STD tar -czf "$BACKUP_FILE" -C /opt dispatcharr /tmp/dispatcharr_db_*.sql
    msg_ok "Backup created: $BACKUP_FILE"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "dispatcharr" "Dispatcharr/Dispatcharr" "tarball"

    restore_backup

    msg_info "Updating Dispatcharr Backend"
    if ! grep -q "DJANGO_SECRET_KEY" /opt/dispatcharr/.env; then
      DJANGO_SECRET=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | cut -c1-50)
      echo "DJANGO_SECRET_KEY=$DJANGO_SECRET" >>/opt/dispatcharr/.env
    fi

    cd /opt/dispatcharr
    rm -rf .venv
    $STD uv venv --clear
    $STD uv sync
    $STD uv pip install uwsgi gevent celery redis daphne
    cat <<'EOF' >/opt/dispatcharr/start-uwsgi.sh
#!/usr/bin/env bash
cd /opt/dispatcharr
set -a
source .env
set +a
exec .venv/bin/uwsgi \
    --chdir=/opt/dispatcharr \
    --module=dispatcharr.wsgi:application \
    --master \
    --workers=4 \
    --gevent=400 \
    --http=0.0.0.0:5656 \
    --http-keepalive=1 \
    --http-timeout=600 \
    --socket-timeout=600 \
    --buffer-size=65536 \
    --post-buffering=4096 \
    --lazy-apps \
    --thunder-lock \
    --die-on-term \
    --vacuum
EOF
    chmod +x /opt/dispatcharr/start-uwsgi.sh
    if grep -q 'start-gunicorn.sh' /etc/systemd/system/dispatcharr.service; then
      sed -i 's|start-gunicorn.sh|start-uwsgi.sh|g' /etc/systemd/system/dispatcharr.service
      systemctl daemon-reload
    fi
    msg_ok "Updated Dispatcharr Backend"

    msg_info "Building Frontend"
    cd /opt/dispatcharr/frontend
    node -e "const p=require('./package.json');p.overrides=p.overrides||{};p.overrides['webworkify-webpack']='2.1.3';require('fs').writeFileSync('package.json',JSON.stringify(p,null,2));"
    rm -f package-lock.json
    $STD npm install --no-audit --progress=false
    $STD npm run build
    msg_ok "Built Frontend"

    msg_info "Running Django Migrations"
    cd /opt/dispatcharr
    if [[ -f .env ]]; then
      set -o allexport
      source .env
      set +o allexport
    fi
    $STD uv run python manage.py migrate --noinput
    $STD uv run python manage.py collectstatic --noinput
    rm -f /tmp/dispatcharr_db_*.sql
    msg_ok "Migrations Complete"

    msg_info "Starting Services"
    systemctl start dispatcharr
    systemctl start dispatcharr-celery
    systemctl start dispatcharr-celerybeat
    systemctl start dispatcharr-daphne
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:9191${CL}"
