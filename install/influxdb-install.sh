#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.influxdata.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setting up InfluxDB Repository"
setup_deb822_repo \
  "influxdata" \
  "https://repos.influxdata.com/influxdata-archive_compat.key" \
  "https://repos.influxdata.com/$(get_os_info id)" \
  "stable"
msg_ok "Set up InfluxDB Repository"

read -r -p "${TAB3}Which version of InfluxDB to install? (1 or 2) " prompt
if [[ $prompt == "2" ]]; then
  INFLUX="2"
else
  INFLUX="1"
fi

msg_info "Installing InfluxDB"
$STD apt update
if [[ $INFLUX == "2" ]]; then
  $STD apt install -y influxdb2
else
  $STD apt install -y influxdb
  curl -fsSL "https://dl.influxdata.com/chronograf/releases/chronograf_1.10.8_amd64.deb" -o "/chronograf_1.10.8_amd64.deb"
  $STD dpkg -i chronograf_1.10.8_amd64.deb
  rm -rf /chronograf_1.10.8_amd64.deb
fi
$STD systemctl enable --now influxdb
msg_ok "Installed InfluxDB"

read -r -p "${TAB3}Would you like to add Telegraf? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  msg_info "Installing Telegraf"
  $STD apt install -y telegraf
  msg_ok "Installed Telegraf"
fi

motd_ssh
customize
cleanup_lxc
