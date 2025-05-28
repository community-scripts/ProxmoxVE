#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: jkrgr0
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.2fauth.app/

APP="2FAuth"
var_tags="${var_tags:-2fa;authenticator}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  # Check if installation is present | -f for file, -d for folder
  if [[ ! -d "/opt/2fauth" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # Crawling the new version and checking whether an update is required
  RELEASE=$(curl -fsSL https://api.github.com/repos/Bubka/2FAuth/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ "${RELEASE}" != "$(cat /opt/2fauth_version.txt)" ]] || [[ ! -f /opt/2fauth_version.txt ]]; then
    msg_info "Updating $APP to ${RELEASE}"

    $STD apt-get update
    $STD apt-get -y upgrade

    # Creating Backup
    msg_info "Creating Backup"
    mv "/opt/2fauth" "/opt/2fauth-backup"
    if ! dpkg -l | grep -q 'php8.3'; then
      cp /etc/nginx/conf.d/2fauth.conf /etc/nginx/conf.d/2fauth.conf.bak
    fi
    msg_ok "Backup Created"

    # Upgrade PHP
    if ! dpkg -l | grep -q 'php8.3'; then
      $STD apt-get install -y \
        lsb-release \
        gpg
      curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/deb.sury.org-php.gpg
      echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" >/etc/apt/sources.list.d/php.list
      $STD apt-get update
      $STD apt-get install -y php8.3-{bcmath,common,ctype,curl,fileinfo,fpm,gd,mbstring,mysql,xml,cli,intl}
      sed -i 's/php8.2/php8.3/g' /etc/nginx/conf.d/2fauth.conf
    fi

    # Execute Update
    curl -fsSL -o "${RELEASE}.zip" "https://github.com/Bubka/2FAuth/archive/refs/tags/${RELEASE}.zip"
    $STD unzip "${RELEASE}.zip"
    mv "2FAuth-${RELEASE//v/}/" "/opt/2fauth"
    mv "/opt/2fauth-backup/.env" "/opt/2fauth/.env"
    mv "/opt/2fauth-backup/storage" "/opt/2fauth/storage"
    cd "/opt/2fauth" || return

    chown -R www-data: "/opt/2fauth"
    chmod -R 755 "/opt/2fauth"

    export COMPOSER_ALLOW_SUPERUSER=1
    $STD composer install --no-dev --prefer-source

    php artisan 2fauth:install

    $STD systemctl restart nginx

    # Cleaning up
    msg_info "Cleaning Up"
    rm -rf "v${RELEASE}.zip"
    if dpkg -l | grep -q 'php8.2'; then
      $STD apt-get remove --purge -y php8.2*
    fi
    $STD apt-get -y autoremove
    $STD apt-get -y autoclean
    msg_ok "Cleanup Completed"

    # Last Action
    echo "${RELEASE}" >/opt/2fauth_version.txt
    msg_ok "Updated $APP to ${RELEASE}"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:80${CL}"
