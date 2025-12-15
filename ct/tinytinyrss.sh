#!/usr/bin/env bash

# Force verbose mode for debugging
set -x

# Detectar automáticamente la URL base del repositorio (fork o repo principal)
detect_repo_base_url() {
  local repo_owner="community-scripts"
  local repo_name="ProxmoxVE"
  local branch="main"
  local remote_url
  local current_branch

  # Intentar detectar desde git si estamos en un repo local
  if command -v git &>/dev/null && git rev-parse --git-dir &>/dev/null 2>&1; then
    if remote_url=$(git config --get remote.origin.url 2>/dev/null); then
      if [[ $remote_url =~ git@github.com:([^/]+)/([^/]+) ]]; then
        repo_owner="${BASH_REMATCH[1]}"
        repo_name="${BASH_REMATCH[2]%.git}"
      elif [[ $remote_url =~ github.com[:/]([^/]+)/([^/]+) ]]; then
        repo_owner="${BASH_REMATCH[1]}"
        repo_name="${BASH_REMATCH[2]%.git}"
      fi
      if current_branch=$(git branch --show-current 2>/dev/null); then
        branch="$current_branch"
      fi
    fi
  fi

  # Permitir override con variables de entorno
  repo_owner="${GITHUB_REPO_OWNER:-$repo_owner}"
  repo_name="${GITHUB_REPO_NAME:-$repo_name}"
  branch="${GITHUB_BRANCH:-$branch}"

  echo "https://raw.githubusercontent.com/${repo_owner}/${repo_name}/refs/heads/${branch}"
}

# Obtener URL base del repo (se detecta automáticamente en desarrollo, usa defaults en producción)
# Para testing con app defaults, usar upstream para evitar problemas con build.func del fork
if [[ -n "${USE_UPSTREAM_BUILD_FUNC:-}" ]]; then
  REPO_BASE_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
else
  echo "--- DEBUG: Raw detect_repo_base_url output: $(detect_repo_base_url) ---"
  REPO_BASE_URL="${REPO_BASE_URL:-$(detect_repo_base_url)}"
fi

echo "--- DEBUG: REPO_BASE_URL (before export): $REPO_BASE_URL ---"
# Exportar para que build.func pueda usar esta variable si está disponible
export REPO_BASE_URL
echo "--- DEBUG: REPO_BASE_URL (after export): $REPO_BASE_URL ---"

source <(curl -fsSL "${REPO_BASE_URL}/misc/build.func")
# Copyright (c) 2021-2025 community-scripts ORG
# Author: mrosero
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tt-rss.org/

APP="TinyTinyRSS"
var_tags="${var_tags:-RSS;feed-reader}"
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
  if [[ ! -d /opt/tt-rss ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping Services"
  systemctl stop apache2
  msg_ok "Stopped Services"

  msg_info "Backing up Configuration"
  if [ -f /opt/tt-rss/config.php ]; then
    cp /opt/tt-rss/config.php /opt/tt-rss/config.php.backup
    msg_ok "Backed up Configuration"
  fi
  if [ -d /opt/tt-rss/feed-icons ]; then
    mv /opt/tt-rss/feed-icons /opt/tt-rss/feed-icons.backup
    msg_ok "Backed up Feed Icons"
  fi

  msg_info "Updating ${APP} to latest version"
  curl -fsSL https://github.com/tt-rss/tt-rss/archive/refs/heads/main.tar.gz -o /tmp/tt-rss-update.tar.gz
  $STD tar -xzf /tmp/tt-rss-update.tar.gz -C /tmp
  $STD cp -r /tmp/tt-rss-main/* /opt/tt-rss/
  rm -rf /tmp/tt-rss-update.tar.gz /tmp/tt-rss-main
  echo "main" >"/opt/TinyTinyRSS_version.txt"
  msg_ok "Downloaded latest version"

  if [ -f /opt/tt-rss/config.php.backup ]; then
    cp /opt/tt-rss/config.php.backup /opt/tt-rss/config.php
    msg_ok "Restored Configuration"
  fi
  if [ -d /opt/tt-rss/feed-icons.backup ]; then
    mv /opt/tt-rss/feed-icons.backup /opt/tt-rss/feed-icons
    msg_ok "Restored Feed Icons"
  fi

  msg_info "Setting Permissions"
  chown -R www-data:www-data /opt/tt-rss
  chmod -R g+rX /opt/tt-rss
  chmod -R g+w /opt/tt-rss/feed-icons /opt/tt-rss/lock /opt/tt-rss/cache
  msg_ok "Set Permissions"

  msg_info "Starting Services"
  systemctl start apache2
  msg_ok "Started Services"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
