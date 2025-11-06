#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pterodactyl/panel

APP="Pterodactyl-Panel"
var_tags="${var_tags:-gaming}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /opt/pterodactyl-panel ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  CURRENT_PHP=$(php -v 2>/dev/null | awk '/^PHP/{print $2}' | cut -d. -f1,2)

  if [[ "$CURRENT_PHP" != "8.4" ]]; then
    msg_info "Migrating PHP $CURRENT_PHP to 8.4"
    $STD curl -fsSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
    $STD dpkg -i /tmp/debsuryorg-archive-keyring.deb
    $STD sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
    cat <<EOF >/etc/apt/sources.list.d/php.sources
Types: deb
URIs: https://packages.sury.org/php/
Suites: $(lsb_release -sc)
Components: main
Signed-By: /usr/share/keyrings/deb.sury.org-php.gpg
EOF
    $STD apt update
    $STD apt remove -y php"${CURRENT_PHP//./}"*
    $STD apt install -y \
      php8.4 \
      php8.4-{gd,mysql,mbstring,bcmath,xml,curl,zip,intl,fpm} \
      libapache2-mod-php8.4

    msg_ok "Migrated PHP $CURRENT_PHP to 8.4"
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/pterodactyl/panel/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    cd /opt/pterodactyl-panel
    $STD php artisan down
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to v${RELEASE}"
    cp -r /opt/pterodactyl-panel/.env /opt/
    rm -rf * .*
    curl -fsSL "https://github.com/pterodactyl/panel/releases/download/v${RELEASE}/panel.tar.gz" -o $(basename "https://github.com/pterodactyl/panel/releases/download/v${RELEASE}/panel.tar.gz")
    tar -xzf "panel.tar.gz"
    mv /opt/.env /opt/pterodactyl-panel/
    $STD composer install --no-dev --optimize-autoloader --no-interaction
    $STD php artisan view:clear
    $STD php artisan config:clear
    $STD php artisan migrate --seed --force --no-interaction
    chown -R www-data:www-data /opt/pterodactyl-panel/*
    chmod -R 755 /opt/pterodactyl-panel/storage /opt/pterodactyl-panel/bootstrap/cache/
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting Service"
    $STD php artisan queue:restart
    $STD php artisan up
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -rf "/opt/pterodactyl-panel/panel.tar.gz"
    msg_ok "Cleaned"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
