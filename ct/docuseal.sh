#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.docuseal.com/

APP="DocuSeal"
var_tags="${var_tags:-document;esignature;pdf}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
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

  if [[ ! -d /opt/docuseal ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  ensure_dependencies musl
  [[ -f /opt/pdfium/lib/libpdfium.so ]] || rm -f "$HOME/.pdfium"
  fetch_and_deploy_gh_release "pdfium" "docusealco/pdfium-binaries" "prebuild" "latest" "/opt/pdfium" "pdfium-musl-$(arch_resolve "x86_64" "aarch64").zip"
  if ! cmp -s /opt/pdfium/lib/libpdfium.so /usr/lib/libpdfium.so; then
    msg_info "Updating PDFium"
    install -m 644 /opt/pdfium/lib/libpdfium.so /usr/lib/libpdfium.so
    echo "/usr/lib/$(arch_resolve "x86_64" "aarch64")-linux-musl" >/etc/ld.so.conf.d/musl.conf
    ldconfig
    systemctl restart docuseal docuseal-sidekiq
    msg_ok "Updated PDFium"
  fi

  if check_for_gh_release "docuseal" "docusealco/docuseal"; then
    msg_info "Stopping Services"
    systemctl stop docuseal docuseal-sidekiq
    msg_ok "Stopped Services"

    ensure_dependencies libleptonica-dev libleptonica6

    create_backup /opt/docuseal/.env \
      /opt/docuseal/data

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "docuseal" "docusealco/docuseal" "tarball"

    local required_ruby current_ruby
    required_ruby=$(grep -m1 '^ruby ' /opt/docuseal/Gemfile | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')
    current_ruby=$(PATH="/root/.rbenv/bin:/root/.rbenv/shims:${PATH}" rbenv global 2>/dev/null || true)
    if [[ -n $required_ruby && $required_ruby != "$current_ruby" ]]; then
      RUBY_VERSION="${required_ruby}" RUBY_INSTALL_RAILS="false" HOME=/root setup_ruby
    fi

    restore_backup

    msg_info "Building Application"
    cd /opt/docuseal
    export PATH="/root/.rbenv/bin:/root/.rbenv/shims:${PATH}"
    eval "$(rbenv init - bash)" 2>/dev/null || true
    export RAILS_ENV=production
    export NODE_ENV=production
    mkdir -p /opt/docuseal/tmp
    set -a
    source /opt/docuseal/.env
    set +a
    $STD bundle config set --local deployment 'true'
    $STD bundle config set --local without 'development:test'
    $STD bundle install -j"$(nproc)"
    $STD yarn install --network-timeout 1000000
    $STD ./bin/shakapacker
    $STD bundle exec rails db:migrate
    $STD bundle exec bootsnap precompile -j 1 --gemfile app/ lib/
    chown -R docuseal:docuseal /opt/docuseal
    msg_ok "Built Application"

    msg_info "Starting Services"
    systemctl start docuseal docuseal-sidekiq
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
