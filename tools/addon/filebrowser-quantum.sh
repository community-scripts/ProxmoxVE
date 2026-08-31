#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/filebrowserspace/quantum

APP="FileBrowser Quantum"
APP_TYPE="addon"
INSTALL_PATH="/usr/local/bin/filebrowser"
CONFIG_PATH="/usr/local/community-scripts/fq-config.yaml"
DEFAULT_PORT=8080
SRC_DIR="/"

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
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "filebrowser-quantum" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

header_info
get_lxc_ip
IP="$LOCAL_IP"

# Proxmox Host Warning
if [[ -d "/etc/pve" ]]; then
  msg_warn "Running this addon directly on the Proxmox host is not recommended!"
  msg_warn "Only the boot disk will be visible â€” passthrough drives will not be indexed."
  msg_warn "This causes incorrect disk usage stats and incomplete file browsing."
  msg_warn "Run this addon inside an LXC or VM instead and mount your drives there."
  echo ""
  echo -n "${TAB}Continue anyway on the Proxmox host? (y/N): "
  read -r host_confirm
  if [[ ! "${host_confirm,,}" =~ ^(y|yes)$ ]]; then
    msg_error "Aborted."
    exit 0
  fi
fi

# OS Detection
if [[ -f "/etc/alpine-release" ]]; then
  OS="Alpine"
  SERVICE_PATH="/etc/init.d/filebrowser"
  PKG_MANAGER="apk add --no-cache"
elif [[ -f "/etc/debian_version" ]]; then
  OS="Debian"
  SERVICE_PATH="/etc/systemd/system/filebrowser.service"
  PKG_MANAGER="apt install -y"
else
  msg_error "Unsupported OS detected. Exiting."
  exit 238
fi

# Detect legacy FileBrowser installation
LEGACY_DB="/usr/local/community-scripts/filebrowser.db"
LEGACY_BIN="/usr/local/bin/filebrowser"
LEGACY_SERVICE_DEB="/etc/systemd/system/filebrowser.service"
LEGACY_SERVICE_ALP="/etc/init.d/filebrowser"

if [[ -f "$LEGACY_DB" || -f "$LEGACY_BIN" && ! -f "$CONFIG_PATH" ]]; then
  msg_warn "Detected legacy FileBrowser installation."
  echo -n "${TAB}Uninstall legacy FileBrowser and continue with Quantum install? (y/n): "
  read -r remove_legacy
  if [[ "${remove_legacy,,}" =~ ^(y|yes)$ ]]; then
    msg_info "Uninstalling legacy FileBrowser"
    if [[ -f "$LEGACY_SERVICE_DEB" ]]; then
      systemctl disable --now filebrowser.service &>/dev/null || true
      rm -f "$LEGACY_SERVICE_DEB"
    elif [[ -f "$LEGACY_SERVICE_ALP" ]]; then
      rc-service filebrowser stop &>/dev/null || true
      rc-update del filebrowser &>/dev/null || true
      rm -f "$LEGACY_SERVICE_ALP"
    fi
    rm -f "$LEGACY_BIN" "$LEGACY_DB"
    msg_ok "Legacy FileBrowser removed"
  else
    msg_error "Installation aborted by user."
    exit 0
  fi
fi

# Existing installation
if [[ -f "$INSTALL_PATH" ]]; then
  msg_warn "${APP} is already installed."
  echo -n "${TAB}Uninstall ${APP}? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    msg_info "Uninstalling ${APP}"
    if [[ "$OS" == "Debian" ]]; then
      systemctl disable --now filebrowser.service &>/dev/null || true
      rm -f "$SERVICE_PATH"
    else
      rc-service filebrowser stop &>/dev/null || true
      rc-update del filebrowser &>/dev/null || true
      rm -f "$SERVICE_PATH"
    fi
    rm -f "$INSTALL_PATH" "$CONFIG_PATH" "$HOME/.filebrowser-quantum"
    msg_ok "${APP} has been uninstalled."
    exit 0
  fi

  echo -n "${TAB}Update ${APP}? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    if check_for_gh_release "filebrowser-quantum" "gtsteffaniak/filebrowser"; then
      msg_info "Updating ${APP}"
      if ! command -v curl &>/dev/null; then $STD $PKG_MANAGER curl; fi
      fetch_and_deploy_gh_release "filebrowser-quantum" "gtsteffaniak/filebrowser" "singlefile" "latest" "/usr/local/bin" "linux-$(arch_resolve)-filebrowser"
      mv -f /usr/local/bin/filebrowser-quantum "$INSTALL_PATH"
      if [[ -f "$CONFIG_PATH" ]]; then
        sed -i '/^\s*disableIndexing:/d' "$CONFIG_PATH"
      fi
      if [[ "$OS" == "Debian" ]]; then
        systemctl restart filebrowser.service
      else
        rc-service filebrowser restart
      fi
      msg_ok "Updated ${APP}"
    fi
    exit 0
  else
    msg_warn "Update skipped. Exiting."
    exit 0
  fi
