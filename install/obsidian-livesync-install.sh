#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/vrtmrz/obsidian-livesync | https://couchdb.apache.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb822_repo \
  "couchdb" \
  "https://couchdb.apache.org/repo/keys.asc" \
  "https://apache.jfrog.io/artifactory/couchdb-deb/" \
  "$(get_os_info codename)" \
  "main"

msg_info "Installing CouchDB"
COUCHDB_ADMIN_USER="admin"
COUCHDB_PASSWORD="$(openssl rand -hex 24)"
COUCHDB_COOKIE="$(openssl rand -hex 16)"

cat <<EOF | debconf-set-selections
couchdb couchdb/mode select standalone
couchdb couchdb/mode seen true
couchdb couchdb/bindaddress string 0.0.0.0
couchdb couchdb/bindaddress seen true
couchdb couchdb/cookie string ${COUCHDB_COOKIE}
couchdb couchdb/cookie seen true
couchdb couchdb/adminpass password ${COUCHDB_PASSWORD}
couchdb couchdb/adminpass seen true
couchdb couchdb/adminpass_again password ${COUCHDB_PASSWORD}
couchdb couchdb/adminpass_again seen true
EOF
DEBIAN_FRONTEND=noninteractive $STD apt-get install -y couchdb

cat <<EOF >/root/.couchdb.credentials
COUCHDB_ADMIN_USER="${COUCHDB_ADMIN_USER}"
COUCHDB_ADMIN_PASSWORD="${COUCHDB_PASSWORD}"
COUCHDB_COOKIE="${COUCHDB_COOKIE}"
EOF
msg_ok "Installed CouchDB"

msg_info "Configuring CouchDB"
mkdir -p /opt/couchdb/etc/local.d /opt/obsidian-livesync
cat <<EOF >/opt/couchdb/etc/local.d/obsidian-livesync.ini
[couchdb]
single_node = true
max_document_size = 50000000

[admins]
admin = ${COUCHDB_PASSWORD}

[chttpd]
bind_address = 0.0.0.0
port = 5984
max_http_request_size = 4294967296

[chttpd_auth]
require_valid_user = true

[httpd]
enable_cors = true
WWW-Authenticate = Basic realm="couchdb"

[cors]
credentials = true
origins = app://obsidian.md,capacitor://localhost,http://localhost
headers = accept, authorization, content-type, origin, referer
methods = GET, PUT, POST, HEAD, DELETE
max_age = 3600
EOF
cat <<EOF >/opt/obsidian-livesync/.env
COUCHDB_URL=http://${LOCAL_IP}:5984
COUCHDB_USER=admin
COUCHDB_PASSWORD=${COUCHDB_PASSWORD}
COUCHDB_DATABASE=obsidiannotes
EOF
chmod 600 /opt/obsidian-livesync/.env
msg_ok "Configured CouchDB"

msg_info "Creating LiveSync Database"
systemctl enable -q couchdb
systemctl restart couchdb
for _ in {1..30}; do
  curl -fsS -u "admin:${COUCHDB_PASSWORD}" -X PUT http://127.0.0.1:5984/obsidiannotes >/dev/null 2>&1 && break
  sleep 1
done
msg_ok "Created LiveSync Database"

motd_ssh
customize
cleanup_lxc
