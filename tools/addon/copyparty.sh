#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/9001/copyparty

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

YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
RD=$(echo "\033[01;31m")
BL=$(echo "\033[36m")
CL=$(echo "\033[m")
CM="${GN}✔️${CL}"
CROSS="${RD}✖️${CL}"
INFO="${BL}ℹ️${CL}"

APP="CopyParty"
BIN_PATH="/usr/local/bin/copyparty-sfx.py"
CONF_PATH="/etc/copyparty.conf"
LOG_PATH="/var/log/copyparty"
DATA_PATH="/var/lib/copyparty"
SERVICE_PATH_DEB="/etc/systemd/system/copyparty.service"
SERVICE_PATH_ALP="/etc/init.d/copyparty"
SVC_USER="copyparty"
SVC_GROUP="copyparty"
SRC_URL="https://github.com/9001/copyparty/releases/latest/download/copyparty-sfx.py"
DEFAULT_PORT=3923

if [[ -f "/etc/alpine-release" ]]; then
  OS="Alpine"
  PKG_MANAGER="apk add --no-cache"
  SERVICE_PATH="$SERVICE_PATH_ALP"
elif [[ -f "/etc/debian_version" ]]; then
  OS="Debian"
  PKG_MANAGER="apt-get install -y"
  SERVICE_PATH="$SERVICE_PATH_DEB"
else
  echo -e "${CROSS} Unsupported OS detected. Exiting."
  exit 1
fi

header_info

function msg_info() { echo -e "${INFO} ${YW}$1...${CL}"; }
function msg_ok() { echo -e "${CM} ${GN}$1${CL}"; }
function msg_error() { echo -e "${CROSS} ${RD}$1${CL}"; }

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

function uninstall_copyparty() {
  msg_info "Uninstalling $APP"
  if [[ "$OS" == "Debian" ]]; then
    systemctl disable --now copyparty &>/dev/null
    rm -f "$SERVICE_PATH_DEB"
  else
    rc-service copyparty stop &>/dev/null
    rc-update del copyparty &>/dev/null
    rm -f "$SERVICE_PATH_ALP"
  fi
  rm -f "$BIN_PATH" "$CONF_PATH"
  msg_ok "$APP has been uninstalled."
  exit 0
}

function update_copyparty() {
  msg_info "Updating $APP"
  curl -fsSL "$SRC_URL" -o "$BIN_PATH"
  chmod +x "$BIN_PATH"
  msg_ok "Updated $APP"
  exit 0
}

if [[ -f "$BIN_PATH" ]]; then
  echo -e "${YW}⚠️ $APP is already installed.${CL}"
  echo -n "Uninstall $APP? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    uninstall_copyparty
  fi

  echo -n "Update $APP? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    update_copyparty
  else
    echo -e "${YW}⚠️ Update skipped. Exiting.${CL}"
    exit 0
  fi
fi

msg_info "Installing dependencies"
if [[ "$OS" == "Debian" ]]; then
  $PKG_MANAGER python3 curl &>/dev/null
else
  $PKG_MANAGER python3 curl &>/dev/null
fi
msg_ok "Dependencies installed"

setup_user_and_dirs

msg_info "Downloading $APP"
curl -fsSL "$SRC_URL" -o "$BIN_PATH"
chmod +x "$BIN_PATH"
chown "$SVC_USER:$SVC_GROUP" "$BIN_PATH"
msg_ok "Downloaded to $BIN_PATH"

echo -n "Enter port for $APP (default: $DEFAULT_PORT): "
read -r PORT
PORT=${PORT:-$DEFAULT_PORT}

echo -n "Set data directory (default: $DATA_PATH): "
read -r USER_DATA_PATH
USER_DATA_PATH=${USER_DATA_PATH:-$DATA_PATH}
mkdir -p "$USER_DATA_PATH"
chown "$SVC_USER:$SVC_GROUP" "$USER_DATA_PATH"

echo -n "Enable authentication? (Y/n): "
read -r auth_enable
if [[ "${auth_enable,,}" =~ ^(n|no)$ ]]; then
  AUTH_LINE=""
  msg_ok "Configured without authentication"
else
  echo -n "Set admin username [default: admin]: "
  read -r ADMIN_USER
  ADMIN_USER=${ADMIN_USER:-admin}
  echo -n "Set admin password [default: helper-scripts.com]: "
  read -rs ADMIN_PASS
  ADMIN_PASS=${ADMIN_PASS:-helper-scripts.com}
  echo
  AUTH_LINE="auth vhost=/:$ADMIN_USER:$ADMIN_PASS:admin,,"
  msg_ok "Configured with admin user: $ADMIN_USER"
fi

msg_info "Writing config to $CONF_PATH"
msg_info "Writing config to $CONF_PATH"
{
  echo "[global]"
  echo "  p: $PORT"
  echo "  ansi"
  echo "  e2dsa"
  echo "  e2ts"
  echo "  theme: 2"
  echo "  grid"
  echo
  if [[ -n "$ADMIN_USER" && -n "$ADMIN_PASS" ]]; then
    echo "[accounts]"
    echo "  $ADMIN_USER: $ADMIN_PASS"
    echo
  fi
  echo "[/]"
  echo "  $USER_DATA_PATH"
  echo "  accs:"
  if [[ -n "$ADMIN_USER" ]]; then
    echo "    rw: *"
    echo "    rwmda: $ADMIN_USER"
  else
    echo "    rw: *"
  fi
} >"$CONF_PATH"

chmod 640 "$CONF_PATH"
chown "$SVC_USER:$SVC_GROUP" "$CONF_PATH"
msg_ok "Config written"

msg_info "Creating service"
if [[ "$OS" == "Debian" ]]; then
  cat <<EOF >"$SERVICE_PATH_DEB"
[Unit]
Description=Copyparty file server
After=network.target

[Service]
User=$SVC_USER
Group=$SVC_GROUP
WorkingDirectory=$DATA_PATH
ExecStart=/usr/bin/python3 /usr/local/bin/copyparty-sfx.py -c /etc/copyparty.conf
Restart=always
StandardOutput=append:/var/log/copyparty/copyparty.log
StandardError=append:/var/log/copyparty/copyparty.err

[Install]
WantedBy=multi-user.target
EOF

  systemctl enable -q --now copyparty

elif [[ "$OS" == "Alpine" ]]; then
  cat <<'EOF' >"$SERVICE_PATH_ALP"
#!/sbin/openrc-run

name="copyparty"
description="Copyparty file server"

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
EOF

  chmod +x "$SERVICE_PATH_ALP"
  rc-update add copyparty default >/dev/null 2>&1
  rc-service copyparty restart >/dev/null 2>&1
fi
msg_ok "Service created and started"

IFACE=$(ip -4 route | awk '/default/ {print $5; exit}')
IP=$(ip -4 addr show "$IFACE" | awk '/inet / {print $2}' | cut -d/ -f1 | head -n 1)
[[ -z "$IP" ]] && IP=$(hostname -I | awk '{print $1}')
[[ -z "$IP" ]] && IP="127.0.0.1"

echo -e "${CM} ${GN}$APP is running at: ${BL}http://$IP:$PORT${CL}"
echo -e "${INFO} Storage directory: ${YW}$USER_DATA_PATH${CL}"
if [[ -n "$AUTH_LINE" ]]; then
  echo -e "${INFO} Login: ${GN}${ADMIN_USER}${CL} / ${GN}${ADMIN_PASS}${CL}"
fi