fi

msg_warn "${APP} is not installed."
echo -n "${TAB}Enter port number (Default: ${DEFAULT_PORT}): "
read -r PORT
PORT=${PORT:-$DEFAULT_PORT}

echo -n "${TAB}Install ${APP}? (y/n): "
read -r install_prompt
if ! [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  msg_warn "Installation skipped. Exiting."
  exit 0
fi

msg_info "Installing ${APP} on ${OS}"
$STD $PKG_MANAGER \
  curl \
  ffmpeg
fetch_and_deploy_gh_release "filebrowser-quantum" "gtsteffaniak/filebrowser" "singlefile" "latest" "/usr/local/bin" "linux-$(arch_resolve)-filebrowser"
mv -f /usr/local/bin/filebrowser-quantum "$INSTALL_PATH"
msg_ok "Installed ${APP}"

msg_info "Preparing configuration directory"
mkdir -p /usr/local/community-scripts
chown root:root /usr/local/community-scripts
chmod 755 /usr/local/community-scripts
msg_ok "Directory prepared"

echo -n "${TAB}Use No Authentication? (y/N): "
read -r noauth_prompt

# === YAML CONFIG GENERATION ===
if [[ "${noauth_prompt,,}" =~ ^(y|yes)$ ]]; then
  cat <<EOF >"$CONFIG_PATH"
server:
  port: $PORT
  sources:
    - path: "$SRC_DIR"
      name: "RootFS"
      config:
        denyByDefault: false
        indexingIntervalMinutes: 240
        conditionals:
          rules:
            - neverWatchPath: "/proc"
            - neverWatchPath: "/sys"
            - neverWatchPath: "/dev"
            - neverWatchPath: "/run"
            - neverWatchPath: "/tmp"
            - neverWatchPath: "/lost+found"
auth:
  methods:
    noauth: true
EOF
  msg_ok "Configured with no authentication"
else
  cat <<EOF >"$CONFIG_PATH"
server:
  port: $PORT
  sources:
    - path: "$SRC_DIR"
      name: "RootFS"
      config:
        denyByDefault: false
        indexingIntervalMinutes: 240
        conditionals:
          rules:
            - neverWatchPath: "/proc"
            - neverWatchPath: "/sys"
            - neverWatchPath: "/dev"
            - neverWatchPath: "/run"
            - neverWatchPath: "/tmp"
            - neverWatchPath: "/lost+found"
auth:
  adminUsername: admin
  adminPassword: community-scripts.org
EOF
  msg_ok "Configured with default admin (admin / community-scripts.org)"
fi

msg_info "Creating service"
if [[ "$OS" == "Debian" ]]; then
  cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=FileBrowser Quantum
After=network.target

[Service]
User=root
WorkingDirectory=/usr/local/community-scripts
ExecStart=/usr/local/bin/filebrowser -c $CONFIG_PATH
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable --now filebrowser &>/dev/null
else
  cat <<EOF >"$SERVICE_PATH"
#!/sbin/openrc-run

command="/usr/local/bin/filebrowser"
command_args="-c $CONFIG_PATH"
command_background=true
directory="/usr/local/community-scripts"
pidfile="/usr/local/community-scripts/pidfile"

depend() {
    need net
}
EOF
  chmod +x "$SERVICE_PATH"
  $STD rc-update add filebrowser default
  $STD rc-service filebrowser start
fi

msg_ok "Service created successfully"
msg_ok "${APP} is reachable at: ${BL}http://${IP}:${PORT}${CL}"
