#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Termix-SSH/Termix

APP="Termix"
var_tags="${var_tags:-ssh;terminal;management}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
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

  if [[ ! -d /opt/termix ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "termix" "Termix-SSH/Termix"; then
    msg_info "Stopping Service"
    systemctl stop termix
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/termix/data /opt/termix_data_backup
    cp -r /opt/termix/uploads /opt/termix_uploads_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "termix" "Termix-SSH/Termix"

    msg_info "Recreating Directories"
    mkdir -p /opt/termix/html \
      /opt/termix/nginx \
      /opt/termix/nginx/logs \
      /opt/termix/nginx/cache \
      /opt/termix/nginx/client_body
    msg_ok "Recreated Directories"

    msg_info "Building Frontend"
    cd /opt/termix
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    find public/fonts -name "*.ttf" ! -name "*Regular.ttf" ! -name "*Bold.ttf" ! -name "*Italic.ttf" -delete 2>/dev/null || true
    $STD npm install --ignore-scripts --force
    $STD npm run build
    msg_ok "Built Frontend"

    msg_info "Building Backend"
    $STD npm rebuild better-sqlite3 --force
    $STD npm run build:backend
    msg_ok "Built Backend"

    msg_info "Setting up Production Dependencies"
    $STD npm ci --only=production --ignore-scripts --force
    $STD npm rebuild better-sqlite3 bcryptjs --force
    $STD npm cache clean --force
    msg_ok "Set up Production Dependencies"

    msg_info "Restoring Data"
    cp -r /opt/termix_data_backup /opt/termix/data
    cp -r /opt/termix_uploads_backup /opt/termix/uploads
    rm -rf /opt/termix_data_backup /opt/termix_uploads_backup
    msg_ok "Restored Data"

    msg_info "Updating Frontend Files"
    rm -rf /opt/termix/html/*
    cp -r /opt/termix/dist/* /opt/termix/html/ 2>/dev/null || true
    cp -r /opt/termix/src/locales /opt/termix/html/locales 2>/dev/null || true
    cp -r /opt/termix/public/fonts /opt/termix/html/fonts 2>/dev/null || true
    msg_ok "Updated Frontend Files"

    msg_warn "The Nginx configuration may need to be updated for new features to work."
    msg_custom "💾" "Your current config will be backed up to nginx.conf.bak"
    msg_custom "⚠️ " "Note: Custom modifications (reverse proxy, SSL) will be overwritten!"
    echo ""
    read -rp "${TAB3}Update Nginx configuration? [Y/n]: " REPLY
    if [[ "${REPLY,,}" =~ ^(y|yes|)$ ]]; then
      msg_info "Updating Nginx Configuration"
      cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
      curl -fsSL "https://raw.githubusercontent.com/Termix-SSH/Termix/main/docker/nginx.conf" -o /etc/nginx/nginx.conf
      sed -i '/^master_process/d' /etc/nginx/nginx.conf
      sed -i '/^pid \/app\/nginx/d' /etc/nginx/nginx.conf
      sed -i 's|/app/html|/opt/termix/html|g' /etc/nginx/nginx.conf
      sed -i 's|/app/nginx|/opt/termix/nginx|g' /etc/nginx/nginx.conf
      sed -i 's|listen ${PORT};|listen 80;|g' /etc/nginx/nginx.conf
      
      nginx -t && systemctl reload nginx
      msg_ok "Updated Nginx Configuration"
    else
      msg_warn "Nginx configuration not updated. If Termix doesn't work, restore from backup or update manually."
    fi

    msg_info "Starting Service"
    systemctl start termix
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
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
