#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/tess1o/geopulse

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  openssl \
  nginx
msg_ok "Installed Dependencies"

PG_VERSION="17" PG_MODULES="postgis" setup_postgresql
PG_DB_NAME="geopulse" PG_DB_USER="geopulse" PG_DB_EXTENSIONS="postgis,postgis_topology" setup_postgresql_db

msg_info "Generating Security Keys"
mkdir -p /opt/geopulse/{backend,keys}
mkdir -p /etc/geopulse /var/www/geopulse /var/lib/geopulse/dumps
mkdir -p /var/log/geopulse/{backend,nginx}
openssl genpkey -algorithm RSA -out /opt/geopulse/keys/jwt-private-key.pem 2>/dev/null
openssl rsa -pubout -in /opt/geopulse/keys/jwt-private-key.pem -out /opt/geopulse/keys/jwt-public-key.pem 2>/dev/null
openssl rand -base64 32 >/opt/geopulse/keys/ai-encryption-key.txt
chmod 640 /opt/geopulse/keys/jwt-private-key.pem /opt/geopulse/keys/jwt-public-key.pem /opt/geopulse/keys/ai-encryption-key.txt
msg_ok "Generated Security Keys"

if [[ "$(uname -m)" == "aarch64" ]]; then
  if grep -qi "raspberry\|bcm" /proc/cpuinfo 2>/dev/null; then
    BINARY_PATTERN="geopulse-backend-native-arm64-compat-*"
  else
    BINARY_PATTERN="geopulse-backend-native-arm64-[!c]*"
  fi
else
  if grep -q avx2 /proc/cpuinfo && grep -q bmi2 /proc/cpuinfo && grep -q fma /proc/cpuinfo; then
    BINARY_PATTERN="geopulse-backend-native-amd64-[!c]*"
  else
    BINARY_PATTERN="geopulse-backend-native-amd64-compat-*"
  fi
fi

fetch_and_deploy_gh_release "geopulse-backend" "tess1o/geopulse" "singlefile" "latest" "/opt/geopulse/backend" "${BINARY_PATTERN}"
fetch_and_deploy_gh_release "geopulse-frontend" "tess1o/geopulse" "prebuild" "latest" "/var/www/geopulse" "geopulse-frontend-*.tar.gz"

msg_info "Configuring GeoPulse"
cat <<EOF >/etc/geopulse/geopulse.env
GEOPULSE_PUBLIC_BASE_URL=http://${LOCAL_IP}
GEOPULSE_UI_URL=http://${LOCAL_IP}
GEOPULSE_CORS_ENABLED=false
GEOPULSE_CORS_ORIGINS=
QUARKUS_HTTP_PORT=8080
GEOPULSE_POSTGRES_URL=jdbc:postgresql://localhost:5432/${PG_DB_NAME}
GEOPULSE_POSTGRES_HOST=localhost
GEOPULSE_POSTGRES_PORT=5432
GEOPULSE_POSTGRES_DB=${PG_DB_NAME}
GEOPULSE_POSTGRES_USERNAME=${PG_DB_USER}
GEOPULSE_POSTGRES_PASSWORD=${PG_DB_PASS}
GEOPULSE_JWT_PRIVATE_KEY_LOCATION=file:/opt/geopulse/keys/jwt-private-key.pem
GEOPULSE_JWT_PUBLIC_KEY_LOCATION=file:/opt/geopulse/keys/jwt-public-key.pem
GEOPULSE_AI_ENCRYPTION_KEY_LOCATION=file:/opt/geopulse/keys/ai-encryption-key.txt
QUARKUS_LOG_FILE_ENABLE=true
QUARKUS_LOG_FILE_PATH=/var/log/geopulse/backend/geopulse.log
QUARKUS_LOG_FILE_ROTATION_MAX_FILE_SIZE=10M
QUARKUS_LOG_FILE_ROTATION_MAX_BACKUP_INDEX=5
EOF
chmod 640 /etc/geopulse/geopulse.env
msg_ok "Configured GeoPulse"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/geopulse-backend.service
[Unit]
Description=GeoPulse Backend
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/geopulse/backend
EnvironmentFile=/etc/geopulse/geopulse.env
ExecStart=/opt/geopulse/backend/geopulse-backend -Dquarkus.http.host=0.0.0.0 -XX:MaximumHeapSizePercent=70 -XX:MaximumYoungGenerationSizePercent=15
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/geopulse/backend/geopulse-stdout.log
StandardError=append:/var/log/geopulse/backend/geopulse-stderr.log

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now geopulse-backend
msg_ok "Created Service"

