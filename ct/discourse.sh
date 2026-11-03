#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.discourse.org/

APP="Discourse"
var_tags="${var_tags:-forum;community;discussion}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/discourse ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [[ ! -f /opt/discourse/.env ]]; then
    msg_error "No Discourse Configuration Found!"
    exit
  fi

  if grep -q 'X-Accel-Mapping' /etc/nginx/sites-available/discourse 2>/dev/null; then
    msg_info "Fixing stylesheet delivery in Nginx"
    sed -i '/X-Accel-Mapping/d' /etc/nginx/sites-available/discourse
    $STD systemctl reload nginx
    msg_ok "Fixed stylesheet delivery in Nginx"
  fi

  msg_info "Stopping Services"
  systemctl stop discourse discourse-sidekiq
  msg_ok "Stopped Services"

  msg_info "Updating Discourse"
  cd /opt/discourse
  export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
  export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
  export BUNDLE_SILENCE_ROOT_WARNING=1
  set -a
  source /opt/discourse/.env
  set +a
  $STD git pull origin main
  msg_ok "Updated Discourse"

  if check_for_gh_release "libvips" "libvips/libvips"; then
    ensure_dependencies meson ninja-build pkg-config libglib2.0-dev libexpat1-dev libjpeg-dev libpng-dev libwebp-dev libtiff-dev libheif-dev libjxl-dev librsvg2-dev libcgif-dev libexif-dev liblcms2-dev liborc-0.4-dev libimagequant-dev libpango1.0-dev
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "libvips" "libvips/libvips" "prebuild" "latest" "/opt/libvips" "vips-*.tar.xz"
    msg_info "Building libvips"
    cd /opt/libvips
    $STD meson setup build --prefix=/usr/local --libdir=lib --buildtype=release -Dmodules=disabled -Dmagick=disabled -Dexamples=false
    $STD ninja -C build install
    ldconfig
    msg_ok "Built libvips"
  fi

  msg_info "Updating Dependencies"
  RUBY_TARGET=$(grep -A1 '^RUBY VERSION' /opt/discourse/Gemfile.lock | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
  RUBY_VERSION="${RUBY_TARGET:-4.0.7}" RUBY_INSTALL_RAILS="false" setup_ruby
  export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
  hash -r
  cd /opt/discourse
  $STD bundle install -j"$(nproc)"
  $STD pnpm install
  msg_ok "Updated Dependencies"

  msg_info "Running Database Migrations"
  $STD runuser -u postgres -- psql -d discourse -c "CREATE EXTENSION IF NOT EXISTS vector;"
  $STD bundle exec rails db:migrate
  msg_ok "Ran Database Migrations"

  msg_info "Precompiling Assets"
  $STD bundle exec rails assets:precompile
  msg_ok "Precompiled Assets"

  msg_info "Starting Services"
  systemctl start discourse discourse-sidekiq
  msg_ok "Started Services"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
