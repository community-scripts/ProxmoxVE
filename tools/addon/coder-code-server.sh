#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://coder.com/ | Github: https://github.com/coder/code-server

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
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "coder-code-server" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

APP="Coder Code Server"
APP_TYPE="addon"

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

header_info
ensure_usr_local_bin_persist
get_lxc_ip
IP="$LOCAL_IP"

confirm_not_pve_host
require_debian_like

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling ${APP}"
  systemctl disable --now code-server@"$USER" &>/dev/null || true
  $STD apt remove -y code-server
  rm -f "$HOME/.coder-code-server"
  msg_ok "${APP} has been uninstalled"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  if check_for_gh_release "coder-code-server" "coder/code-server"; then
    msg_info "Updating ${APP}"
    fetch_and_deploy_gh_release "coder-code-server" "coder/code-server" "binary" "latest" "/opt/coder-code-server" "code-server_*_$(arch_resolve).deb"
    systemctl restart code-server@"$USER"
    msg_ok "Updated successfully!"
    exit
  fi
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  msg_info "Installing Dependencies"
  $STD apt update
  $STD apt install -y \
    curl \
    git
  msg_ok "Installed Dependencies"

  msg_info "Installing ${APP}"
  config_path="${HOME}/.config/code-server/config.yaml"
  preexisting_config=false
  if [ -f "$config_path" ]; then
    preexisting_config=true
  fi

  fetch_and_deploy_gh_release "coder-code-server" "coder/code-server" "binary" "latest" "/opt/coder-code-server" "code-server_*_$(arch_resolve).deb"
  mkdir -p "${HOME}/.config/code-server/"

  if [ "$preexisting_config" = false ]; then
    cat <<EOF >"$config_path"
bind-addr: 0.0.0.0:8680
auth: none
password: 
cert: false
EOF
  fi
  systemctl enable -q --now code-server@"$USER"
  systemctl restart code-server@"$USER"
  if ! systemctl is-active --quiet code-server@"$USER"; then
    msg_error "code-server service failed to start."
    exit 150
  fi
  msg_ok "Installed ${APP}"

  msg_info "Creating update script"
  ensure_usr_local_bin_persist
  cat <<'EOF' >/usr/local/bin/update_coder-code-server
#!/usr/bin/env bash
# Coder Code Server Update Script
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/coder-code-server.sh)"
EOF
  chmod +x /usr/local/bin/update_coder-code-server
  msg_ok "Created update script (/usr/local/bin/update_coder-code-server)"

  echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8680${CL} \n"
}

# ==============================================================================
# MAIN
# ==============================================================================

# Handle type=update (called from update script)
if [[ "${type:-}" == "update" ]]; then
  if command -v code-server &>/dev/null; then
    update
  else
    msg_error "${APP} is not installed. Nothing to update."
    exit 233
  fi
  exit 0
fi

if [[ -d "$HOME" && -f "$HOME/.coder-code-server" ]] || command -v code-server &>/dev/null; then
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

install
