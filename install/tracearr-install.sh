#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: durzo
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/connorgallopo/Tracearr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y redis-server
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs
PG_VERSION="18" setup_postgresql

msg_info "Installing pnpm"
PNPM_VERSION="$(curl -fsSL "https://raw.githubusercontent.com/connorgallopo/Tracearr/refs/heads/main/package.json" | jq -r '.packageManager | split("@")[1]' | cut -d'+' -f1)"
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
$STD corepack enable pnpm
$STD corepack prepare pnpm@${PNPM_VERSION} --activate
msg_ok "Installed pnpm"

msg_info "Installing TimescaleDB"
setup_deb822_repo \
  "timescaledb" \
  "https://packagecloud.io/timescale/timescaledb/gpgkey" \
  "https://packagecloud.io/timescale/timescaledb/debian" \
  "$(get_os_info codename)"
  
$STD apt install -y \
    timescaledb-2-postgresql-18 \
    timescaledb-tools \
    timescaledb-toolkit-postgresql-18
total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
ram_for_tsdb=$((total_ram_kb / 1024 / 2))
$STD timescaledb-tune -yes -memory "$ram_for_tsdb"MB
$STD systemctl restart postgresql
msg_ok "Installed TimescaleDB"

PG_DB_NAME="tracearr_db" PG_DB_USER="tracearr" PG_DB_EXTENSIONS="timescaledb,timescaledb_toolkit" setup_postgresql_db
fetch_and_deploy_gh_release "tracearr" "connorgallopo/Tracearr" "tarball" "latest" "/opt/tracearr.build"

msg_info "Building Tracearr"
export TZ=$(cat /etc/timezone)
cd /opt/tracearr.build
$STD pnpm install --frozen-lockfile --force
$STD pnpm turbo telemetry disable
$STD pnpm turbo run build --no-daemon --filter=@tracearr/shared --filter=@tracearr/server --filter=@tracearr/web
mkdir -p /opt/tracearr/{packages/shared,apps/server,apps/web,apps/server/src/db}
cp -rf package.json /opt/tracearr/
cp -rf pnpm-workspace.yaml /opt/tracearr/
cp -rf pnpm-lock.yaml /opt/tracearr/
cp -rf apps/server/package.json /opt/tracearr/apps/server/
cp -rf apps/server/dist /opt/tracearr/apps/server/dist
cp -rf apps/web/dist /opt/tracearr/apps/web/dist
cp -rf packages/shared/package.json /opt/tracearr/packages/shared/
cp -rf packages/shared/dist /opt/tracearr/packages/shared/dist
cp -rf apps/server/src/db/migrations /opt/tracearr/apps/server/src/db/migrations
cp -rf data /opt/tracearr/data
mkdir -p /opt/tracearr/data/image-cache
rm -rf /opt/tracearr.build
cd /opt/tracearr
$STD pnpm install --prod --frozen-lockfile --ignore-scripts
msg_ok "Built Tracearr"

msg_info "Configuring Tracearr"
$STD useradd -r -s /bin/false -U tracearr
$STD chown -R tracearr:tracearr /opt/tracearr
install -d -m 750 -o tracearr -g tracearr /data/tracearr
export JWT_SECRET=$(openssl rand -hex 32)
export COOKIE_SECRET=$(openssl rand -hex 32)
cat <<EOF >/data/tracearr/.env
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@127.0.0.1:5432/${PG_DB_NAME}
REDIS_URL=redis://127.0.0.1:6379
PORT=3000
HOST=0.0.0.0
NODE_ENV=production
TZ=${TZ}
LOG_LEVEL=info
JWT_SECRET=$JWT_SECRET
COOKIE_SECRET=$COOKIE_SECRET
APP_VERSION=$(cat /root/.tracearr)
#CORS_ORIGIN=http://localhost:5173
#MOBILE_BETA_MODE=true
EOF
chmod 600 /data/tracearr/.env
chown -R tracearr:tracearr /data/tracearr
msg_ok "Configured Tracearr"

msg_info "Creating Services"
cat <<EOF >/data/tracearr/prestart.sh
#!/usr/bin/env bash
# =============================================================================
# Tune PostgreSQL for available resources (runs every startup)
# =============================================================================
# timescaledb-tune automatically optimizes PostgreSQL settings based on
# available RAM and CPU. Safe to run repeatedly - recalculates if resources change.
if command -v timescaledb-tune &> /dev/null; then
    total_ram_kb=\$(grep MemTotal /proc/meminfo | awk '{print \$2}')
    ram_for_tsdb=\$((total_ram_kb / 1024 / 2))
    timescaledb-tune -yes -memory "\$ram_for_tsdb"MB --quiet 2>/dev/null \
        || echo "Warning: timescaledb-tune failed (non-fatal)"
fi
# =============================================================================
# Ensure TimescaleDB decompression limit is set (for existing databases)
# =============================================================================
# This setting allows migrations to modify compressed hypertable data.
# Without it, bulk UPDATEs on compressed sessions will fail with
# "tuple decompression limit exceeded" errors.
pg_config_file="/etc/postgresql/18/main/postgresql.conf"
if [ -f \$pg_config_file ]; then
    if ! grep -q "max_tuples_decompressed_per_dml_transaction" \$pg_config_file; then
        echo "" >> \$pg_config_file
        echo "# Allow unlimited tuple decompression for migrations on compressed hypertables" >> \$pg_config_file
        echo "timescaledb.max_tuples_decompressed_per_dml_transaction = 0" >> \$pg_config_file
    fi
fi
systemctl restart postgresql
EOF
chmod +x /data/tracearr/prestart.sh
cat <<EOF >/lib/systemd/system/tracearr.service
[Unit]
Description=Tracearr Web Server
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
KillMode=control-group
EnvironmentFile=/data/tracearr/.env
WorkingDirectory=/opt/tracearr
ExecStartPre=+/data/tracearr/prestart.sh
ExecStart=node /opt/tracearr/apps/server/dist/index.js
Restart=on-failure
RestartSec=10
User=tracearr

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now postgresql redis-server tracearr
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
