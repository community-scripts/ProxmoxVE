#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dani-garcia/vaultwarden

APP="Vaultwarden"
var_tags="${var_tags:-password-manager}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-20}"
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
    # Version cache written by fetch_and_deploy_gh_release (see misc/tools.func).
    VW_CACHE="$HOME/.vaultwarden"

    # Resolve the installed binary location (layout differs between installs).
    if [[ -x /usr/bin/vaultwarden ]]; then
      VW_BIN="/usr/bin/vaultwarden"
    elif [[ -x /opt/vaultwarden/bin/vaultwarden ]]; then
      VW_BIN="/opt/vaultwarden/bin/vaultwarden"
    else
      VW_BIN=""
    fi

    # Returns the installed binary's reported version (x.y.z), empty on failure.
    vw_installed_version() {
      [[ -n "$1" && -x "$1" ]] || return 0
      "$1" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1
    }

    # Abort an in-flight update: invalidate the (possibly stale) version cache so
    # the next run retries, clean the build dir, bring the previously-running
    # service back up, and exit non-zero.
    vw_abort_update() {
      msg_error "$1"
      rm -f "$VW_CACHE"
      cd ~ && rm -rf /tmp/vaultwarden-src
      msg_info "Starting Service"
      systemctl start vaultwarden
      msg_ok "Started Service"
      exit 1
    }

    NEEDS_UPDATE=0
    if check_for_gh_release "vaultwarden" "dani-garcia/vaultwarden"; then
      NEEDS_UPDATE=1
    else
      # Cache repair guard. check_for_gh_release reports "up to date" purely from
      # the cached version in /root/.vaultwarden, which fetch_and_deploy_gh_release
      # writes when it extracts the source tarball - BEFORE the cargo build that
      # actually produces the binary. If a previous compile failed mid-flight, the
      # cache can claim the new version while the old binary is still installed.
      # Cross-check the cache against the running binary and force an update on a
      # mismatch instead of silently skipping it.
      INSTALLED_VER="$(vw_installed_version "$VW_BIN")"
      CACHED_VER=""
      [[ -f "$VW_CACHE" ]] && CACHED_VER="$(<"$VW_CACHE")"
      CACHED_VER="${CACHED_VER#v}"

      if [[ -n "$CACHED_VER" && -n "$INSTALLED_VER" && "$CACHED_VER" != "$INSTALLED_VER" ]]; then
        msg_warn "Version cache desync: cache reports ${CACHED_VER} but installed binary is ${INSTALLED_VER}"
        msg_warn "A previous compile likely failed after the cache was written - forcing update"
        rm -f "$VW_CACHE"
        NEEDS_UPDATE=1
      else
        msg_ok "VaultWarden is already up-to-date"
      fi
    fi

    if [[ "$NEEDS_UPDATE" == "1" ]]; then
      msg_info "Stopping Service"
      systemctl stop vaultwarden
      msg_ok "Stopped Service"

      fetch_and_deploy_gh_release "vaultwarden" "dani-garcia/vaultwarden" "tarball" "latest" "/tmp/vaultwarden-src"

      msg_info "Updating VaultWarden to $VAULT (Patience)"
      cd /tmp/vaultwarden-src
      VW_VERSION="$VAULT"
      export VW_VERSION
      $STD cargo build --features "sqlite,mysql,postgresql" --release

      # Verify the freshly built artifact BEFORE replacing the running binary, so
      # an interrupted or silently-failed compile cannot leave a broken install.
      BUILT_BIN="target/release/vaultwarden"
      [[ -x "$BUILT_BIN" ]] || vw_abort_update "Build artifact missing or not executable: ${BUILT_BIN}"
      BUILT_VER="$(vw_installed_version "$BUILT_BIN")"
      [[ -n "$BUILT_VER" && "$BUILT_VER" == "$VAULT" ]] ||
        vw_abort_update "Built binary version mismatch: expected ${VAULT}, got ${BUILT_VER:-unknown}"

      # Preserve the existing install layout when copying.
      if [[ -f /usr/bin/vaultwarden ]]; then
        INSTALL_TARGET="/usr/bin/vaultwarden"
      else
        INSTALL_TARGET="/opt/vaultwarden/bin/vaultwarden"
      fi
      cp "$BUILT_BIN" "$INSTALL_TARGET"

      # Re-verify the installed copy before restarting the service.
      [[ -x "$INSTALL_TARGET" ]] || vw_abort_update "Installed binary is not executable: ${INSTALL_TARGET}"
      INSTALLED_VER="$(vw_installed_version "$INSTALL_TARGET")"
      [[ "$INSTALLED_VER" == "$VAULT" ]] ||
        vw_abort_update "Installed binary version mismatch: expected ${VAULT}, got ${INSTALLED_VER:-unknown}"

      cd ~ && rm -rf /tmp/vaultwarden-src
      msg_ok "Updated VaultWarden to ${VAULT}"

      msg_info "Starting Service"
      systemctl start vaultwarden
      msg_ok "Started Service"
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

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}https://${IP}:8000${CL}"
