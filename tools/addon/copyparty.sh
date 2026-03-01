#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/9001/copyparty

if ! command -v curl &>/dev/null; then
  printf "\r\e[2K%b" '\033[93m Setup Source \033[m' >&2
  apt-get update >/dev/null 2>&1
  apt-get install -y curl >/dev/null 2>&1
fi
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR
load_functions
init_tool_telemetry "" "addon"

# ==============================================================================
# CONFIGURATION
# ==============================================================================
VERBOSE=${var_verbose:-no}
APP="CopyParty"
APP_TYPE="addon"
BIN_PATH="/usr/local/bin/copyparty-sfx.py"
CONF_PATH="/etc/copyparty.conf"
LOG_PATH="/var/log/copyparty"
DATA_PATH="/var/lib/copyparty"
SVC_USER="copyparty"
SVC_GROUP="copyparty"
SRC_URL="https://github.com/9001/copyparty/releases/latest/download/copyparty-sfx.py"
DEFAULT_PORT=3923

# ==============================================================================
# OS DETECTION
# ==============================================================================
if [[ -f "/etc/alpine-release" ]]; then
  OS="Alpine"
  PKG_MANAGER="apk add --no-cache"
  SERVICE_PATH="/etc/init.d/copyparty"
elif grep -qE 'ID=debian|ID=ubuntu' /etc/os-release; then
  OS="Debian"
  PKG_MANAGER="apt-get install -y"
  SERVICE_PATH="/etc/systemd/system/copyparty.service"
else
  msg_error "Unsupported OS detected. Exiting."
  exit 1
fi

