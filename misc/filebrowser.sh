#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tteck (tteckster) | Co-Author: MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
    clear
    cat <<"EOF"
    _______ __     ____
   / ____(_) /__  / __ )_________ _      __________  _____
  / /_  / / / _ \/ __  / ___/ __ \ | /| / / ___/ _ \/ ___/
 / __/ / / /  __/ /_/ / /  / /_/ / |/ |/ (__  )  __/ /
/_/   /_/_/\___/_____/_/   \____/|__/|__/____/\___/_/
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

APP="FileBrowser"
INSTALL_PATH="/usr/local/bin/filebrowser"
DB_PATH="/usr/local/community-scripts/filebrowser.db"
DEFAULT_PORT=8080

# Get first non-loopback IP & Detect primary network interface dynamically
IFACE=$(ip -4 route | awk '/default/ {print $5; exit}')
IP=$(ip -4 addr show "$IFACE" | awk '/inet / {print $2}' | cut -d/ -f1 | head -n 1)

[[ -z "$IP" ]] && IP=$(hostname -I | awk '{print $1}')
[[ -z "$IP" ]] && IP="127.0.0.1"

# Detect OS
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

function msg_info() {
    local msg="$1"
    echo -e "${INFO} ${YW}${msg}...${CL}"
}

function msg_ok() {
    local msg="$1"
    echo -e "${CM} ${GN}${msg}${CL}"
}

function msg_error() {
    local msg="$1"
    echo -e "${CROSS} ${RD}${msg}${CL}"
}

if [ -f "$INSTALL_PATH" ]; then
    echo -e "${YW}⚠️ ${APP} is already installed.${CL}"
    read -r -p "Would you like to uninstall ${APP}? (y/N): " uninstall_prompt
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
        rm -f "$INSTALL_PATH" "$DB_PATH"
        msg_ok "${APP} has been uninstalled."
        exit 0
    fi

    read -r -p "Would you like to update ${APP}? (y/N): " update_prompt
    if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
        msg_info "Updating ${APP}"
        curl -fsSL "https://github.com/filebrowser/filebrowser/releases/latest/download/linux-amd64-filebrowser.tar.gz" | tar -xzv -C /usr/local/bin &>/dev/null
        chmod +x "$INSTALL_PATH"
        msg_ok "Updated ${APP}"
        exit 0
    else
        echo -e "${YW}⚠️ Update skipped. Exiting.${CL}"
        exit 0
    fi
fi

echo -e "${YW}⚠️ ${APP} is not installed.${CL}"
read -r -p "Enter port number (Default: ${DEFAULT_PORT}): " PORT
PORT=${PORT:-$DEFAULT_PORT}

read -r -p "Would you like to install ${APP}? (y/n): " install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
    msg_info "Installing ${APP} on ${OS}"
    $PKG_MANAGER wget tar curl &>/dev/null
    curl -fsSL "https://github.com/filebrowser/filebrowser/releases/latest/download/linux-amd64-filebrowser.tar.gz" | tar -xzv -C /usr/local/bin &>/dev/null
    chmod +x "$INSTALL_PATH"
    msg_ok "Installed ${APP}"

    msg_info "Creating FileBrowser directory"
    mkdir -p /usr/local/community-scripts
    chown root:root /usr/local/community-scripts
    chmod 755 /usr/local/community-scripts
    touch "$DB_PATH"
    chown root:root "$DB_PATH"
    chmod 644 "$DB_PATH"
    msg_ok "Directory created successfully"

    read -r -p "Would you like to use No Authentication? (y/N): " auth_prompt
    if [[ "${auth_prompt,,}" =~ ^(y|yes)$ ]]; then
        msg_info "Configuring No Authentication"
        cd /usr/local/community-scripts
        filebrowser config init -a '0.0.0.0' -p "$PORT" -d "$DB_PATH" &>/dev/null
        filebrowser config set -a '0.0.0.0' -p "$PORT" -d "$DB_PATH" &>/dev/null
        filebrowser config init --auth.method=noauth &>/dev/null
        filebrowser config set --auth.method=noauth &>/dev/null
        filebrowser users add ID 1 --perm.admin &>/dev/null
        msg_ok "No Authentication configured"
    else
        msg_info "Setting up default authentication"
        cd /usr/local/community-scripts
        filebrowser config init -a '0.0.0.0' -p "$PORT" -d "$DB_PATH" &>/dev/null
        filebrowser config set -a '0.0.0.0' -p "$PORT" -d "$DB_PATH" &>/dev/null
        filebrowser users add admin helper-scripts.com --perm.admin --database "$DB_PATH" &>/dev/null
        msg_ok "Default authentication configured (admin:helper-scripts.com)"
    fi

    msg_info "Creating service"
    if [[ "$OS" == "Debian" ]]; then
        cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=Filebrowser
After=network-online.target

[Service]
User=root
WorkingDirectory=/usr/local/community-scripts
ExecStartPre=/bin/touch /usr/local/community-scripts/filebrowser.db
ExecStartPre=/usr/local/bin/filebrowser config set -a "0.0.0.0" -p ${PORT} -d /usr/local/community-scripts/filebrowser.db
ExecStart=/usr/local/bin/filebrowser -r / -d /usr/local/community-scripts/filebrowser.db -p ${PORT}
Restart=always

[Install]
WantedBy=multi-user.target
EOF
        systemctl enable -q --now filebrowser
    else
        cat <<EOF >"$SERVICE_PATH"
#!/sbin/openrc-run

command="/usr/local/bin/filebrowser"
command_args="-r / -d $DB_PATH -p $PORT"
command_background=true
pidfile="/var/run/filebrowser.pid"
directory="/usr/local/community-scripts"

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
else
    echo -e "${YW}⚠️ Installation skipped. Exiting.${CL}"
    exit 0
fi
