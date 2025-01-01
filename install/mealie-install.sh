#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: TheRealVira
# License: MIT
# Source: https://github.com/mealie-recipes/mealie

# Import Functions und Setup
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    nodejs \
    npm \
    sudo \
    git \
    python3 \
    curl \
    mc \
    build-essential \
    libwebp-dev \
    libsasl2-dev \
    libldap2-dev \
    libssl-dev \
    gnupg \
    gnupg2 \
    gnupg1 \
    gosu \
    iproute2 \
    libldap-common \
    libldap-2.5

mkdir /app
npm install --global yarn
msg_ok "Installed Dependencies"

RELEASE=$(curl -s https://api.github.com/repos/mealie-recipes/mealie/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
msg_info "Downloading mealie ${RELEASE}"
wget -q "https://github.com/mealie-recipes/mealie/archive/refs/tags/${RELEASE}.zip"
unzip "${RELEASE}.zip" -d /app/${APP}
echo "${RELEASE}" >/app/${APP}_version.txt
msg_ok "Downloading mealie ${RELEASE}"

msg_info "Setting up frontend"
cd /app/${APP}
npm yarn install \
    --prefer-offline \
    --frozen-lockfile \
    --non-interactive \
    --production=false \
    --network-timeout=1000000
npm yarn generate
msg_ok "Setting up frontend"

msg_info "Setting up ENV"
cat <<EOF >>/etc/environment
MEALIE_HOME="/app"

PYTHONUNBUFFERED=1
PYTHONDONTWRITEBYTECODE=1
PIP_NO_CACHE_DIR=off
PIP_DISABLE_PIP_VERSION_CHECK=on
PIP_DEFAULT_TIMEOUT=100
POETRY_HOME="/opt/poetry"
POETRY_VIRTUALENVS_IN_PROJECT=true
POETRY_NO_INTERACTION=1
POETRY_VERSION=1.3.1
PYSETUP_PATH="/opt/pysetup"
VENV_PATH="/opt/pysetup/.venv"

PRODUCTION=true
TESTING=false
LD_LIBRARY_PATH=/usr/local/lib
APP_PORT=9000
STATIC_FILES=/spa/static
HOST 0.0.0.0
EOF
export PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"
set -a; source /etc/environment; set +a;
msg_ok "Setting up ENV"

msg_info "Create user account"
useradd -u 911 -U -d $MEALIE_HOME -s /bin/bash abc
usermod -G users abc
mkdir $MEALIE_HOME
msg_ok "Create user account"

msg_info "Builder Image"
pip install -U --no-cache-dir pip
curl -sSL https://install.python-poetry.org | python3 -
cd $PYSETUP_PATH
cp ./poetry.lock ./pyproject.toml ./
poetry install -E pgsql --only main
msg_ok "Builder Image"

msg_info "CRFPP Image"
mkdir -p /run/secrets
cp ./mealie $MEALIE_HOME/mealie
cp ./poetry.lock ./pyproject.toml $MEALIE_HOME/
cd $MEALIE_HOME
. $VENV_PATH/bin/activate
poetry install -E pgsql --only main
cd ~
python $MEALIE_HOME/mealie/scripts/install_model.py
msg_ok "CRFPP Image"

msg_info "Copy Frontend"
cp /app/dist $STATIC_FILES
cp ./docker/entry.sh $MEALIE_HOME/run.sh
chmod +x $MEALIE_HOME/run.sh
$MEALIE_HOME/run.sh
msg_ok "Copy Frontend"

motd_ssh
customize
