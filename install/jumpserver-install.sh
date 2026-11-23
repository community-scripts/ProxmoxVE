#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Nícolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.jumpserver.org/ | Github: https://github.com/jumpserver/jumpserver

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  autoconf \
  automake \
  libtool \
  pkg-config \
  xz-utils \
  default-libmysqlclient-dev \
  freetds-dev \
  gettext \
  locales \
  libkrb5-dev \
  libldap2-dev \
  libsasl2-dev \
  libx11-dev \
  openssh-client \
  sshpass \
  bubblewrap \
  libcairo2-dev \
  libjpeg62-turbo-dev \
  libpng-dev \
  uuid-dev \
  libavcodec-dev \
  libavformat-dev \
  libavutil-dev \
  libswscale-dev \
  freerdp3-dev \
  libwinpr3-dev \
  libpango1.0-dev \
  libssh2-1-dev \
  libtelnet-dev \
  libvncserver-dev \
  libwebsockets-dev \
  libpulse-dev \
  libssl-dev \
  libvorbis-dev \
  libwebp-dev \
  redis-server \
  nginx
msg_ok "Installed Dependencies"

PG_VERSION="16" setup_postgresql
PG_DB_NAME="jumpserver" PG_DB_USER="jumpserver" setup_postgresql_db

msg_info "Starting Redis"
systemctl enable -q --now redis-server
msg_ok "Started Redis"

PYTHON_VERSION="3.14" setup_uv
NODE_VERSION="24" NODE_MODULE="corepack" setup_nodejs

fetch_and_deploy_gh_tag "guacd" "apache/guacamole-server"

msg_info "Building guacd"
cd /opt/guacd
$STD autoreconf -fi
# FreeRDP 3.6+ deprecates APIs guacd still calls, which -Werror turns into build failures
$STD ./configure --with-systemd-dir=/etc/systemd/system --disable-guacenc CFLAGS="-O2 -Wno-error=deprecated-declarations"
$STD make -j"$(nproc)"
$STD make install
$STD ldconfig
# guacd binds "localhost" (::1 here) by default, but KoKo dials 127.0.0.1
mkdir -p /etc/guacamole
cat <<EOF >/etc/guacamole/guacd.conf
[server]
bind_host = 127.0.0.1
bind_port = 4822
EOF
systemctl enable -q --now guacd
msg_ok "Built guacd"

fetch_and_deploy_gh_release "jumpserver" "jumpserver/jumpserver" "tarball" "latest" "" "" "v5."
# KoKo, Lina and Luna must match the core release exactly
JMS_TAG="v$(<~/.jumpserver)"
# The PAM clients are a git submodule, which the release tarball leaves empty
github_api_call "https://api.github.com/repos/jumpserver/jumpserver/contents/apps/accounts/clients?ref=${JMS_TAG}" /tmp/jms-clients.json
fetch_and_deploy_from_url "https://github.com/jumpserver/pam-clients/archive/$(jq -r .sha /tmp/jms-clients.json).tar.gz" /opt/jumpserver/apps/accounts/clients
rm -f /tmp/jms-clients.json

