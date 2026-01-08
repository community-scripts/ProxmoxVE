#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# Co-Author: remz1337
# License: MIT
# https://github.com/remz1337/ProxmoxVE/raw/remz/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y {curl,sudo,mc,libc6}
msg_ok "Installed Dependencies"

if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "INFLUXDB v2" --yesno "Scrutiny needs InfluxDB. Do you wish to install a new InfluxDB in the same LXC?" 10 58); then
  msg_info "Installing InfluxDB Dependencies"
  $STD apt-get install -y lsb-base
  $STD apt-get install -y lsb-release
  $STD apt-get install -y gnupg2
  msg_ok "Installed InfluxDB Dependencies"

  msg_info "Setting up InfluxDB Repository"
  wget -q https://repos.influxdata.com/influxdata-archive_compat.key
  cat influxdata-archive_compat.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
  sh -c 'echo "deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main" > /etc/apt/sources.list.d/influxdata.list'
  msg_ok "Set up InfluxDB Repository"

  msg_info "Installing InfluxDB"
  $STD apt-get update
  $STD apt-get install -y influxdb2
  $STD systemctl enable --now influxdb
  msg_ok "Installed InfluxDB"
else
  echo -e "${YW}Don't forget to update the scrutiny configuration file with the external InfluxDB parameters.${CL}"
fi

msg_info "Installing Scrutiny (web app and API)"
mkdir -p /opt/scrutiny/config
mkdir -p /opt/scrutiny/web
mkdir -p /opt/scrutiny/bin

cd /opt/scrutiny/config
$STD wget -O scrutiny.yaml https://raw.githubusercontent.com/AnalogJ/scrutiny/master/example.scrutiny.yaml

cd /opt/scrutiny/bin
$STD wget "https://github.com/AnalogJ/scrutiny/releases/latest/download/scrutiny-web-linux-amd64"
chmod +x scrutiny-web-linux-amd64

cd /opt/scrutiny/web
$STD wget "https://github.com/AnalogJ/scrutiny/releases/latest/download/scrutiny-web-frontend.tar.gz"

# Next, lets extract the frontend files.
# NOTE: after extraction, there **should not** be a `dist` subdirectory in `/opt/scrutiny/web` directory.
$STD tar xvzf scrutiny-web-frontend.tar.gz --strip-components 1 -C .
msg_ok "Installed Scrutiny"


msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/scrutiny.service
[Unit]
Description=Scrutiny service
After=syslog.target network.target

[Service]
Type=simple
WorkingDirectory=/opt/scrutiny
ExecStart=/opt/scrutiny/bin/scrutiny-web-linux-amd64 start --config /opt/scrutiny/config/scrutiny.yaml
Restart=on-failure
RestartSec=5min

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now scrutiny
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/scrutiny/web/scrutiny-web-frontend.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

echo -e "Don't forget to update the Scrutiny config file (${GN}/opt/scrutiny/config/scrutiny.yaml${CL}) and reboot."