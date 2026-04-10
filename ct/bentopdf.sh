#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/alam00000/bentopdf

APP="BentoPDF"
var_tags="${var_tags:-pdf-editor}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/bentopdf ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" setup_nodejs

  if check_for_gh_release "bentopdf" "alam00000/bentopdf"; then
    msg_info "Stopping Service"
    systemctl stop bentopdf
    msg_ok "Stopped Service"

    [[ -f /opt/bentopdf/.env.production ]] && cp /opt/bentopdf/.env.production /opt/production.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "bentopdf" "alam00000/bentopdf" "tarball" "latest" "/opt/bentopdf"

    msg_info "Updating BentoPDF"
    cd /opt/bentopdf
    $STD npm ci --no-audit --no-fund
    if [[ -f /opt/production.env ]]; then
      mv /opt/production.env ./.env.production
    else
      cp ./.env.example ./.env.production
    fi
    export NODE_OPTIONS="--max-old-space-size=3072"
    export SIMPLE_MODE=true
    export VITE_USE_CDN=true
    $STD npm run build:all
    if [[ ! -f /opt/bentopdf/dist/config.json ]]; then
      cat <<'EOF' >/opt/bentopdf/dist/config.json
{}
EOF
    fi
    msg_ok "Updated BentoPDF"

    msg_info "Starting Service"
    ensure_dependencies nginx openssl
    if [[ ! -f /etc/ssl/private/bentopdf-selfsigned.key || ! -f /etc/ssl/certs/bentopdf-selfsigned.crt ]]; then
      CERT_CN="$(hostname -I | awk '{print $1}')"
      $STD openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
      -keyout /etc/ssl/private/bentopdf-selfsigned.key \
      -out /etc/ssl/certs/bentopdf-selfsigned.crt \
      -subj "/CN=${CERT_CN}"
    fi
    cat <<'EOF' >/etc/nginx/sites-available/bentopdf
server {
    listen 8080;
    server_name _;
    return 301 https://$host:8443$request_uri;
  }

  server {
    listen 8443 ssl;
    server_name _;
    ssl_certificate /etc/ssl/certs/bentopdf-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/bentopdf-selfsigned.key;
    root /opt/bentopdf/dist;
    index index.html;

    # Required for LibreOffice WASM (Word/Excel/PowerPoint to PDF via SharedArrayBuffer)
    add_header Cross-Origin-Opener-Policy "same-origin" always;
    add_header Cross-Origin-Embedder-Policy "require-corp" always;
    add_header Cross-Origin-Resource-Policy "cross-origin" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;

    gzip_static on;

    location ~* /libreoffice-wasm/soffice\.wasm\.gz$ {
      gzip off;
      types {} default_type application/wasm;
      add_header Content-Encoding gzip;
      add_header Vary "Accept-Encoding";
      add_header Cache-Control "public, immutable";
    }

    location ~* /libreoffice-wasm/soffice\.data\.gz$ {
      gzip off;
      types {} default_type application/octet-stream;
      add_header Content-Encoding gzip;
      add_header Vary "Accept-Encoding";
      add_header Cache-Control "public, immutable";
    }

    location ~* \.wasm$ {
      types {} default_type application/wasm;
      expires 1y;
      add_header Cache-Control "public, immutable";
    }

    location ~* \.(wasm\.gz|data\.gz|data)$ {
      expires 1y;
      add_header Cache-Control "public, immutable";
    }

    location / {
        try_files $uri $uri/ $uri.html =404;
    }

    error_page 404 /404.html;
}
EOF
    rm -f /etc/nginx/sites-enabled/default
    ln -sf /etc/nginx/sites-available/bentopdf /etc/nginx/sites-enabled/bentopdf
    cat <<'EOF' >/etc/systemd/system/bentopdf.service
[Unit]
Description=BentoPDF Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/nginx -g "daemon off;"
ExecReload=/bin/kill -HUP $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl start bentopdf
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:8443${CL}"
