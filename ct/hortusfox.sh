#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ) | Co-Author: Tom Frenzel (tomfrenzel)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/danielbrendel/hortusfox-web

APP="HortusFox"
var_tags="${var_tags:-plants}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/hortusfox ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  setup_mariadb
  if check_for_gh_release "hortusfox" "danielbrendel/hortusfox-web"; then
    msg_info "Stopping Service"
    systemctl stop apache2
    msg_ok "Stopped Service"

    cd /opt/hortusfox
    if [[ ! -s app/migrations/migrations.list ]]; then
      msg_info "Rebuilding HortusFox migration history"
      local database_tables
      database_tables="$(mariadb -u root -D hortusfox -NBe "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE();")"
      : >app/migrations/migrations.list
      local migration migration_file table_name
      for migration in app/migrations/*.php; do
        migration_file="${migration##*/}"
        table_name="${migration_file%.php}"
        if [[ "$migration_file" == "VersionModel.php" ]] || grep -Fxq "$table_name" <<<"$database_tables"; then
          php -r 'echo hash("sha512", $argv[1]), PHP_EOL;' -- "$migration_file" >>app/migrations/migrations.list
        fi
      done
      msg_ok "Rebuilt HortusFox migration history"
    fi
    if [[ ! -f app/migrations/verhist.json && -f ~/.hortusfox ]]; then
      printf '["%s"]\n' "$(<~/.hortusfox)" >app/migrations/verhist.json
    fi

    create_backup \
      /opt/hortusfox/.env \
      /opt/hortusfox/app/migrations/migrations.list \
      /opt/hortusfox/app/migrations/verhist.json \
      /opt/hortusfox/public/img \
      /opt/hortusfox/public/attachments \
      /opt/hortusfox/public/backup \
      /opt/hortusfox/public/exports \
      /opt/hortusfox/public/snd \
      /opt/hortusfox/public/themes

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "hortusfox" "danielbrendel/hortusfox-web" "tarball"
    restore_backup

    msg_info "Updating HortusFox"
    cd /opt/hortusfox
    export COMPOSER_ALLOW_SUPERUSER=1
    $STD composer install --no-dev --optimize-autoloader
    $STD php asatru migrate:list
    $STD php asatru migrate:upgrade
    $STD php asatru calendar:classes
    $STD php asatru plants:attributes
    $STD php asatru aquashell:config
    chown -R www-data:www-data /opt/hortusfox
    msg_ok "Updated HortusFox"

    msg_info "Starting Service"
    systemctl start apache2
    msg_ok "Started Service"

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
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
