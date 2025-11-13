#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info() {
  clear
  cat <<"EOF"
    _______ __     ____                                       ____                    __
   / ____(_) /__  / __ )_________ _      __________  _____   / __ \__  ______ _____  / /___  ______ ___
  / /_  / / / _ \/ __  / ___/ __ \ | /| / / ___/ _ \/ ___/  / / / / / / / __ `/ __ \/ __/ / / / __ `__ \
 / __/ / / /  __/ /_/ / /  / /_/ / |/ |/ (__  )  __/ /     / /_/ / /_/ / /_/ / / / / /_/ /_/ / / / / / /
/_/   /_/_/\___/_____/_/   \____/|__/|__/____/\___/_/      \___\_\__,_/\__,_/_/ /_/\__/\__,_/_/ /_/ /_/

EOF
}

YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
RD=$(echo "\033[01;31m")
BL=$(echo "\033[36m")
CL=$(echo "\033[m")
CM="${GN}✔️${CL}"
CROSS="${RD}✖️${CL}"
INFO="${BL}ℹ️${CL}"

APP="FileBrowser Quantum"
INSTALL_PATH="/usr/local/bin/filebrowser"
CONFIG_PATH="/usr/local/community-scripts/fq-config.yaml"
DEFAULT_PORT=8080
SRC_DIR="/"
TMP_BIN="/tmp/filebrowser.$$"

# Get primary IP
IFACE=$(ip -4 route | awk '/default/ {print $5; exit}')
IP=$(ip -4 addr show "$IFACE" | awk '/inet / {print $2}' | cut -d/ -f1 | head -n 1)
[[ -z "$IP" ]] && IP=$(hostname -I | awk '{print $1}')
[[ -z "$IP" ]] && IP="127.0.0.1"

# OS Detection
if [[ -f "/etc/alpine-release" ]]; then
  OS="Alpine"
  SERVICE_PATH="/etc/init.d/filebrowser"
  PKG_MANAGER="apk add --no-cache"
elif [[ -f "/etc/debian_version" ]]; then
  OS="Debian"
  SERVICE_PATH="/etc/systemd/system/filebrowser.service"
  PKG_MANAGER="apt-get install -y"
else
  echo -e "${CROSS} Unsupported OS detected. Exiting."
  exit 1
fi

header_info

function msg_info() { echo -e "${INFO} ${YW}$1...${CL}"; }
function msg_ok() { echo -e "${CM} ${GN}$1${CL}"; }
function msg_error() { echo -e "${CROSS} ${RD}$1${CL}"; }

# Detect legacy FileBrowser installation
LEGACY_DB="/usr/local/community-scripts/filebrowser.db"
LEGACY_BIN="/usr/local/bin/filebrowser"
LEGACY_SERVICE_DEB="/etc/systemd/system/filebrowser.service"
LEGACY_SERVICE_ALP="/etc/init.d/filebrowser"

if [[ -f "$LEGACY_DB" || -f "$LEGACY_BIN" && ! -f "$CONFIG_PATH" ]]; then
  echo -e "${YW}⚠️ Detected legacy FileBrowser installation.${CL}"
  echo -n "Uninstall legacy FileBrowser and continue with Quantum install? (y/n): "
  read -r remove_legacy
  if [[ "${remove_legacy,,}" =~ ^(y|yes)$ ]]; then
    msg_info "Uninstalling legacy FileBrowser"
    if [[ -f "$LEGACY_SERVICE_DEB" ]]; then
      systemctl disable --now filebrowser.service &>/dev/null
      rm -f "$LEGACY_SERVICE_DEB"
    elif [[ -f "$LEGACY_SERVICE_ALP" ]]; then
      rc-service filebrowser stop &>/dev/null
      rc-update del filebrowser &>/dev/null
      rm -f "$LEGACY_SERVICE_ALP"
    fi
    rm -f "$LEGACY_BIN" "$LEGACY_DB"
    msg_ok "Legacy FileBrowser removed"
  else
    echo -e "${YW}❌ Installation aborted by user.${CL}"
    exit 0
  fi
fi

# Existing installation
if [[ -f "$INSTALL_PATH" ]]; then
  echo -e "${YW}⚠️ ${APP} is already installed.${CL}"
  echo -n "Uninstall ${APP}? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    msg_info "Uninstalling ${APP}"
    if [[ "$OS" == "Debian" ]]; then
      systemctl disable --now filebrowser.service &>/dev/null
      rm -f "$SERVICE_PATH"
    else
      rc-service filebrowser stop &>/dev/null
      rc-update del filebrowser &>/dev/null
      rm -f "$SERVICE_PATH"
    fi
    rm -f "$INSTALL_PATH" "$CONFIG_PATH"
    msg_ok "${APP} has been uninstalled."
    exit 0
  fi

  echo -n "Update ${APP}? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    msg_info "Updating ${APP}"
    curl -fsSL https://github.com/gtsteffaniak/filebrowser/releases/latest/download/linux-amd64-filebrowser -o "$TMP_BIN"
    chmod +x "$TMP_BIN"
    mv -f "$TMP_BIN" /usr/local/bin/filebrowser
    msg_ok "Updated ${APP}"
    exit 0
  else
    echo -e "${YW}⚠️ Update skipped. Exiting.${CL}"
    exit 0
  fi
fi

echo -e "${YW}⚠️ ${APP} is not installed.${CL}"
echo -n "Enter port number (Default: ${DEFAULT_PORT}): "
read -r PORT
PORT=${PORT:-$DEFAULT_PORT}

echo -n "Install ${APP}? (y/n): "
read -r install_prompt
if ! [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  echo -e "${YW}⚠️ Installation skipped. Exiting.${CL}"
  exit 0
fi

msg_info "Installing ${APP} on ${OS}"
$PKG_MANAGER curl ffmpeg &>/dev/null
curl -fsSL https://github.com/gtsteffaniak/filebrowser/releases/latest/download/linux-amd64-filebrowser -o "$TMP_BIN"
chmod +x "$TMP_BIN"
mv -f "$TMP_BIN" /usr/local/bin/filebrowser
msg_ok "Installed ${APP}"

msg_info "Preparing configuration directory"
mkdir -p /usr/local/community-scripts
chown root:root /usr/local/community-scripts
chmod 755 /usr/local/community-scripts
msg_ok "Directory prepared"

echo -n "Use No Authentication? (y/N): "
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
        disableIndexing: false
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
        disableIndexing: false
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
  adminPassword: helper-scripts.com
EOF
  msg_ok "Configured with default admin (admin / helper-scripts.com)"
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
  rc-update add filebrowser default &>/dev/null
  rc-service filebrowser start &>/dev/null
fi

msg_ok "Service created successfully"
echo -e "${CM} ${GN}${APP} is reachable at: ${BL}http://$IP:$PORT${CL}"
