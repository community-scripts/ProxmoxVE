#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://pangolin.net/ | Github: https://github.com/fosrl/pangolin

APP="Pangolin"
PANGOLIN_VERSION="${PANGOLIN_VERSION:-1.20.0}"
var_tags="${var_tags:-proxy}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
var_tun="${var_tun:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/pangolin ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  ensure_dependencies build-essential python3

  NODE_VERSION="24" setup_nodejs

  if check_for_gh_release "pangolin" "fosrl/pangolin" "$PANGOLIN_VERSION" "Pinned to a tested release because Pangolin's schema changes have repeatedly broken unattended updates. To try a newer version at your own risk, run: 'export PANGOLIN_VERSION=<tag>' and re-run update. If it breaks, please open an issue at https://github.com/community-scripts/ProxmoxVE/issues with the error log."; then
    msg_info "Stopping Service"
    systemctl stop pangolin
    systemctl stop gerbil
    msg_info "Service stopped"

    msg_info "Creating backup"
    tar -czf /opt/pangolin_config_backup.tar.gz -C /opt/pangolin config
    if [[ -f /opt/pangolin/config/db/db.sqlite ]]; then
      cp -a /opt/pangolin/config/db/db.sqlite \
        "/opt/pangolin/config/db/db.sqlite.pre-${PANGOLIN_VERSION}-$(date +%Y%m%d-%H%M%S).bak"
    fi
    msg_ok "Created backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "pangolin" "fosrl/pangolin" "tarball" "$PANGOLIN_VERSION"
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "gerbil" "fosrl/gerbil" "singlefile" "latest" "/usr/bin" "gerbil_linux_$(arch_resolve)"

    msg_info "Updating Pangolin"
    cd /opt/pangolin
    $STD npm ci
    $STD npm run set:sqlite
    $STD npm run set:oss
    rm -rf server/private
    $STD npm run db:generate
    $STD npm run build
    $STD npm run build:cli
    cp -R .next/standalone ./
    chmod +x ./dist/cli.mjs
    cp server/db/names.json ./dist/names.json
    cp server/db/ios_models.json ./dist/ios_models.json
    cp server/db/mac_models.json ./dist/mac_models.json
    msg_ok "Updated Pangolin"

    msg_info "Restoring config"
    tar -xzf /opt/pangolin_config_backup.tar.gz -C /opt/pangolin --overwrite
    rm -f /opt/pangolin_config_backup.tar.gz
    msg_ok "Restored config"

    if ! grep -q '^ExecStartPre=/usr/bin/node dist/migrations.mjs' /etc/systemd/system/pangolin.service 2>/dev/null; then
      msg_info "Adding migration step to pangolin.service"
      sed -i '/^ExecStart=\/usr\/bin\/node --enable-source-maps dist\/server.mjs/i ExecStartPre=/usr/bin/node dist/migrations.mjs' /etc/systemd/system/pangolin.service
      systemctl daemon-reload
      msg_ok "Updated pangolin.service"
    fi

    sqlite_table_exists() {
      local db_path="$1"
      local table_name="$2"
      sqlite3 "$db_path" "SELECT 1 FROM sqlite_master WHERE type='table' AND name='$table_name' LIMIT 1;" 2>/dev/null | grep -q '^1$'
    }

    sqlite_column_exists() {
      local db_path="$1"
      local table_name="$2"
      local column_name="$3"
      sqlite3 "$db_path" "PRAGMA table_info('$table_name');" 2>/dev/null | awk -F'|' -v col="$column_name" '$2==col{found=1} END{exit !found}'
    }

    sqlite_schema_ready_for_120() {
      local db_path="$1"
      sqlite_table_exists "$db_path" "remoteExitNodePreferenceLabels" &&
        sqlite_table_exists "$db_path" "remoteExitNodeResources" &&
        sqlite_table_exists "$db_path" "launcherViews" &&
        sqlite_column_exists "$db_path" "domains" "customCertResolver" &&
        sqlite_column_exists "$db_path" "domains" "lastCheckedAt"
    }

    sqlite_value() {
      local db_path="$1"
      local query="$2"
      sqlite3 "$db_path" "$query" 2>/dev/null | tr -d '[:space:]'
    }

    prepare_sqlite_for_120_replay() {
      local db_path="$1"
      local has_120
      local vm_count

      has_120="$(sqlite_value "$db_path" "SELECT COUNT(*) FROM versionMigrations WHERE version='1.20.0';")"
      vm_count="$(sqlite_value "$db_path" "SELECT COUNT(*) FROM versionMigrations;")"

      if [[ "${has_120:-0}" -gt 0 ]]; then
        msg_info "Detected stale migration marker for 1.20.0; forcing replay"
        sqlite3 "$db_path" "DELETE FROM versionMigrations WHERE version='1.20.0';" 2>/dev/null || true
        vm_count="$(sqlite_value "$db_path" "SELECT COUNT(*) FROM versionMigrations;")"
      fi

      if [[ "${vm_count:-0}" -eq 0 ]]; then
        msg_info "Migration history is empty; seeding baseline 1.19.1 so 1.20.0 migration can run"
        sqlite3 "$db_path" "INSERT INTO versionMigrations (version, executedAt) VALUES ('1.19.1', CAST(strftime('%s','now') AS INTEGER) * 1000);" 2>/dev/null || true
      fi
    }

    run_sqlite_migrations() {
      ENVIRONMENT=prod $STD node dist/migrations.mjs
    }

    msg_info "Running database migrations"
    cd /opt/pangolin
    SQLITE_DB="/opt/pangolin/config/db/db.sqlite"
    if [[ -f "$SQLITE_DB" ]]; then
      if ! sqlite_table_exists "$SQLITE_DB" "statusHistory"; then
        sqlite3 "$SQLITE_DB" "DELETE FROM versionMigrations;" 2>/dev/null || true
      fi

      if [[ "$PANGOLIN_VERSION" == "1.20.0" ]] && ! sqlite_schema_ready_for_120 "$SQLITE_DB"; then
        prepare_sqlite_for_120_replay "$SQLITE_DB"
      fi
    fi

    run_sqlite_migrations

    if [[ -f "$SQLITE_DB" ]] && [[ "$PANGOLIN_VERSION" == "1.20.0" ]] && ! sqlite_schema_ready_for_120 "$SQLITE_DB"; then
      msg_info "Schema check failed after first pass; retrying 1.20.0 migration"
      prepare_sqlite_for_120_replay "$SQLITE_DB"
      run_sqlite_migrations
    fi

    if [[ -f "$SQLITE_DB" ]] && [[ "$PANGOLIN_VERSION" == "1.20.0" ]] && ! sqlite_schema_ready_for_120 "$SQLITE_DB"; then
      msg_error "SQLite schema is still incomplete after migration replay (expected 1.20.0 schema). Aborting update to prevent broken runtime."
      exit 1
    fi

    msg_ok "Ran database migrations"

    msg_info "Updating Badger plugin version"
    BADGER_VERSION=$(get_latest_github_release "fosrl/badger" "false")
    sed -i "s/version: \"v[0-9.]*\"/version: \"$BADGER_VERSION\"/g" /opt/pangolin/config/traefik/traefik_config.yml
    msg_ok "Updated Badger plugin version"

    msg_info "Starting Services"
    systemctl start pangolin
    systemctl start gerbil
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}https://<YOUR_PANGOLIN_URL>${CL}"