msg_info "Configuring JumpServer Core"
JMS_BOOTSTRAP_TOKEN=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-32)
cat <<EOF >/opt/jumpserver/config.yml
SECRET_KEY: $(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9' | cut -c1-49)
BOOTSTRAP_TOKEN: ${JMS_BOOTSTRAP_TOKEN}
DB_ENGINE: postgresql
DB_HOST: 127.0.0.1
DB_PORT: 5432
DB_USER: jumpserver
DB_PASSWORD: ${PG_DB_PASS}
DB_NAME: jumpserver
REDIS_HOST: 127.0.0.1
REDIS_PORT: 6379
HTTP_BIND_HOST: 0.0.0.0
HTTP_LISTEN_PORT: 8080
WS_LISTEN_PORT: 8070
LOG_LEVEL: ERROR
EOF
cd /opt/jumpserver
$STD bash requirements/static_files.sh
$STD uv venv --python 3.14
$STD uv pip install -r pyproject.toml
JMS_GALAXY_RETRIES=3
until ANSIBLE_COLLECTIONS_PATHS="/opt/jumpserver/.venv/lib/python3.14/site-packages/ansible_collections" $STD .venv/bin/ansible-galaxy collection install -r requirements/collections.yml --force --ignore-certs; do
  JMS_GALAXY_RETRIES=$((JMS_GALAXY_RETRIES - 1))
  if ((JMS_GALAXY_RETRIES <= 0)); then
    msg_error "ansible-galaxy collection install failed after 3 attempts (Ansible Galaxy may be unreachable)"
    exit 1
  fi
  sleep 15
done
cd /opt/jumpserver/apps
$STD ../.venv/bin/python3 manage.py compilemessages
msg_ok "Configured JumpServer Core"

msg_info "Creating Core Service"
cat <<EOF >/etc/systemd/system/jumpserver.service
[Unit]
Description=JumpServer Core Service
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/jumpserver
Environment=ANSIBLE_COLLECTIONS_PATHS=/opt/jumpserver/.venv/lib/python3.14/site-packages/ansible_collections
Environment=PATH=/opt/jumpserver/.venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/opt/jumpserver/.venv/bin/python3 /opt/jumpserver/jms start all
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q jumpserver
msg_ok "Created Core Service"

fetch_and_deploy_gh_tag "koko" "jumpserver/koko" "$JMS_TAG"

# Toolchain pins come from KoKo's own build files so they follow each release
GHOSTTY_COMMIT=$(grep -oP 'libghostty-vt:ghostty-\K[0-9a-f]+' /opt/koko/Dockerfile-base)
ZIG_VERSION=$(grep -oP 'libghostty-vt:ghostty-[0-9a-f]+-zig-\K[0-9.]+' /opt/koko/Dockerfile-base)
USQL_VERSION=$(grep -oP 'ARG USQL_VERSION=\K\S+' /opt/koko/Dockerfile-base)
K8S_BUNDLE_VERSION=$(grep -oP 'ARG K8S_BUNDLE_VERSION=\K\S+' /opt/koko/Dockerfile-base)
GO_VERSION=$(grep -oP '^go \K\S+' /opt/koko/go.mod) setup_go

fetch_and_deploy_from_url "https://ziglang.org/download/${ZIG_VERSION}/zig-$(arch_resolve x86_64 aarch64)-linux-${ZIG_VERSION}.tar.xz" "/opt/zig"
fetch_and_deploy_from_url "https://github.com/ghostty-org/ghostty/archive/${GHOSTTY_COMMIT}.tar.gz" "/opt/ghostty"

msg_info "Building libghostty-vt"
cd /opt/ghostty
$STD /opt/zig/zig build -Demit-lib-vt -Doptimize=ReleaseFast -Dcpu=baseline --prefix /opt/libghostty-vt
rm -rf /opt/ghostty /opt/zig ~/.cache/zig
echo "$GHOSTTY_COMMIT" >~/.libghostty-vt
msg_ok "Built libghostty-vt"

msg_info "Building KoKo"
cd /opt/koko
export PKG_CONFIG_PATH=/opt/libghostty-vt/share/pkgconfig
$STD make build VERSION="$JMS_TAG"
mv build/koko koko
rm -rf build
msg_ok "Built KoKo"

fetch_and_deploy_gh_release "usql" "jumpserver-dev/usql" "prebuild" "$USQL_VERSION" "/opt/usql" "usql-*-linux-$(arch_resolve amd64 arm64).tar.gz"
ln -sf /opt/usql/usql /usr/local/bin/usql
fetch_and_deploy_gh_release "k8s-bundle" "jumpserver-dev/k8s-bundle" "binary" "$K8S_BUNDLE_VERSION" "" "k8s-bundle_$(arch_resolve amd64 arm64).deb"

msg_info "Configuring KoKo"
cat <<EOF >/opt/koko/config.yml
CORE_HOST: http://127.0.0.1:8080
BOOTSTRAP_TOKEN: ${JMS_BOOTSTRAP_TOKEN}
REDIS_HOST: 127.0.0.1
REDIS_PORT: 6379
GUA_HOST: 127.0.0.1
GUA_PORT: 4822
WEB_PROXY_RECORDING_ENABLED: false
EOF
cat <<EOF >/etc/systemd/system/koko.service
[Unit]
Description=JumpServer KoKo Service
After=network.target guacd.service jumpserver.service

[Service]
Type=simple
WorkingDirectory=/opt/koko
ExecStart=/opt/koko/koko
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q koko
msg_ok "Configured KoKo"

fetch_and_deploy_gh_tag "lina" "jumpserver/lina" "$JMS_TAG" "/opt/lina-src"

msg_info "Building Lina"
cd /opt/lina-src
$STD yarn install --immutable
$STD yarn build:prod
rm -rf /opt/lina
mv lina /opt/lina
rm -rf /opt/lina-src
msg_ok "Built Lina"

fetch_and_deploy_gh_tag "luna" "jumpserver/luna" "$JMS_TAG" "/opt/luna-src"

msg_info "Building Luna"
cd /opt/luna-src
# NUXT_TELEMETRY_DISABLED stops nuxt generate from waiting on a consent prompt
export ELECTRON_SKIP_BINARY_DOWNLOAD=1 PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 HUSKY=0 NUXT_TELEMETRY_DISABLED=1
$STD pnpm --filter jumpserver-web... install --frozen-lockfile --config.node-linker=isolated
$STD pnpm --config.node-linker=isolated --filter jumpserver-web web:generate
rm -rf /opt/luna
mv .output/public /opt/luna
rm -rf /opt/luna-src
msg_ok "Built Luna"

msg_info "Initializing Database"
cd /opt/jumpserver
$STD .venv/bin/python3 jms upgrade_db
msg_ok "Initialized Database"

msg_info "Securing Admin Account"
# Booting Django here (outside upgrade_db) also generates TERMINAL_HOST_KEY,
# so the core service loads it on start instead of caching an empty one
JMS_ADMIN_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-16)
cd /opt/jumpserver
PYTHONPATH=/opt/jumpserver/apps DJANGO_SETTINGS_MODULE=jumpserver.settings $STD .venv/bin/python3 -c "
import django
django.setup()
from users.models import User
u = User.objects.get(username='admin')
u.set_password('${JMS_ADMIN_PASS}')
u.need_update_password = False
u.save()
"
cat <<EOF >>~/jumpserver.creds
JumpServer Admin Credentials
Username: admin
Password: ${JMS_ADMIN_PASS}
EOF
msg_ok "Secured Admin Account"

msg_info "Starting Services"
# The core only accepts terminal registration for 5 minutes after it starts,
# so KoKo has to come up right behind it instead of after the long builds
systemctl start jumpserver
for _ in $(seq 1 90); do
  curl -fsS -o /dev/null http://127.0.0.1:8080/api/health/ 2>/dev/null && break
  sleep 5
done
systemctl start koko
msg_ok "Started Services"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/jumpserver
server {
    listen 80 default_server;
    client_max_body_size 4096m;

    location / {
        rewrite ^/(.*)\$ /ui/\$1 last;
    }

    location /ui/ {
        try_files \$uri / /index.html;
        alias /opt/lina/;
    }

    location /luna/ {
        try_files \$uri / /index.html;
        alias /opt/luna/;
    }

    location /static/ {
        root /opt/jumpserver/data/;
    }

    location /private-media/ {
        internal;
        alias /opt/jumpserver/data/media/;
    }

    location /ws/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$remote_addr;
    }

    location ~ ^/(core|api|media)/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_ignore_client_abort on;
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 6000;
    }

    location /koko/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_request_buffering off;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_ignore_client_abort on;
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 6000;
    }
}
EOF
nginx_enable_site "jumpserver"
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
