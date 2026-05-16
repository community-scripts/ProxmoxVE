#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Thieneret
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/goauthentik/authentik

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
  pkg-config \
  libffi-dev \
  libxslt-dev \
  zlib1g-dev \
  libpq-dev \
  krb5-multidev \
  libkrb5-dev \
  heimdal-multidev \
  libclang-dev \
  libltdl-dev \
  libpq5 \
  libmaxminddb0 \
  libkrb5-3 \
  libkdb5-10 \
  libkadm5clnt-mit12 \
  libkadm5clnt7t64-heimdal \
  libltdl7 \
  libxslt1.1 \
  python3-dev \
  libxml2-dev \
  libxml2 \
  libxslt1-dev \
  automake \
  autoconf \
  libtool \
  libtool-bin \
  gcc \
  git
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs
setup_yq
setup_go
UV_PYTHON_INSTALL_DIR="/usr/local/bin" PYTHON_VERSION="3.14.3" setup_uv
setup_rust
PG_VERSION="17" setup_postgresql
PG_DB_NAME="authentik" PG_DB_USER="authentik" PG_DB_GRANT_SUPERUSER="true" setup_postgresql_db

XMLSEC_VERSION="1.3.11"
AUTHENTIK_VERSION="version/2026.2.3"
fetch_and_deploy_gh_release "xmlsec" "lsh123/xmlsec" "tarball" "${XMLSEC_VERSION}" "/opt/xmlsec"
fetch_and_deploy_gh_release "authentik" "goauthentik/authentik" "tarball" "${AUTHENTIK_VERSION}" "/opt/authentik"
fetch_and_deploy_gh_release "geoipupdate" "maxmind/geoipupdate" "binary"

msg_info "Setup xmlsec"
cd /opt/xmlsec
$STD ./autogen.sh
$STD make -j $(nproc)
$STD make check
$STD make install
$STD ldconfig
msg_ok "xmlsec installed"

msg_info "Setup web"
cd /opt/authentik/web
export NODE_ENV="production"
$STD npm install
$STD npm run build
$STD npm run build:sfe
msg_ok "Web installed"

msg_info "Setup go proxy"
cd /opt/authentik
export CGO_ENABLED="1"
$STD go mod download
$STD go build -o /opt/authentik/authentik-server ./cmd/server
$STD go build -o /opt/authentik/ldap ./cmd/ldap
$STD go build -o /opt/authentik/rac ./cmd/rac
$STD go build -o /opt/authentik/radius ./cmd/radius
msg_ok "Go proxy installed"

cat <<EOF >/usr/local/etc/GeoIP.conf
AccountID ChangeME
LicenseKey ChangeME
EditionIDs GeoLite2-ASN GeoLite2-City GeoLite2-Country
DatabaseDirectory /opt/authentik-data/geoip
RetryFor 5m
Parallelism 1
EOF

echo "#39 19 * * 6,4 /usr/bin/geoipupdate -f /usr/local/etc/GeoIP.conf" | crontab -

msg_info "Setup python server"
export UV_NO_BINARY_PACKAGE="cryptography lxml python-kadmin-rs xmlsec"
export UV_COMPILE_BYTECODE="1"
export UV_LINK_MODE="copy"
export UV_NATIVE_TLS="1"
export RUSTUP_PERMIT_COPY_RENAME="true"
export UV_PYTHON_INSTALL_DIR="/usr/local/bin"
cd /opt/authentik
$STD uv sync --frozen --no-install-project --no-dev
cp /opt/authentik/authentik/sources/kerberos/krb5.conf /etc/krb5.conf
msg_ok "Installed python server"

