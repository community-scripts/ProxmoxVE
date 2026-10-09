#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docspell.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  ocrmypdf \
  tesseract-ocr \
  tesseract-ocr-deu \
  tesseract-ocr-eng \
  unpaper \
  weasyprint \
  libreoffice-core \
  ghostscript \
  libreoffice-writer \
  libreoffice-calc \
  python3-pip \
  python3-uno \
  python3-venv

python3 -m venv \
  --system-site-packages \
  /opt/unoserver

$STD /opt/unoserver/bin/pip install --upgrade pip
$STD /opt/unoserver/bin/pip install unoserver
msg_ok "Installed Dependencies"

JAVA_VERSION="21" setup_java
PG_VERSION="17" setup_postgresql
PG_DB_NAME="docspell" PG_DB_USER="docspell" setup_postgresql_db

fetch_and_deploy_gh_release "docspell-joex" "eikek/docspell" "binary" "latest" "/opt/docspell" "docspell-joex_*_all.deb"
fetch_and_deploy_gh_release "docspell-restserver" "eikek/docspell" "binary" "latest" "/opt/docspell" "docspell-restserver_*_all.deb"

msg_info "Configuring Docspell"
DOCSPELL_SECRET=$(openssl rand -hex 32)
DOCSPELL_ADMIN_SECRET=$(openssl rand -hex 32)
cat <<EOF >/etc/docspell-restserver/docspell-server.conf
docspell.server {
  app-id = "rest1"
  base-url = "http://${LOCAL_IP}:7880"
  internal-url = "http://127.0.0.1:7880"
  bind {
    address = "0.0.0.0"
    port = 7880
  }
  auth.server-secret = "hex:${DOCSPELL_SECRET}"
  admin-endpoint.secret = "${DOCSPELL_ADMIN_SECRET}"
  full-text-search {
    enabled = true
    backend = "postgresql"
    postgresql.use-default-connection = true
  }
  backend {
    jdbc {
      url = "jdbc:postgresql://127.0.0.1:5432/${PG_DB_NAME}"
      user = "${PG_DB_USER}"
      password = "${PG_DB_PASS}"
    }
    signup.mode = "open"
  }
}
EOF
cat <<EOF >/etc/docspell-joex/docspell-joex.conf
docspell.joex {
  app-id = "joex1"
  base-url = "http://127.0.0.1:7878"
  bind {
    address = "127.0.0.1"
    port = 7878
  }
  jdbc {
    url = "jdbc:postgresql://127.0.0.1:5432/${PG_DB_NAME}"
    user = "${PG_DB_USER}"
    password = "${PG_DB_PASS}"
  }
  full-text-search {
    enabled = true
    backend = "postgresql"
    postgresql.use-default-connection = true
  }
  scheduler.pool-size = 1
  text-analysis.nlp.mode = "basic"
}
EOF
chown root:docspell /etc/docspell-joex/docspell-joex.conf /etc/docspell-restserver/docspell-server.conf
chmod 640 /etc/docspell-joex/docspell-joex.conf /etc/docspell-restserver/docspell-server.conf
msg_ok "Configured Docspell"

msg_info "Creating Services"
systemctl enable -q --now docspell-restserver docspell-joex
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
