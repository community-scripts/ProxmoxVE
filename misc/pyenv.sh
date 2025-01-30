#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

set -e
YW=$(echo "\033[33m")
RD=$(echo "\033[01;31m")
BL=$(echo "\033[36m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"
BFR="\\r\\033[K"
HOLD="-"
function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}
function msg_error() {
  local msg="$1"
  echo -e "${BFR} ${CROSS} ${RD}${msg}${CL}"
}
if command -v pveversion >/dev/null 2>&1; then msg_error "Can't Install on Proxmox "; exit; fi
msg_info "Installing pyenv"
apt-get install -y \
  make \
  build-essential \
  libjpeg-dev \
  libpcap-dev \
  libssl-dev \
  zlib1g-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  autoconf \
  git \
  curl \
  sudo \
  llvm \
  libncursesw5-dev \
  xz-utils \
  tk-dev \
  libxml2-dev \
  libxmlsec1-dev \
  libffi-dev \
  libopenjp2-7 \
  libtiff5 \
  libturbojpeg0-dev \
  liblzma-dev &>/dev/null

git clone https://github.com/pyenv/pyenv.git ~/.pyenv &>/dev/null
set +e
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n eval "$(pyenv init --path)"\nfi' >> ~/.bashrc  
msg_ok "Installed pyenv"
. ~/.bashrc
set -e
msg_info "Installing Python 3.11.1"
pyenv install 3.11.1 &>/dev/null
pyenv global 3.11.1
msg_ok "Installed Python 3.11.1"
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
python3 -m pip install wheel &>/dev/null
pip3 install --upgrade pip &>/dev/null
pip3 install psycopg2-binary &>/dev/null
pip3 install --pre homeassistant &>/dev/null
systemctl enable homeassistant &>/dev/null
msg_ok "Installed Home Assistant Beta"
echo -e " Go to $(hostname -I | awk '{print $1}'):8123"
hass
fi

read -r -p "Would you like to install ESPHome Beta? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
msg_info "Installing ESPHome Beta"
mkdir /srv/esphome
cd /srv/esphome
python3 -m venv .
source bin/activate
python3 -m pip install wheel &>/dev/null
pip3 install --upgrade pip &>/dev/null
pip3 install --pre esphome &>/dev/null
cat <<EOF >/srv/esphome/start.sh
#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
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
echo -e " Go to $(hostname -I | awk '{print $1}'):6052"
exec $SHELL
fi

read -r -p "Would you like to install Matter-Server (Beta)? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
msg_info "Installing Matter Server"
apt-get install -y \
libcairo2-dev \
libjpeg62-turbo-dev \
libgirepository1.0-dev \
libpango1.0-dev \
libgif-dev \
g++ &>/dev/null
python3 -m pip install wheel 
pip3 install --upgrade pip 
pip install python-matter-server[server]
msg_ok "Installed Matter Server"
echo -e "Start server > python -m matter_server.server"
fi
msg_ok "\nFinished\n"
exec $SHELL
