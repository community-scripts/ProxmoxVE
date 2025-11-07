#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
   ________
  / ____/ /___ _____  ________  _____
 / / __/ / __ `/ __ \/ ___/ _ \/ ___/
/ /_/ / / /_/ / / / / /__/  __(__  )
\____/_/\__,_/_/ /_/\___/\___/____/

EOF
}

APP="Glances"
YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
RD=$(echo "\033[01;31m")
BL=$(echo "\033[36m")
CL=$(echo "\033[m")
CM="${GN}✔️${CL}"
CROSS="${RD}✖️${CL}"
INFO="${BL}ℹ️${CL}"

function msg_info() { echo -e "${INFO} ${YW}$1...${CL}"; }
function msg_ok() { echo -e "${CM} ${GN}$1${CL}"; }
function msg_error() { echo -e "${CROSS} ${RD}$1${CL}"; }

get_local_ip() {
  if command -v hostname >/dev/null 2>&1 && hostname -I 2>/dev/null; then
    hostname -I | awk '{print $1}'
  elif command -v ip >/dev/null 2>&1; then
    ip -4 addr show scope global | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1
  else
    echo "127.0.0.1"
  fi
}
IP=$(get_local_ip)

install_glances_debian() {
  msg_info "Installing dependencies"
  apt-get update >/dev/null 2>&1
  apt-get install -y gcc lm-sensors wireless-tools >/dev/null 2>&1
  msg_ok "Installed dependencies"

  msg_info "Setting up Python + uv"
  source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
  setup_uv PYTHON_VERSION="3.12"
  msg_ok "Setup Python + uv"

  msg_info "Installing $APP (with web UI)"
  cd /opt
  mkdir -p glances
  cd glances
  uv venv
  source .venv/bin/activate >/dev/null 2>&1
  uv pip install --upgrade pip wheel setuptools >/dev/null 2>&1
  uv pip install "glances[web]" >/dev/null 2>&1
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

  echo -e "\n$APP is now running at: http://$IP:61208\n"
}

# update on Debian/Ubuntu
update_glances_debian() {
  if [[ ! -d /opt/glances/.venv ]]; then
    msg_error "$APP is not installed"
    exit 1
  fi
  msg_info "Updating $APP"
  cd /opt/glances
  source .venv/bin/activate
  uv pip install --upgrade "glances[web]" >/dev/null 2>&1
  deactivate
  systemctl restart glances
  msg_ok "Updated $APP"
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
  apk update >/dev/null 2>&1
  $STD apk add --no-cache \
    gcc musl-dev linux-headers python3-dev \
    python3 py3-pip py3-virtualenv lm-sensors wireless-tools >/dev/null 2>&1
  msg_ok "Installed dependencies"

  msg_info "Setting up Python + uv"
  source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
  setup_uv PYTHON_VERSION="3.12"
  msg_ok "Setup Python + uv"

  msg_info "Installing $APP (with web UI)"
  cd /opt
  mkdir -p glances
  cd glances
  uv venv
  source .venv/bin/activate
  uv pip install --upgrade pip wheel setuptools >/dev/null 2>&1
  uv pip install "glances[web]" >/dev/null 2>&1
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
    exit 1
  fi
  msg_info "Updating $APP"
  cd /opt/glances
  source .venv/bin/activate
  uv pip install --upgrade "glances[web]" >/dev/null 2>&1
  deactivate
  rc-service glances restart
  msg_ok "Updated $APP"
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
