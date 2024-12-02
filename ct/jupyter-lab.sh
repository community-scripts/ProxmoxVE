#!/usr/bin/env bash

source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2024 itssujee
# Author: itssujee
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
     __               __          __        __ 
 __ / /_ _____  __ __/ /____ ____/ /  ___ _/ / 
/ // / // / _ \/ // / __/ -_) __/ /__/ _ `/ _ \
\___/\_,_/ .__/\_, /\__/\__/_/ /____/\_,_/_.__/
        /_/   /___/                            
EOF
}
header_info
echo -e "Loading..."
APP="jupyter-lab"
var_disk="10"
var_cpu="2"
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

start
build_container
description

cat <<INSTALLER_MESSAGE
========================================================================
Jupyter Lab installation successful!
------------------------------------------------------------------------
Check service status      : sudo systemctl status jupyterlab
Access JupyterLab         : http://${IP}:8080/lab
Default password          : password
Change the password       : jupyter server password
========================================================================
INSTALLER_MESSAGE