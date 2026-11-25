#!/usr/bin/env bash

# community-scripts ORG | VueTorrent Addon Installer
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/VueTorrent/VueTorrent

if command -v curl >/dev/null 2>&1; then
  source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/core.func")
  load_functions
elif command -v wget >/dev/null 2>&1; then
  source <(wget -qO- "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/core.func")
  load_functions
fi
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/lib/tools.func")
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/error_handler.func")

color
catch_errors

APP="VueTorrent"
APP_TYPE="addon"
QBT_CONF="/root/.config/qBittorrent/qBittorrent.conf"

header_info "$APP"
require_debian_like
get_lxc_ip

if [[ ! -f /etc/systemd/system/qbittorrent-nox.service || ! -f "$QBT_CONF" ]]; then
  msg_error "qBittorrent is not installed. Install the qBittorrent LXC first, then run the VueTorrent addon inside it."
  exit 1
fi

QBT_PORT=$(sed -nE '/^(WebUI\\)?Port=/{s/^[^=]*=//p;q}' "$QBT_CONF")

# qBittorrent 5.3 moved the WebUI keys from [Preferences] (WebUI\Key) to their own [WebUI] section
function qbt_webui_set() {
  local section="Preferences" key="WebUI\\$1" tmp
  if grep -q '^\[WebUI\]' "$QBT_CONF"; then
    section="WebUI"
    key="$1"
  fi
  tmp=$(mktemp)
  SECTION="[${section}]" KEY="${key}=" LINE="${key}=$2" awk '
    /^\[/ { in_section = ($0 == ENVIRON["SECTION"]) }
    in_section && index($0, ENVIRON["KEY"]) == 1 { next }
    { print }
    in_section && $0 == ENVIRON["SECTION"] && !done { print ENVIRON["LINE"]; done = 1 }
    END { if (!done) printf "\n%s\n%s\n", ENVIRON["SECTION"], ENVIRON["LINE"] }
  ' "$QBT_CONF" >"$tmp"
  cat "$tmp" >"$QBT_CONF"
  rm -f "$tmp"
}

function install_vuetorrent() {
  fetch_and_deploy_gh_release "vuetorrent" "VueTorrent/VueTorrent" "prebuild" "latest" "/opt/vuetorrent" "vuetorrent.zip"

  # qBittorrent writes its config back on shutdown, so it has to be stopped before editing
  msg_info "Enabling VueTorrent in qBittorrent"
  systemctl stop qbittorrent-nox
  qbt_webui_set AlternativeUIEnabled true
  qbt_webui_set RootFolder /opt/vuetorrent
  systemctl start qbittorrent-nox
  msg_ok "Enabled VueTorrent in qBittorrent"

  echo ""
  msg_ok "VueTorrent is reachable at: ${BL}http://${LOCAL_IP}:${QBT_PORT:-8080}${CL}"
  echo -e "${INFO}${YW} Log in with your qBittorrent WebUI credentials${CL}"
}

function update_vuetorrent() {
  if check_for_gh_release "vuetorrent" "VueTorrent/VueTorrent"; then
    # qBittorrent turns the alternative UI off for good if index.html is missing on a request, so swap instead of wiping in place
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "vuetorrent" "VueTorrent/VueTorrent" "prebuild" "latest" "/opt/vuetorrent.new" "vuetorrent.zip"
    rm -rf /opt/vuetorrent.old
    mv /opt/vuetorrent /opt/vuetorrent.old
    mv /opt/vuetorrent.new /opt/vuetorrent
    rm -rf /opt/vuetorrent.old
    msg_ok "Updated VueTorrent"
  fi
}

function uninstall_vuetorrent() {
  msg_info "Uninstalling VueTorrent"
  systemctl stop qbittorrent-nox
  qbt_webui_set AlternativeUIEnabled false
  qbt_webui_set RootFolder ""
  rm -rf /opt/vuetorrent "$HOME/.vuetorrent"
  systemctl start qbittorrent-nox
  msg_ok "Uninstalled VueTorrent, qBittorrent is back on its built-in WebUI"
}

if [[ -d /opt/vuetorrent ]]; then
  if [[ "${type:-}" == "update" ]]; then
    update_vuetorrent
    exit 0
  fi
  read -r -p "${TAB}Update (1), Uninstall (2), Cancel (3)? [1/2/3]: " action || action=""
  action="${action//[[:space:]]/}"
  case "$action" in
  1) update_vuetorrent ;;
  2) uninstall_vuetorrent ;;
  3) msg_warn "No changes made to VueTorrent" ;;
  *) msg_error "Invalid input - no changes made to VueTorrent" ;;
  esac
else
  read -r -p "${TAB}Install VueTorrent? (y/n): " answer || answer=""
  answer="${answer//[[:space:]]/}"
  if [[ "${answer,,}" =~ ^(y|yes)$ ]]; then
    install_vuetorrent
  else
    msg_warn "VueTorrent installation skipped"
  fi
fi
