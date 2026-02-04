#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: durzo
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/connorgallopo/Tracearr

APP="Tracearr"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
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
  if [[ ! -f /lib/systemd/system/tracearr.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" setup_nodejs

  msg_info "Updating prestart script"
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
# Ensure required PostgreSQL settings for Tracearr
# =============================================================================
pg_config_file="/etc/postgresql/18/main/postgresql.conf"
if [ -f \$pg_config_file ]; then
    # Ensure max_tuples_decompressed_per_dml_transaction is set
    if grep -q "^timescaledb\.max_tuples_decompressed_per_dml_transaction" \$pg_config_file; then
        # Setting exists (uncommented) - update if not 0
        current_value=\$(grep "^timescaledb\.max_tuples_decompressed_per_dml_transaction" \$pg_config_file | grep -oE '[0-9]+' | head -1)
        if [ -n "\$current_value" ] && [ "\$current_value" -ne 0 ]; then
            sed -i "s/^timescaledb\.max_tuples_decompressed_per_dml_transaction.*/timescaledb.max_tuples_decompressed_per_dml_transaction = 0/" \$pg_config_file
        fi
    elif ! grep -q "^timescaledb\.max_tuples_decompressed_per_dml_transaction" \$pg_config_file; then
        echo "" >> \$pg_config_file
        echo "# Allow unlimited tuple decompression for migrations on compressed hypertables" >> \$pg_config_file
        echo "timescaledb.max_tuples_decompressed_per_dml_transaction = 0" >> \$pg_config_file
    fi
    # Ensure max_locks_per_transaction is set (for existing databases)
    if grep -q "^max_locks_per_transaction" \$pg_config_file; then
        # Setting exists (uncommented) - update if below 4096
        current_value=\$(grep "^max_locks_per_transaction" \$pg_config_file | grep -oE '[0-9]+' | head -1)
        if [ -n "\$current_value" ] && [ "\$current_value" -lt 4096 ]; then
            sed -i "s/^max_locks_per_transaction.*/max_locks_per_transaction = 4096/" \$pg_config_file
        fi
    elif ! grep -q "^max_locks_per_transaction" \$pg_config_file; then
        echo "" >> \$pg_config_file
        echo "# Increase lock table size for TimescaleDB hypertables with many chunks" >> \$pg_config_file
        echo "max_locks_per_transaction = 4096" >> \$pg_config_file
    fi
fi
systemctl restart postgresql
EOF
  chmod +x /data/tracearr/prestart.sh
  msg_ok "Updated prestart script"

  if check_for_gh_release "tracearr" "connorgallopo/Tracearr"; then
    msg_info "Stopping Services"
    systemctl stop tracearr postgresql redis
    msg_ok "Stopped Services"

    msg_info "Updating pnpm"
    PNPM_VERSION="$(curl -fsSL "https://raw.githubusercontent.com/connorgallopo/Tracearr/refs/heads/main/package.json" | jq -r '.packageManager | split("@")[1]' | cut -d'+' -f1)"
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    $STD corepack prepare pnpm@${PNPM_VERSION} --activate
    msg_ok "Updated pnpm"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "tracearr" "connorgallopo/Tracearr" "tarball" "latest" "/opt/tracearr.build"

    msg_info "Building Tracearr"
    export TZ=$(cat /etc/timezone)
    cd /opt/tracearr.build
    $STD pnpm install --frozen-lockfile --force
    $STD pnpm turbo telemetry disable
    $STD pnpm turbo run build --no-daemon --filter=@tracearr/shared --filter=@tracearr/server --filter=@tracearr/web
    rm -rf /opt/tracearr
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
    $STD chown -R tracearr:tracearr /opt/tracearr
    msg_ok "Built Tracearr"

    msg_info "Configuring Tracearr"
    sed -i "s/^APP_VERSION=.*/APP_VERSION=$(cat /root/.tracearr)/" /data/tracearr/.env
    chmod 600 /data/tracearr/.env
    chown -R tracearr:tracearr /data/tracearr
    msg_ok "Configured Tracearr"

    msg_info "Starting services"
    systemctl start postgresql redis tracearr
    msg_ok "Started services"
    msg_ok "Updated successfully!"
  else
    # no new release, just restart service to apply prestart changes
    msg_info "Restarting service"
    systemctl restart tracearr
    msg_ok "Restarted service"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
