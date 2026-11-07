#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mozilla-services/syncstorage-rs

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
  libssl-dev \
  libpq-dev \
  python3-dev
msg_ok "Installed Dependencies"

PG_VERSION="18" setup_postgresql
PG_DB_NAME="syncserver" PG_DB_USER="syncserver" setup_postgresql_db
setup_rust
setup_uv

fetch_and_deploy_gh_release "firefox-syncserver" "mozilla-services/syncstorage-rs" "tarball"

msg_info "Building Firefox Syncserver (Patience)"
cd /opt/firefox-syncserver
$STD cargo build --release --locked --no-default-features --features=syncstorage-db/postgres --features=tokenserver-db/postgres --features=py_verifier
cp target/release/syncserver /usr/local/bin/syncserver
rm -rf target
# The binary embeds the system libpython, so the verifier packages must be built for that same interpreter
$STD uv venv --python /usr/bin/python3 /opt/firefox-syncserver/.venv
$STD uv pip install --python /opt/firefox-syncserver/.venv/bin/python pyfxa tokenlib cryptography
msg_ok "Built Firefox Syncserver"

msg_info "Configuring Firefox Syncserver"
mkdir -p /opt/firefox-syncserver_data
cat <<EOF >/opt/firefox-syncserver_data/.env
SYNC_HOST=0.0.0.0
SYNC_PORT=8000
SYNC_MASTER_SECRET=$(openssl rand -hex 32)
SYNC_HUMAN_LOGS=true
RUST_LOG=info
SYNC_SYNCSTORAGE__DATABASE_URL=postgres://syncserver:${PG_DB_PASS}@127.0.0.1:5432/syncserver
SYNC_SYNCSTORAGE__GLEAN_ENABLED=false
SYNC_TOKENSERVER__ENABLED=true
SYNC_TOKENSERVER__RUN_MIGRATIONS=true
SYNC_TOKENSERVER__DATABASE_URL=postgres://syncserver:${PG_DB_PASS}@127.0.0.1:5432/syncserver
SYNC_TOKENSERVER__NODE_TYPE=postgres
SYNC_TOKENSERVER__FXA_EMAIL_DOMAIN=api.accounts.firefox.com
SYNC_TOKENSERVER__FXA_OAUTH_SERVER_URL=https://oauth.accounts.firefox.com
SYNC_TOKENSERVER__INIT_NODE_URL=http://${LOCAL_IP}:8000
EOF
chmod 600 /opt/firefox-syncserver_data/.env
# The server only ever inserts INIT_NODE_URL; keep it the single node so a changed URL needs just a restart
cat <<'EOF' >/opt/firefox-syncserver_data/nodes.sql
SELECT to_regclass('nodes') IS NOT NULL AS ready \gset
\if :ready
UPDATE nodes SET node = :'url'
 WHERE id = (SELECT min(id) FROM nodes)
   AND NOT EXISTS (SELECT 1 FROM nodes WHERE node = :'url');
UPDATE users SET nodeid = (SELECT id FROM nodes WHERE node = :'url')
 WHERE nodeid <> (SELECT id FROM nodes WHERE node = :'url');
DELETE FROM nodes WHERE node <> :'url';
\endif
EOF
msg_ok "Configured Firefox Syncserver"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/firefox-syncserver.service
[Unit]
Description=Firefox Syncserver
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/firefox-syncserver
EnvironmentFile=/opt/firefox-syncserver_data/.env
Environment=PYTHONPATH=/opt/firefox-syncserver/.venv/lib/python3.13/site-packages
ExecStartPre=/usr/bin/psql -1 -q -v ON_ERROR_STOP=1 -v url=\${SYNC_TOKENSERVER__INIT_NODE_URL} -f /opt/firefox-syncserver_data/nodes.sql \${SYNC_TOKENSERVER__DATABASE_URL}
ExecStart=/usr/local/bin/syncserver
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now firefox-syncserver
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