msg_info "Creating authentik config"
mkdir -p /etc/authentik
mv /opt/authentik/authentik/lib/default.yml /etc/authentik/config.yml
yq -i ".secret_key = \"$(openssl rand -base64 128 | tr -dc 'a-zA-Z0-9' | head -c64)\"" /etc/authentik/config.yml
yq -i ".postgresql.password = \"${PG_DB_PASS}\"" /etc/authentik/config.yml
yq -i ".events.context_processors.geoip = \"/opt/authentik-data/geoip/GeoLite2-City.mmdb\"" /etc/authentik/config.yml
yq -i ".events.context_processors.asn = \"/opt/authentik-data/geoip/GeoLite2-ASN.mmdb\"" /etc/authentik/config.yml
yq -i ".blueprints_dir = \"/opt/authentik/blueprints\"" /etc/authentik/config.yml
yq -i ".cert_discovery_dir = \"/opt/authentik-data/certs\"" /etc/authentik/config.yml
yq -i ".email.template_dir = \"/opt/authentik-data/templates\"" /etc/authentik/config.yml
yq -i ".storage.file.path = \"/opt/authentik-data\"" /etc/authentik/config.yml
yq -i ".disable_startup_analytics = \"true\"" /etc/authentik/config.yml
$STD useradd -U -s /usr/sbin/nologin -r -M -d /opt/authentik authentik
chown -R authentik:authentik /opt/authentik
cat <<EOF >/etc/default/authentik
TMPDIR=/dev/shm/
UV_LINK_MODE=copy
UV_PYTHON_DOWNLOADS=0
UV_NATIVE_TLS=1
VENV_PATH=/opt/authentik/.venv
PYTHONDONTWRITEBYTECODE=1
PYTHONUNBUFFERED=1
PATH=/opt/authentik/lifecycle:/opt/authentik/.venv/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin
DJANGO_SETTINGS_MODULE=authentik.root.settings
PROMETHEUS_MULTIPROC_DIR="/tmp/authentik_prometheus_tmp"
EOF
cat <<EOF >/etc/default/authentik_ldap
AUTHENTIK_HOST="https://127.0.0.1:9443"
AUTHENTIK_INSECURE="true"
AUTHENTIK_TOKEN="token-generated-by-authentik"
EOF
cat <<EOF >/etc/default/authentik_rac
AUTHENTIK_HOST="https://127.0.0.1:9443"
AUTHENTIK_INSECURE="true"
AUTHENTIK_TOKEN="token-generated-by-authentik"
EOF
cat <<EOF >/etc/default/authentik_radius
AUTHENTIK_HOST="https://127.0.0.1:9443"
AUTHENTIK_INSECURE="true"
AUTHENTIK_TOKEN="token-generated-by-authentik"
EOF
msg_ok "authentik config created"

msg_info "Creating services"
cat <<EOF >/etc/systemd/system/authentik-server.service
[Unit]
Description=authentik Go Server (API Gateway)
After=network.target
Wants=postgresql.service

[Service]
User=authentik
Group=authentik
ExecStartPre=/usr/bin/mkdir -p "\${PROMETHEUS_MULTIPROC_DIR}"
ExecStart=/opt/authentik/authentik-server
WorkingDirectory=/opt/authentik/
Restart=always
RestartSec=5
EnvironmentFile=/etc/default/authentik

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/authentik-worker.service
[Unit]
Description=authentik Worker
After=network.target postgresql.service

[Service]
User=authentik
Group=authentik
Type=simple
EnvironmentFile=/etc/default/authentik
ExecStart=/usr/local/bin/uv run python -m manage worker --pid-file /dev/shm/authentik-worker.pid
WorkingDirectory=/opt/authentik
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/authentik-ldap.service
[Unit]
Description=authentik LDAP Outpost
After=network.target
Wants=postgresql.service

[Service]
User=authentik
Group=authentik
ExecStart=/opt/authentik/ldap
WorkingDirectory=/opt/authentik/
Restart=always
RestartSec=5
EnvironmentFile=/etc/default/authentik_ldap

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/authentik-rac.service
[Unit]
Description=authentik RAC Outpost
After=network.target
Wants=postgresql.service

[Service]
User=authentik
Group=authentik
ExecStart=/opt/authentik/rac
WorkingDirectory=/opt/authentik/
Restart=always
RestartSec=5
EnvironmentFile=/etc/default/authentik_rac

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/authentik-radius.service
[Unit]
Description=authentik Radius Outpost
After=network.target
Wants=postgresql.service

[Service]
User=authentik
Group=authentik
ExecStart=/opt/authentik/radius
WorkingDirectory=/opt/authentik/
Restart=always
RestartSec=5
EnvironmentFile=/etc/default/authentik_radius

[Install]
WantedBy=multi-user.target
EOF
msg_ok "Services created"

motd_ssh
customize
cleanup_lxc
