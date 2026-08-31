#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dani-garcia/vaultwarden

APP="Vaultwarden"
var_tags="${var_tags:-password-manager}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
if [[ -z "${var_os:-}" ]] && command -v pveversion >/dev/null 2>&1; then
  var_os=$(msg_menu "Choose the container OS" \
    "debian" "Debian 13" \
    "alpine" "Alpine (smaller footprint)")
fi

if [[ "${var_os:-}" == "alpine" ]]; then
  var_cpu="${var_cpu:-1}"
  var_ram="${var_ram:-256}"
  var_disk="${var_disk:-1}"
  var_version="${var_version:-3.24}"
else
  var_cpu="${var_cpu:-4}"
  var_ram="${var_ram:-6144}"
  var_disk="${var_disk:-20}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

update_deb_based() {
  if [[ ! -f /etc/systemd/system/vaultwarden.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  VAULT=$(get_latest_github_release "dani-garcia/vaultwarden")
  WVRELEASE=$(get_latest_github_release "dani-garcia/bw_web_builds")

  UPD=$(msg_menu "Vaultwarden Update Options" \
    "1" "Update VaultWarden + Web-Vault" \
    "2" "Set Admin Token")

  if [ "$UPD" == "1" ]; then
    INSTALLED_VERSION="$(/opt/vaultwarden/bin/vaultwarden --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true)"
    if [[ -n "$INSTALLED_VERSION" ]] &&
      ! grep -qxF "$INSTALLED_VERSION" "$HOME/.vaultwarden" 2>/dev/null; then
      printf '%s\n' "$INSTALLED_VERSION" >"$HOME/.vaultwarden"
    fi
    if check_for_gh_release "vaultwarden" "dani-garcia/vaultwarden"; then
      msg_info "Stopping Service"
      systemctl stop vaultwarden
      msg_ok "Stopped Service"

      fetch_and_deploy_gh_release "vaultwarden" "dani-garcia/vaultwarden" "tarball" "latest" "/tmp/vaultwarden-src"

      msg_info "Updating VaultWarden to $VAULT (Patience)"
      cd /tmp/vaultwarden-src
      VW_VERSION="$VAULT"
      export VW_VERSION
      CARGO_BUILD_JOBS="$(get_parallel_jobs)" CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 $STD cargo build --features "sqlite,mysql,postgresql" --release
      if [[ -f /usr/bin/vaultwarden ]]; then
        cp target/release/vaultwarden /usr/bin/
      else
        cp target/release/vaultwarden /opt/vaultwarden/bin/
      fi
      cd ~ && rm -rf /tmp/vaultwarden-src
      msg_ok "Updated VaultWarden to ${VAULT}"

      msg_info "Starting Service"
      systemctl start vaultwarden
      msg_ok "Started Service"
    else
      msg_ok "VaultWarden is already up-to-date"
    fi

    if check_for_gh_release "vaultwarden_webvault" "dani-garcia/bw_web_builds"; then
      msg_info "Stopping Service"
      systemctl stop vaultwarden
      msg_ok "Stopped Service"

      msg_info "Updating Web-Vault to $WVRELEASE"
      rm -rf /opt/vaultwarden/web-vault
      mkdir -p /opt/vaultwarden/web-vault

      fetch_and_deploy_gh_release "vaultwarden_webvault" "dani-garcia/bw_web_builds" "prebuild" "latest" "/opt/vaultwarden/web-vault" "bw_web_*.tar.gz"

      chown -R root:root /opt/vaultwarden/web-vault/
      msg_ok "Updated Web-Vault to ${WVRELEASE}"

      msg_info "Starting Service"
      systemctl start vaultwarden
      msg_ok "Started Service"
    else
      msg_ok "Web-Vault is already up-to-date"
    fi

    msg_ok "Updated successfully!"
    exit
  fi

  if [ "$UPD" == "2" ]; then
    if [[ "${PHS_SILENT:-0}" == "1" ]]; then
      msg_warn "Set Admin Token requires interactive mode, skipping."
      exit
    fi
    read -r -s -p "Set the ADMIN_TOKEN: " NEWTOKEN
    echo ""
    if [[ -n "$NEWTOKEN" ]]; then
      ensure_dependencies argon2
      TOKEN=$(echo -n "${NEWTOKEN}" | argon2 "$(openssl rand -base64 32)" -t 2 -m 16 -p 4 -l 64 -e)
      sed -i "s|ADMIN_TOKEN=.*|ADMIN_TOKEN='${TOKEN}'|" /opt/vaultwarden/.env
      if [[ -f /opt/vaultwarden/data/config.json ]]; then
        sed -i "s|\"admin_token\":.*|\"admin_token\": \"${TOKEN}\"|" /opt/vaultwarden/data/config.json
      fi
      systemctl restart vaultwarden
      msg_ok "Admin token updated"
    fi
    exit
  fi
}

update_alpine() {
  CHOICE=$(msg_menu "Vaultwarden Update Options" \
    "1" "Update Vaultwarden" \
    "2" "Reset ADMIN_TOKEN")

  case $CHOICE in
  1)
    $STD apk -U upgrade
    rc-service vaultwarden restart -q
    msg_ok "Updated successfully!"
    exit
    ;;
  2)
    if [[ "${PHS_SILENT:-0}" == "1" ]]; then
      msg_warn "Reset ADMIN_TOKEN requires interactive mode, skipping."
      exit
    fi
    read -r -s -p "Setup your ADMIN_TOKEN (make it strong): " NEWTOKEN
    echo ""
    if [[ -n "$NEWTOKEN" ]]; then
      if ! command -v argon2 >/dev/null 2>&1; then apk add argon2 &>/dev/null; fi
      TOKEN=$(echo -n "${NEWTOKEN}" | argon2 "$(openssl rand -base64 32)" -e -id -k 19456 -t 2 -p 1)
      if [[ ! -f /var/lib/vaultwarden/config.json ]]; then
        sed -i "s|export ADMIN_TOKEN=.*|export ADMIN_TOKEN='${TOKEN}'|" /etc/conf.d/vaultwarden
      else
        sed -i "s|\"admin_token\": .*|\"admin_token\": \"${TOKEN}\",|" /var/lib/vaultwarden/config.json
      fi
      rc-service vaultwarden restart -q
      msg_ok "Admin token updated"
    fi
    exit
    ;;
  esac
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  run_os_update
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}https://${IP}:8000${CL}"
