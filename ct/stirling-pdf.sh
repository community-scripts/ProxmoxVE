#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
   _____ __  _      ___                 ____  ____  ______
  / ___// /_(_)____/ (_)___  ____ _    / __ \/ __ \/ ____/
  \__ \/ __/ / ___/ / / __ \/ __ `/___/ /_/ / / / / /_
 ___/ / /_/ / /  / / / / / / /_/ /___/ ____/ /_/ / __/
/____/\__/_/_/  /_/_/_/ /_/\__, /   /_/   /_____/_/
                          /____/
EOF
}
header_info
echo -e "Loading..."
APP="Stirling-PDF"
var_disk="8"
var_cpu="2"
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
if [[ ! -d /opt/Stirling-PDF ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating ${APP}"
systemctl stop stirlingpdf
RELEASE=$(curl -s https://api.github.com/repos/Stirling-Tools/Stirling-PDF/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q https://github.com/Stirling-Tools/Stirling-PDF/archive/refs/tags/v$RELEASE.tar.gz
tar -xzf v$RELEASE.tar.gz
cd Stirling-PDF-$RELEASE
chmod +x ./gradlew
./gradlew build &>/dev/null
cp -r ./build/libs/Stirling-PDF-*.jar /opt/Stirling-PDF/
cp -r scripts /opt/Stirling-PDF/
cd ~
rm -rf Stirling-PDF-$RELEASE v$RELEASE.tar.gz
ln -sf /opt/Stirling-PDF/Stirling-PDF-$RELEASE.jar /opt/Stirling-PDF/Stirling-PDF.jar
systemctl start stirlingpdf
msg_ok "Updated ${APP} to v$RELEASE"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8080 ${CL} \n"
