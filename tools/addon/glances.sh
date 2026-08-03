#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nicolargo.github.io/glances/ | Github: https://github.com/nicolargo/glances

APP="Glances"
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
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "glances" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

header_info
get_lxc_ip
IP="$LOCAL_IP"

install_glances_debian() {
  msg_info "Installing dependencies"
  $STD apt update
  $STD apt install -y \
    gcc \
    lm-sensors \
    wireless-tools \
    curl
  msg_ok "Installed dependencies"

  msg_info "Setting up Python + uv"
  setup_uv PYTHON_VERSION="3.12"
  msg_ok "Setup Python + uv"

  msg_info "Installing $APP (with web UI)"
  cd /opt
  mkdir -p glances
  cd glances
  $STD uv venv --clear
  source .venv/bin/activate >/dev/null 2>&1
  $STD uv pip install --upgrade pip wheel setuptools
  $STD uv pip install "glances[web]"
  deactivate
  msg_ok "Installed $APP"

  msg_info "Creating systemd service"
  cat <<EOF >/etc/systemd/system/glances.service
[Unit]
Description=Glances - An eye on your system
After=network.target

[Service]
Type=simple
ExecStart=/opt/glances/.venv/bin/glances -w
Restart=on-failure
WorkingDirectory=/opt/glances

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now glances
  msg_ok "Created systemd service"

  msg_ok "$APP is now running at: http://${IP}:61208"
}

# update on Debian/Ubuntu
update_glances_debian() {
  if [[ ! -d /opt/glances/.venv ]]; then
    msg_error "$APP is not installed"
    exit 233
  fi
  msg_info "Updating $APP"
  cd /opt/glances
  source .venv/bin/activate
  $STD uv pip install --upgrade "glances[web]"
  deactivate
  systemctl restart glances
  msg_ok "Updated successfully!"
}

# uninstall on Debian/Ubuntu
uninstall_glances_debian() {
  msg_info "Uninstalling $APP"
  systemctl disable -q --now glances || true
  rm -f /etc/systemd/system/glances.service
  rm -rf /opt/glances
  msg_ok "Removed $APP"
}

# install on Alpine
install_glances_alpine() {
  msg_info "Installing dependencies"
  $STD apk update
  $STD apk add --no-cache \
    gcc musl-dev linux-headers python3-dev \
    python3 py3-pip py3-virtualenv lm-sensors wireless-tools curl
  msg_ok "Installed dependencies"

  msg_info "Setting up Python + uv"
  setup_uv PYTHON_VERSION="3.12"
  msg_ok "Setup Python + uv"

  msg_info "Installing $APP (with web UI)"
  cd /opt
  mkdir -p glances
  cd glances
  $STD uv venv --clear
  source .venv/bin/activate
  $STD uv pip install --upgrade pip wheel setuptools
  $STD uv pip install "glances[web]"
  deactivate
  msg_ok "Installed $APP"

  msg_info "Creating OpenRC service"
  cat <<'EOF' >/etc/init.d/glances
#!/sbin/openrc-run
command="/opt/glances/.venv/bin/glances"
command_args="-w"
command_background="yes"
pidfile="/run/glances.pid"
name="glances"
description="Glances monitoring tool"
EOF
  chmod +x /etc/init.d/glances
  rc-update add glances default
  rc-service glances start
  msg_ok "Created OpenRC service"

  echo -e "\n$APP is now running at: http://$IP:61208\n"
}

# update on Alpine
update_glances_alpine() {
  if [[ ! -d /opt/glances/.venv ]]; then
    msg_error "$APP is not installed"
    exit 233
  fi
  msg_info "Updating $APP"
  cd /opt/glances
  source .venv/bin/activate
  $STD uv pip install --upgrade "glances[web]"
  deactivate
  rc-service glances restart
  msg_ok "Updated successfully!"
}

# uninstall on Alpine
uninstall_glances_alpine() {
  msg_info "Uninstalling $APP"
  rc-service glances stop || true
  rc-update del glances || true
  rm -f /etc/init.d/glances
  rm -rf /opt/glances
  msg_ok "Removed $APP"
}

# options menu
OPTIONS=(Install "Install $APP"
  Update "Update $APP"
  Uninstall "Uninstall $APP")

CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "$APP" --menu "Select an option:" 12 58 3 \
  "${OPTIONS[@]}" 3>&1 1>&2 2>&3 || true)

# OS detection
if grep -qi "alpine" /etc/os-release; then
  case "$CHOICE" in
  Install) install_glances_alpine ;;
  Update) update_glances_alpine ;;
  Uninstall) uninstall_glances_alpine ;;
  *) exit 0 ;;
  esac
else
  case "$CHOICE" in
  Install) install_glances_debian ;;
  Update) update_glances_debian ;;
  Uninstall) uninstall_glances_debian ;;
  *) exit 0 ;;
  esac
fi
