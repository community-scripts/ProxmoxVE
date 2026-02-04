#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://couchdb.apache.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Apache CouchDB"
ERLANG_COOKIE=$(openssl rand -base64 32)
ADMIN_PASS="$(openssl rand -base64 18 | cut -c1-13)"
debconf-set-selections <<<"couchdb couchdb/cookie string $ERLANG_COOKIE"
debconf-set-selections <<<"couchdb couchdb/mode select standalone"
debconf-set-selections <<<"couchdb couchdb/bindaddress string 0.0.0.0"
debconf-set-selections <<<"couchdb couchdb/adminpass password $ADMIN_PASS"
debconf-set-selections <<<"couchdb couchdb/adminpass_again password $ADMIN_PASS"
setup_deb822_repo \
  "couchdb" \
  "https://couchdb.apache.org/repo/keys.asc" \
  "https://apache.jfrog.io/artifactory/couchdb-deb" \
  "$(get_os_info codename)" \
  "main"
$STD apt install -y couchdb
{
  echo "CouchDB Credentials"
  echo "CouchDB Erlang Cookie: $ERLANG_COOKIE"
  echo "CouchDB Admin Password: $ADMIN_PASS"
} >>~/couchdb.creds
msg_ok "Installed Apache CouchDB"

motd_ssh
customize
cleanup_lxc