# ==============================================================================
# HEADER
# ==============================================================================
function header_info() {
  clear
  cat <<"EOF"
   ______                  ____             __
  / ____/___  ____  __  __/ __ \____ ______/ /___  __
 / /   / __ \/ __ \/ / / / /_/ / __ `/ ___/ __/ / / /
/ /___/ /_/ / /_/ / /_/ / ____/ /_/ / /  / /_/ /_/ /
\____/\____/ .___/\__, /_/    \__,_/_/   \__/\__, /
          /_/    /____/                     /____/
EOF
}

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================
function setup_user_and_dirs() {
  msg_info "Creating $SVC_USER user and directories"
  if ! id "$SVC_USER" &>/dev/null; then
    if [[ "$OS" == "Debian" ]]; then
      useradd -r -s /sbin/nologin -d "$DATA_PATH" "$SVC_USER"
    else
      addgroup -S "$SVC_GROUP" 2>/dev/null || true
      adduser -S -D -H -G "$SVC_GROUP" -h "$DATA_PATH" -s /sbin/nologin "$SVC_USER" 2>/dev/null || true
    fi
  fi
  mkdir -p "$DATA_PATH" "$LOG_PATH"
  chown -R "$SVC_USER:$SVC_GROUP" "$DATA_PATH" "$LOG_PATH"
  chmod 755 "$DATA_PATH" "$LOG_PATH"
  msg_ok "User/Group/Dirs ready"
}

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling ${APP}"
  if [[ "$OS" == "Alpine" ]]; then
    rc-service copyparty stop &>/dev/null || true
    rc-update del copyparty &>/dev/null || true
    rm -f "$SERVICE_PATH"
  else
    systemctl disable --now copyparty.service &>/dev/null || true
    rm -f "$SERVICE_PATH"
  fi
  rm -f "$BIN_PATH" "$CONF_PATH"
  rm -rf "$DATA_PATH" "$LOG_PATH"
  userdel "$SVC_USER" 2>/dev/null || true
  groupdel "$SVC_GROUP" 2>/dev/null || true
  rm -f "/usr/local/bin/update_copyparty"
  rm -f "$HOME/.copyparty"
  msg_ok "${APP} has been uninstalled"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  if check_for_gh_release "copyparty-sfx.py" "9001/copyparty"; then
    msg_info "Stopping service"
    if [[ "$OS" == "Alpine" ]]; then
      rc-service copyparty stop &>/dev/null || true
    else
      systemctl stop copyparty.service &>/dev/null || true
    fi
    msg_ok "Stopped service"

    msg_info "Updating ${APP}"
    curl -fsSL "$SRC_URL" -o "$BIN_PATH"
    chmod +x "$BIN_PATH"
    chown "$SVC_USER:$SVC_GROUP" "$BIN_PATH"
    msg_ok "Updated ${APP}"

    msg_info "Starting service"
    if [[ "$OS" == "Alpine" ]]; then
      rc-service copyparty start
    else
      systemctl start copyparty.service
    fi
    msg_ok "Started service"
    msg_ok "Updated successfully!"
    exit
  fi
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  local port data_path enable_auth admin_user admin_pass

  echo ""
  read -rp "${TAB}Enter port for ${APP} [${DEFAULT_PORT}]: " port
  port=${port:-$DEFAULT_PORT}

  read -rp "${TAB}Set data directory [${DATA_PATH}]: " data_path
  data_path=${data_path:-$DATA_PATH}

  echo -n "${TAB}Enable authentication? (Y/n): "
  read -r enable_auth
  if [[ "${enable_auth,,}" =~ ^(n|no)$ ]]; then
    admin_user=""
    admin_pass=""
    msg_ok "Configured without authentication"
  else
    read -rp "${TAB}Set admin username [admin]: " admin_user
    admin_user=${admin_user:-admin}
    read -rsp "${TAB}Set admin password [helper-scripts.com]: " admin_pass
    echo ""
    admin_pass=${admin_pass:-helper-scripts.com}
    msg_ok "Configured with admin user: ${admin_user}"
  fi

  msg_info "Installing dependencies"
  if [[ "$OS" == "Debian" ]]; then
    $STD $PKG_MANAGER python3 python3-pil ffmpeg curl
  else
    $STD $PKG_MANAGER python3 py3-pillow ffmpeg curl
  fi
  msg_ok "Dependencies installed (with thumbnail support)"

  setup_user_and_dirs

  # Use data_path if provided
  if [[ "$data_path" != "$DATA_PATH" ]]; then
    DATA_PATH="$data_path"
    mkdir -p "$DATA_PATH"
    chown "$SVC_USER:$SVC_GROUP" "$DATA_PATH"
  fi

  msg_info "Downloading ${APP}"
  curl -fsSL "$SRC_URL" -o "$BIN_PATH"
  chmod +x "$BIN_PATH"
  chown "$SVC_USER:$SVC_GROUP" "$BIN_PATH"
  msg_ok "Downloaded to ${BIN_PATH}"

  msg_info "Creating configuration"
  cat <<EOF >"$CONF_PATH"
[global]
  p: ${port}
  ansi
  e2dsa
  e2ts
  theme: 2
  grid
  no-robots
  force-js
  lo: ${LOG_PATH}/cpp-%Y-%m%d.txt.xz

EOF

  if [[ -n "$admin_user" && -n "$admin_pass" ]]; then
    cat <<EOF >>"$CONF_PATH"
[accounts]
  ${admin_user}: ${admin_pass}

EOF
  fi

  cat <<EOF >>"$CONF_PATH"
[/]
  ${DATA_PATH}
  accs:
EOF

  if [[ -n "$admin_user" ]]; then
    cat <<EOF >>"$CONF_PATH"
    rw: *
    rwmda: ${admin_user}
EOF
  else
    cat <<EOF >>"$CONF_PATH"
    rw: *
EOF
  fi

  chmod 640 "$CONF_PATH"
  chown "$SVC_USER:$SVC_GROUP" "$CONF_PATH"
  msg_ok "Created configuration"

  msg_info "Creating service"
  if [[ "$OS" == "Alpine" ]]; then
    cat <<'SERVICEEOF' >"$SERVICE_PATH"
#!/sbin/openrc-run

name="copyparty"
description="CopyParty file server"
command="$(command -v python3)"
command_args="/usr/local/bin/copyparty-sfx.py -c /etc/copyparty.conf"
command_background=true
directory="/var/lib/copyparty"
pidfile="/run/copyparty.pid"
output_log="/var/log/copyparty/copyparty.log"
error_log="/var/log/copyparty/copyparty.err"

depend() {
    need net
}
SERVICEEOF
    chmod +x "$SERVICE_PATH"
    $STD rc-update add copyparty default
    $STD rc-service copyparty start
  else
    cat <<SERVICEEOF >"$SERVICE_PATH"
[Unit]
Description=CopyParty file server
After=network.target

[Service]
User=${SVC_USER}
Group=${SVC_GROUP}
WorkingDirectory=${DATA_PATH}
ExecStart=/usr/bin/python3 ${BIN_PATH} -c ${CONF_PATH}
Restart=always
StandardOutput=append:${LOG_PATH}/copyparty.log
StandardError=append:${LOG_PATH}/copyparty.err

[Install]
WantedBy=multi-user.target
SERVICEEOF
    systemctl daemon-reload
    systemctl enable --now copyparty.service &>/dev/null
  fi
  msg_ok "Created and started service"

  # Create update script
  msg_info "Creating update script"
  ensure_usr_local_bin_persist
  cat <<'UPDATEEOF' >/usr/local/bin/update_copyparty
#!/usr/bin/env bash
# CopyParty Update Script
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/copyparty.sh)"
UPDATEEOF
  chmod +x /usr/local/bin/update_copyparty
  msg_ok "Created update script (/usr/local/bin/update_copyparty)"

  echo ""
  msg_ok "${APP} installed successfully"
  msg_ok "Web UI: ${BL}http://${LOCAL_IP}:${port}${CL}"
  msg_ok "Storage: ${BL}${DATA_PATH}${CL}"
  msg_ok "Config: ${BL}${CONF_PATH}${CL}"
  if [[ -n "$admin_user" ]]; then
    echo ""
    msg_ok "Login: ${GN}${admin_user}${CL} / ${GN}${admin_pass}${CL}"
  fi
}

# ==============================================================================
# MAIN
# ==============================================================================
header_info
ensure_usr_local_bin_persist
get_lxc_ip

# Handle type=update (called from update script)
if [[ "${type:-}" == "update" ]]; then
  if [[ -f "$BIN_PATH" ]]; then
    update
  else
    msg_error "${APP} is not installed. Nothing to update."
    exit 1
  fi
  exit 0
fi

# Check if already installed
if [[ -f "$BIN_PATH" ]]; then
  msg_warn "${APP} is already installed."
  echo ""

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

# Fresh installation
msg_warn "${APP} is not installed."
echo ""
echo -e "${TAB}${INFO} This will install:"
echo -e "${TAB}  - CopyParty (Python file server)"
echo -e "${TAB}  - Thumbnail support (Pillow, FFmpeg)"
echo -e "${TAB}  - Systemd/OpenRC service"
echo ""

echo -n "${TAB}Install ${APP}? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "Installation cancelled. Exiting."
  exit 0
fi