msg_info "Configuring Nginx"
mkdir -p /var/cache/nginx/osm_tiles
cat <<'EOF' >/etc/nginx/sites-available/geopulse.conf
proxy_cache_path /var/cache/nginx/osm_tiles levels=1:2 keys_zone=osm_cache:100m max_size=10g inactive=30d use_temp_path=off;

map $uri $osm_subdomain {
    ~^/osm/tiles/a/ "a";
    ~^/osm/tiles/b/ "b";
    ~^/osm/tiles/c/ "c";
    default "a";
}

server {
    listen 80;
    server_name _;

    root /var/www/geopulse;
    index index.html;

    client_max_body_size 100M;

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_comp_level 6;
    gzip_min_length 1000;

    location ~* ^/(?!osm/).*\.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, max-age=31536000";
    }

    location ^~ /osm/tiles/ {
        resolver 8.8.8.8 valid=300s;
        resolver_timeout 10s;
        rewrite ^/osm/tiles/[abc]/(.*)$ /$1 break;
        proxy_pass https://$osm_subdomain.tile.openstreetmap.org;
        proxy_cache osm_cache;
        proxy_cache_key "$scheme$proxy_host$uri";
        proxy_cache_valid 200 30d;
        proxy_cache_valid 404 1m;
        proxy_cache_valid 502 503 504 1m;
        proxy_ignore_headers Cache-Control Expires Set-Cookie;
        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
        proxy_cache_background_update on;
        proxy_cache_lock on;
        proxy_set_header Cookie "";
        proxy_set_header Authorization "";
        proxy_set_header User-Agent "GeoPulse/1.0";
        proxy_set_header Host $osm_subdomain.tile.openstreetmap.org;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_connect_timeout 10s;
        proxy_read_timeout 10s;
        expires 30d;
        add_header Cache-Control "public, immutable";
        add_header X-Cache-Status $upstream_cache_status always;
    }

    location /api/ {
        proxy_pass http://localhost:8080/api/;
        proxy_connect_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_read_timeout 3600s;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    access_log /var/log/geopulse/nginx/access.log;
    error_log /var/log/geopulse/nginx/error.log;
}
EOF
ln -sf /etc/nginx/sites-available/geopulse.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl enable -q --now nginx
systemctl reload nginx
msg_ok "Configured Nginx"

msg_info "Creating Admin Helper"
cat <<'EOF' >/usr/local/bin/create-geopulse-admin
#!/usr/bin/env bash
read -rp "Enter admin email address: " ADMIN_EMAIL
if [[ -z "$ADMIN_EMAIL" ]]; then
  echo "No email provided. Aborting."
  exit 1
fi
sed -i '/^GEOPULSE_ADMIN_EMAIL=/d' /etc/geopulse/geopulse.env
echo "GEOPULSE_ADMIN_EMAIL=${ADMIN_EMAIL}" >>/etc/geopulse/geopulse.env
systemctl restart geopulse-backend
echo "Admin email set to '${ADMIN_EMAIL}'. Register with this email in the GeoPulse UI to receive admin privileges."
EOF
chmod +x /usr/local/bin/create-geopulse-admin
msg_ok "Created Admin Helper"

motd_ssh
customize
cleanup_lxc
