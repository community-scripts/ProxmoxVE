#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.olivetin.app/ | Github: https://github.com/OliveTin/OliveTin

APP="OliveTin"
APP_TYPE="addon"

if ! command -v curl &>/dev/null; then
  printf "\r\e[2K%b" '\033[93m Setup Source \033[m' >&2
  if [[ -f /etc/alpine-release ]]; then
    apk update >/dev/null 2>&1
    apk add --no-cache curl >/dev/null 2>&1
  else
    apt-get update >/dev/null 2>&1
    apt-get install -y curl >/dev/null 2>&1
  fi
fi
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "olivetin" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions
require_debian_like

header_info
ensure_usr_local_bin_persist
get_lxc_ip
IP="$LOCAL_IP"

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling ${APP}"
  systemctl disable --now OliveTin &>/dev/null || true
  $STD apt remove -y olivetin
  rm -f "$HOME/.olivetin"
  msg_ok "${APP} has been uninstalled"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  if check_for_gh_release "olivetin" "OliveTin/OliveTin"; then
    msg_info "Updating ${APP}"
    fetch_and_deploy_gh_release "olivetin" "OliveTin/OliveTin" "binary"
    systemctl restart OliveTin
    msg_ok "Updated successfully!"
    exit
  fi
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  msg_info "Installing ${APP}"
  fetch_and_deploy_gh_release "olivetin" "OliveTin/OliveTin" "binary"
  systemctl enable --now OliveTin &>/dev/null
  msg_ok "Installed ${APP}"

  msg_info "Creating update script"
  ensure_usr_local_bin_persist
  cat <<'EOF' >/usr/local/bin/update_olivetin
#!/usr/bin/env bash
# OliveTin Update Script
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/olivetin.sh)"
EOF
  chmod +x /usr/local/bin/update_olivetin
  msg_ok "Created update script (/usr/local/bin/update_olivetin)"

  msg_ok "Completed successfully!\n"
  echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:1337${CL} \n"
}

# ==============================================================================
# MAIN
# ==============================================================================

# Handle type=update (called from update script)
if [[ "${type:-}" == "update" ]]; then
  if command -v olivetin &>/dev/null; then
    update
  else
    msg_error "${APP} is not installed. Nothing to update."
    exit 233
  fi
  exit 0
fi

if [[ -d "$HOME" && -f "$HOME/.olivetin" ]] || command -v olivetin &>/dev/null; then
  msg_warn "${APP} is already installed."
  echo -n "${TAB}Uninstall ${APP}? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    uninstall
    exit 0
  fi

  echo -n "${TAB}Update ${APP}? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    update
    exit 0
  fi

  msg_warn "No action selected. Exiting."
  exit 0
fi

while true; do
  echo -n "${TAB}This will Install ${APP}. Proceed (y/n)? "
  read -r yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) exit ;;
  *) echo "Please answer yes or no." ;;
  esac
done
unset _HEADER_SHOWN
header_info

install
