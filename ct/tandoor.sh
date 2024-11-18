#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
  ______                __                    ____            _
 /_  __/___ _____  ____/ /___  ____  _____   / __ \___  _____(_)___  ___  _____
  / / / __ `/ __ \/ __  / __ \/ __ \/ ___/  / /_/ / _ \/ ___/ / __ \/ _ \/ ___/
 / / / /_/ / / / / /_/ / /_/ / /_/ / /     / _, _/  __/ /__/ / /_/ /  __(__  )
/_/  \__,_/_/ /_/\__,_/\____/\____/_/     /_/ |_|\___/\___/_/ .___/\___/____/
                                                           /_/
EOF
}
header_info
echo -e "Loading..."
APP="Tandoor"
var_disk="10"
var_cpu="4"
var_ram="4096"
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
  if [[ ! -d /opt/tandoor ]]; then msg_error "No ${APP} Installation Found!"; exit; fi 
  if cd /opt/tandoor && git pull | grep -q 'Already up to date'; then
    msg_ok "There is currently no update available."
  else
    msg_info "Updating ${APP} (Patience)"
    export $(cat /opt/tandoor/.env | grep "^[^#]" | xargs)
    cd /opt/tandoor/
    pip3 install -r requirements.txt >/dev/null 2>&1
    /usr/bin/python3 /opt/tandoor/manage.py migrate >/dev/null 2>&1
    /usr/bin/python3 /opt/tandoor/manage.py collectstatic --no-input >/dev/null 2>&1
    /usr/bin/python3 /opt/tandoor/manage.py collectstatic_js_reverse >/dev/null 2>&1
    cd /opt/tandoor/vue
    yarn install >/dev/null 2>&1
    yarn build >/dev/null 2>&1
    systemctl restart gunicorn_tandoor
    msg_ok "Updated ${APP}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} Setup should be reachable by going to the following URL.
         ${BL}http://${IP}:8002${CL} \n"
