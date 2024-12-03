#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: caroipdev
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
    clear
    cat <<"EOF"
    __  ___      _       __        _                     
   /  |/  /___ _(_)___  / /_____ _(_)___  ___  __________
  / /|_/ / __ `/ / __ \/ __/ __ `/ / __ \/ _ \/ ___/ ___/
 / /  / / /_/ / / / / / /_/ /_/ / / / / /  __/ /  / /    
/_/  /_/\__,_/_/_/ /_/\__/\__,_/_/_/ /_/\___/_/  /_/     
                                                         
EOF
}
header_info
echo -e "Loading..."
APP="Maintainerr"
var_disk="4"
var_cpu="1"
var_ram="2048"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
    CT_TYPE="1"
    PW=""
    CT_ID=$NEXTID
    HN=$NSAPP
    DISK_SIZE="$var_disk"
    CORE_COUNT="$var_cpu"
    RAM_SIZE="$var_ram"
    BRG="vmbr0"
    NET="dhcp"
    GATE=""
    APT_CACHER=""
    APT_CACHER_IP=""
    DISABLEIP6="no"
    MTU=""
    SD=""
    NS=""
    MAC=""
    VLAN=""
    SSH="no"
    VERB="no"
    echo_default
}

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -f "/opt/${APP}_version.txt" ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Fetching latest ${APP}"
    RELEASE=$(curl -s https://api.github.com/repos/jorenn92/maintainerr/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')

    if [ "${RELEASE}" == "$(</opt/${APP}_version.txt)" ]; then
        msg_error "No Update Available"
        exit 0
    fi

    systemctl stop maintainerr.service
    systemctl stop maintainerr-server.service
    cd /opt/

    RELEASE=$(curl -s https://api.github.com/repos/jorenn92/maintainerr/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    wget -q https://github.com/jorenn92/maintainerr/archive/refs/tags/v${RELEASE}.zip
    unzip -q v${RELEASE}.zip
    rm -rf "/opt/v${RELEASE}.zip"
    cd /opt/Maintainerr-${RELEASE}
    corepack install &>/dev/null

    msg_ok "Fetched latest ${APP}"

    msg_info "Building Maintainerr"

    yarn --immutable --network-timeout 99999999 &>/dev/null

    # linting is not necessary
    rm ./server/.eslintrc.js
    rm ./ui/.eslintrc.json

    yarn build:server &>/dev/null

    cat >>./ui/.env <<EOF
NEXT_PUBLIC_BASE_PATH=/__PATH_PREFIX__
EOF

    sed -i "s,basePath: '',basePath: '/__PATH_PREFIX__',g" ./ui/next.config.js
    yarn build:ui &>/dev/null

    msg_ok "Built Maintainerr"

    msg_info "Migrating DB"

    # copy the db to the new version
    mkdir ./data
    cp /opt/data/maintainerr.sqlite ./data/maintainerr.sqlite
    yarn migration:run &>/dev/null

    mv /opt/data/maintainerr.sqlite ./data/maintainerr.sqlite.bak
    mv ./data/maintainerr.sqlite /opt/data/maintainerr.sqlite

    msg_ok "Migrated DB"

    msg_info "Updating files"

    mv /opt/app /opt/app.bak
    mkdir /opt/app

    # copy standalone UI
    mv ./ui/.next/standalone/ui/ ./standalone-ui/
    mv ./ui/.next/standalone/ ./standalone-ui/
    mv ./ui/.next/static ./standalone-ui/.next/static
    mv ./ui/public ./standalone-ui/public
    rm -rf ./ui
    mv ./standalone-ui ./ui

    # Copy standalone server
    mv ./server/dist ./standalone-server
    rm -rf ./server
    mv ./standalone-server ./server

    rm -rf node_modules .yarn

    yarn workspaces focus --production &>/dev/null

    rm -rf .yarn
    rm -rf /opt/yarn-*

    mv /opt/Maintainerr-${RELEASE}/* /opt/app/
    rm -rf /opt/Maintainerr-${RELEASE}

    cd /opt/app

    rm -rf /opt/app.bak

    msg_ok "Updated files"

    msg_info "Updating Service"

    cat <<EOF >/etc/systemd/system/maintainerr-server.service
[Unit]
Description=Maintainerr Server
After=network.target

[Service]
ExecStart=/usr/bin/yarn node /opt/app/server/main.js
Restart=always
RestartSec=5
StartLimitBurst=100
StartLimitInterval=0
Environment=NODE_ENV=production
Environment=VERSION_TAG=stable
Environment=npm_package_version=${RELEASE}
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    msg_ok "Updated Service"

    systemctl daemon-reload

    systemctl start maintainerr-server.service
    systemctl start maintainerr.service
    msg_ok "Successfully Updated ${APP}"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:6246${CL} \n"
