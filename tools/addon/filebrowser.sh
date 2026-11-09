#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: tteck (tteckster) | Co-Author: MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://filebrowser.org/ | Github: https://github.com/filebrowser/filebrowser

APP="FileBrowser"
APP_TYPE="addon"
INSTALL_PATH="/usr/local/bin/filebrowser"
DB_PATH="/usr/local/community-scripts/filebrowser.db"
DEFAULT_PORT=8080

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
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/core.func")
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/lib/tools.func")
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/error_handler.func")
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/api/api.func") 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "filebrowser" "addon"

# Enable error handling
set -Eeuo pipefail
catch_errors

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

header_info
get_lxc_ip
IP="$LOCAL_IP"

# Proxmox Host Warning
if [[ -d "/etc/pve" ]]; then
  msg_warn "Running this addon directly on the Proxmox host is not recommended!"
  msg_warn "Only the boot disk will be visible — passthrough drives will not be indexed."
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

# Detect OS
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

if [ -f "$INSTALL_PATH" ]; then
  msg_warn "${APP} is already installed."
  read -r -p "Would you like to uninstall ${APP}? (y/N): " uninstall_prompt
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
    rm -f "$INSTALL_PATH" "$DB_PATH" "$HOME/.filebrowser"
    msg_ok "${APP} has been uninstalled."
    exit 0
  fi

  read -r -p "Would you like to update ${APP}? (y/N): " update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    # Older installs created admin with the public password community-scripts.org
    fb_port=$(grep -oP '(?<=-p )[0-9]+' "$SERVICE_PATH" 2>/dev/null | head -n1)
    fb_db=$(grep -oP '(?<=-d )\S+' "$SERVICE_PATH" 2>/dev/null | head -n1)
    [[ -n "$fb_db" ]] || fb_db="$(grep -oP '(?<=^WorkingDirectory=)\S+' "$SERVICE_PATH" 2>/dev/null || echo /root)/filebrowser.db"
    if [[ "$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' -d '{"username":"admin","password":"community-scripts.org","recaptcha":""}' "http://127.0.0.1:${fb_port:-8080}/api/login")" == "200" ]]; then
      msg_info "Replacing the default admin password"
      ADMIN_PASS=$(random_password 20)
      if [[ "$OS" == "Debian" ]]; then systemctl stop filebrowser; else rc-service filebrowser stop &>/dev/null; fi
      $STD filebrowser users update admin --password "$ADMIN_PASS" --database "$fb_db"
      if [[ "$OS" == "Debian" ]]; then systemctl start filebrowser; else rc-service filebrowser start &>/dev/null; fi
      echo -e "FileBrowser\nUsername: admin\nPassword: ${ADMIN_PASS}" >~/filebrowser.creds
      chmod 600 ~/filebrowser.creds
      msg_ok "Replaced the default admin password (saved in ~/filebrowser.creds)"
    fi
    if check_for_gh_release "filebrowser" "filebrowser/filebrowser"; then
      msg_info "Updating ${APP}"
      fetch_and_deploy_gh_release "filebrowser" "filebrowser/filebrowser" "prebuild" "latest" "/opt/filebrowser-dist" "linux-$(arch_resolve)-filebrowser.tar.gz"
      install -m 755 /opt/filebrowser-dist/filebrowser "$INSTALL_PATH"
      rm -rf /opt/filebrowser-dist
      msg_ok "Updated ${APP}"
    fi
    exit 0
  else
    msg_warn "Update skipped. Exiting."
    exit 0
  fi
fi

msg_warn "${APP} is not installed."
read -r -p "Enter port number (Default: ${DEFAULT_PORT}): " PORT
PORT=${PORT:-$DEFAULT_PORT}

read -r -p "Would you like to install ${APP}? (y/n): " install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  msg_info "Installing ${APP} on ${OS}"
  $STD $PKG_MANAGER \
    tar \
    curl
  fetch_and_deploy_gh_release "filebrowser" "filebrowser/filebrowser" "prebuild" "latest" "/opt/filebrowser-dist" "linux-$(arch_resolve)-filebrowser.tar.gz"
  install -m 755 /opt/filebrowser-dist/filebrowser "$INSTALL_PATH"
  rm -rf /opt/filebrowser-dist
  msg_ok "Installed ${APP}"

  msg_info "Creating FileBrowser directory"
  mkdir -p /usr/local/community-scripts
  chown root:root /usr/local/community-scripts
  chmod 755 /usr/local/community-scripts
  touch "$DB_PATH"
  chown root:root "$DB_PATH"
  chmod 644 "$DB_PATH"
  msg_ok "Directory created successfully"

  ADMIN_PASS=$(random_password 20)
  msg_warn "FileBrowser runs as root and shows the whole filesystem. Without authentication, anyone who reaches port ${PORT} can read and change every file."
  read -r -p "Would you like to use No Authentication? (y/N): " auth_prompt
  if [[ "${auth_prompt,,}" =~ ^(y|yes)$ ]]; then
    msg_info "Configuring No Authentication"
    cd /usr/local/community-scripts
    $STD filebrowser config init -a '0.0.0.0' -p "$PORT" -d "$DB_PATH"
    $STD filebrowser config set -a '0.0.0.0' -p "$PORT" -d "$DB_PATH"
    $STD filebrowser config set --auth.method=noauth --database "$DB_PATH"
    if ! filebrowser users update 1 --perm.admin --database "$DB_PATH" &>/dev/null; then
      $STD filebrowser users add admin "$ADMIN_PASS" --perm.admin --database "$DB_PATH"
    fi
    msg_ok "No Authentication configured"
  else
    msg_info "Setting up authentication"
    cd /usr/local/community-scripts
    $STD filebrowser config init -a '0.0.0.0' -p "$PORT" -d "$DB_PATH"
    $STD filebrowser config set -a '0.0.0.0' -p "$PORT" -d "$DB_PATH"
    $STD filebrowser users add admin "$ADMIN_PASS" --perm.admin --database "$DB_PATH"
    echo -e "FileBrowser\nUsername: admin\nPassword: ${ADMIN_PASS}" >~/filebrowser.creds
    chmod 600 ~/filebrowser.creds
    msg_ok "Authentication configured (credentials saved in ~/filebrowser.creds)"
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
    $STD rc-update add filebrowser default
    $STD rc-service filebrowser start
  fi
  msg_ok "Service created successfully"

  msg_ok "${APP} is reachable at: ${BL}http://${IP}:${PORT}${CL}"
else
  msg_warn "Installation skipped. Exiting."
  exit 0
fi
