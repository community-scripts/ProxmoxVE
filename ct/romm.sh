#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ) | DevelopmentCats | AlphaLawless
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://romm.app | Github: https://github.com/rommapp/romm

APP="RomM"
var_tags="${var_tags:-emulation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/romm ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [[ ! -x /usr/bin/7zz || ! -x /usr/bin/bsdtar ]]; then
    msg_info "Installing Archive Tools"
    $STD apt install -y 7zip-standalone libarchive-tools
    msg_ok "Installed Archive Tools"
  fi

  NODE_VERSION="24" setup_nodejs

  if check_for_gh_release "romm" "rommapp/romm"; then
    msg_info "Stopping Services"
    systemctl stop romm-backend romm-worker romm-scheduler romm-watcher
    msg_ok "Stopped Services"

    create_backup /opt/romm/.env
    BACKUP_DIR=/opt/romm-players.backup create_backup \
      /opt/romm/frontend/dist/assets/emulatorjs \
      /opt/romm/frontend/dist/assets/ruffle

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "romm" "rommapp/romm" "tarball" "latest" "/opt/romm"
    echo "__version__ = \"$(cat ~/.romm)\"" >/opt/romm/backend/__version__.py

    find /opt/romm/backend/alembic/versions -maxdepth 1 -type f -name '1.*.py' -delete 2>/dev/null || true
    find /opt/romm/backend/alembic/versions -maxdepth 1 -type f -name '2.0.0_.py' -delete 2>/dev/null || true
    find /opt/romm/backend -name '__pycache__' -type d -prune -exec rm -rf {} + 2>/dev/null || true

    restore_backup

    msg_info "Updating ROMM"
    cd /opt/romm
    $STD uv sync --all-extras
    cd /opt/romm/backend
    $STD uv run alembic upgrade head
    if [[ -f /opt/romm/backend/utils/rom_patcher/package.json ]]; then
      cd /opt/romm/backend/utils/rom_patcher
      $STD npm install --ignore-scripts --no-audit --no-fund --allow-git=all
      if [[ -d node_modules/rom-patcher/rom-patcher-js ]]; then
        rm -rf rom-patcher-js
        cp -r node_modules/rom-patcher/rom-patcher-js ./rom-patcher-js
      fi
      rm -rf node_modules
    fi
    cd /opt/romm/frontend
    $STD npm install
    $STD npm run build
    # Merge static assets into dist folder
    cp -rf /opt/romm/frontend/assets/* /opt/romm/frontend/dist/assets/
    mkdir -p /opt/romm/frontend/dist/assets/romm
    ROMM_BASE=$(grep '^ROMM_BASE_PATH=' /opt/romm/.env | cut -d'=' -f2)
    ROMM_BASE=${ROMM_BASE:-/var/lib/romm}
    ln -sfn "$ROMM_BASE"/resources /opt/romm/frontend/dist/assets/romm/resources
    ln -sfn "$ROMM_BASE"/assets /opt/romm/frontend/dist/assets/romm/assets
    if [[ -f /etc/angie/http.d/romm.conf ]]; then
      if ! grep -q "js_content decode.decodeBase64" /etc/angie/http.d/romm.conf; then
        msg_info "Adding missing /decode and /cache locations to Angie config"
        dpkg -l angie-module-njs &>/dev/null || $STD apt-get install -y angie-module-njs
        grep -q "ngx_http_js_module.so" /etc/angie/angie.conf || sed -i '1i load_module modules/ngx_http_js_module.so;' /etc/angie/angie.conf
        mkdir -p /etc/angie/js "${ROMM_BASE}/cache"
        cat <<'JSEOF' >/etc/angie/js/decode.js
// Decode a Base64 encoded string received as a query parameter named 'value',
// and return the decoded value in the response body.
function decodeBase64(r) {
  var encodedValue = r.args.value;

  if (!encodedValue) {
    r.return(400, "Missing 'value' query parameter");
    return;
  }

  try {
    // Use Buffer to return raw bytes — atob() returns a JS string which r.return()
    // would re-encode as UTF-8, corrupting any non-ASCII bytes (e.g. in filenames
    // like "Pokémon") and causing CRC mismatches in the mod_zip manifest.
    r.return(200, Buffer.from(encodedValue, 'base64'));
  } catch (e) {
    r.return(400, "Invalid Base64 encoding");
  }
}

export default { decodeBase64 };
JSEOF
        cat <<EOF >/etc/angie/http.d/romm.conf
js_import /etc/angie/js/decode.js;

upstream romm_backend {
    server 127.0.0.1:5000;
}

map \$http_upgrade \$connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen 80;
    server_name _;
    root /opt/romm/frontend/dist;
    client_max_body_size 0;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /assets {
        alias /opt/romm/frontend/dist/assets;
        try_files \$uri \$uri/ =404;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location ~ ^/rom/.*/ejs\$ {
        add_header Cross-Origin-Embedder-Policy "require-corp";
        add_header Cross-Origin-Opener-Policy "same-origin";
        try_files \$uri /index.html;
    }

    location /api {
        proxy_pass http://romm_backend;
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location ~ ^/(ws|netplay) {
        proxy_pass http://romm_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header Host \$host;
        proxy_read_timeout 86400;
    }

    location = /openapi.json {
        proxy_pass http://romm_backend;
    }

    location /library/ {
        internal;
        alias ${ROMM_BASE}/library/;
    }

    location /cache/ {
        internal;
        alias ${ROMM_BASE}/cache/;
    }

    location /decode {
        internal;
        js_content decode.decodeBase64;
    }
}
EOF
        msg_ok "Added /decode and /cache locations"
      else
        sed -i -e "s|alias .*/library/;|alias ${ROMM_BASE}/library/;|" \
          -e "s|alias .*/cache/;|alias ${ROMM_BASE}/cache/;|" /etc/angie/http.d/romm.conf
      fi
      systemctl reload angie
    elif [[ -f /etc/nginx/sites-available/romm ]]; then
      sed -i "s|alias .*/library/;|alias ${ROMM_BASE}/library/;|" /etc/nginx/sites-available/romm
      nginx_enable_site romm
    fi
    msg_ok "Updated ROMM"

    msg_info "Starting Services"
    systemctl start romm-backend romm-worker romm-scheduler romm-watcher
    msg_ok "Started Services"
    msg_ok "Updated successfully"
  fi

  if check_for_gh_release "EmulatorJS" "EmulatorJS/EmulatorJS" "v4.2.3"; then
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "EmulatorJS" "EmulatorJS/EmulatorJS" "prebuild" "v4.2.3" "/opt/romm/frontend/dist/assets/emulatorjs" "4.2.3.7z"
    systemctl restart romm-backend romm-worker romm-scheduler romm-watcher
    msg_ok "Updated EmulatorJS successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
