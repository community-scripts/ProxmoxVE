#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://pyenv.run/ | Github: https://github.com/pyenv/pyenv

APP="pyenv"
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
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "pyenv" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions
require_debian_like

header_info
confirm_not_pve_host
get_lxc_ip
export PYENV_ROOT="${HOME}/.pyenv"

msg_info "Installing dependencies"
$STD apt update

# Official Python build dependencies for Debian/Ubuntu
# https://github.com/pyenv/pyenv/wiki#suggested-build-environment
PYENV_DEPS=(
  build-essential
  libssl-dev
  zlib1g-dev
  libbz2-dev
  libreadline-dev
  libsqlite3-dev
  curl
  git
  xz-utils
  tk-dev
  libxml2-dev
  libxmlsec1-dev
  libffi-dev
  liblzma-dev
)

# Extras for the optional Home Assistant / ESPHome installs below (Pillow et al.)
PYENV_DEPS+=(make llvm libjpeg-dev libpcap-dev libopenjp2-7)

# These were renamed between releases (libtiff5 is gone on Debian 13 / Ubuntu 24.04),
# so take whichever variant the distro actually ships
for candidates in "libncurses-dev libncursesw5-dev" "libtiff-dev libtiff5-dev" "libturbojpeg0-dev libturbojpeg-dev"; do
  for pkg in $candidates; do
    if apt-cache show "$pkg" &>/dev/null; then
      PYENV_DEPS+=("$pkg")
      break
    fi
  done
done

install_packages_with_retry "${PYENV_DEPS[@]}"
msg_ok "Installed dependencies"

# The upstream installer refuses to run when PYENV_ROOT already exists
if [[ -d "$PYENV_ROOT" ]]; then
  msg_ok "${APP} is already installed at ${PYENV_ROOT}"
else
  msg_info "Installing ${APP}"
  # Official installer - also sets up the pyenv-doctor/update/virtualenv plugins
  $STD bash <(curl -fsSL https://pyenv.run)
  msg_ok "Installed ${APP}"
fi

# Shell setup per upstream docs. On Debian-based systems ~/.profile prepends the
# per-user bin dirs *after* sourcing ~/.bashrc, so both files need the init call.
msg_info "Configuring shell environment"
for rc in "${HOME}/.bashrc" "${HOME}/.profile"; do
  [[ -f "$rc" ]] || touch "$rc"
  if ! grep -q 'PYENV_ROOT' "$rc"; then
    cat >>"$rc" <<'EOF'

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"
EOF
  fi
done
msg_ok "Configured shell environment"

# Activate pyenv for the remainder of this script
export PATH="${PYENV_ROOT}/bin:$PATH"
set +Eeuo pipefail
eval "$(pyenv init - bash)"
set -Eeuo pipefail

# pyenv resolves a version prefix to the latest release in that line, so pinning
# a patch level (the old 3.11.1) is neither needed nor portable across distros.
#
# 3.14 is the only series all three optional payloads below agree on:
#   Home Assistant Core   >= 3.14.2
#   ESPHome               >= 3.12.0, < 3.15
#   python-matter-server  >= 3.12
# (3.11 has been security-fix-only since 2024 and is EOL in 10/2027.)
PYTHON_SERIES="3.14"
msg_info "Installing Python ${PYTHON_SERIES} (latest patch release)"
$STD pyenv install -s "$PYTHON_SERIES"
pyenv global "$PYTHON_SERIES"
msg_ok "Installed Python $(pyenv version-name)"
read -r -p "Would you like to install Home Assistant Beta? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  msg_info "Installing Home Assistant Beta"
  cat <<EOF >/etc/systemd/system/homeassistant.service
[Unit]
Description=Home Assistant
After=network-online.target
[Service]
Type=simple
WorkingDirectory=/root/.homeassistant
ExecStart=/srv/homeassistant/bin/hass -c "/root/.homeassistant"
RestartForceExitStatus=100
[Install]
WantedBy=multi-user.target
EOF
  mkdir /srv/homeassistant
  cd /srv/homeassistant
  python3 -m venv .
  source bin/activate
  $STD python3 -m pip install wheel
  $STD pip3 install --upgrade pip
  $STD pip3 install psycopg2-binary
  $STD pip3 install --pre homeassistant
  systemctl enable homeassistant &>/dev/null
  msg_ok "Installed Home Assistant Beta"
  echo -e " Go to ${LOCAL_IP}:8123"
  hass
fi

read -r -p "Would you like to install ESPHome Beta? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  msg_info "Installing ESPHome Beta"
  mkdir /srv/esphome
  cd /srv/esphome
  python3 -m venv .
  source bin/activate
  $STD python3 -m pip install wheel
  $STD pip3 install --upgrade pip
  $STD pip3 install --pre esphome
  cat <<EOF >/srv/esphome/start.sh
#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /srv/esphome/bin/activate
esphome dashboard /srv/esphome/
EOF
  chmod +x start.sh
  cat <<EOF >/etc/systemd/system/esphomedashboard.service
[Unit]
Description=ESPHome Dashboard Service
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=/srv/esphome
ExecStart=/srv/esphome/start.sh
RestartSec=30
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
  systemctl enable --now esphomedashboard &>/dev/null
  msg_ok "Installed ESPHome Beta"
  echo -e " Go to ${LOCAL_IP}:6052"
  exec $SHELL
fi

read -r -p "Would you like to install Matter-Server (Beta)? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  msg_info "Installing Matter Server"
  $STD apt install -y \
    libcairo2-dev \
    libjpeg62-turbo-dev \
    libgirepository1.0-dev \
    libpango1.0-dev \
    libgif-dev \
    g++
  $STD python3 -m pip install wheel
  $STD pip3 install --upgrade pip
  $STD pip install python-matter-server[server]
  msg_ok "Installed Matter Server"
  echo -e "Start server > python -m matter_server.server"
fi
msg_ok "\nFinished\n"
exec $SHELL

