#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Andy Grunwald (andygrunwald)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/apache/tika/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  software-properties-common \
  gdal-bin \
  tesseract-ocr \
  tesseract-ocr-eng \
  tesseract-ocr-ita \
  tesseract-ocr-fra \
  tesseract-ocr-spa \
  tesseract-ocr-deu
$STD echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
$STD apt-get install -y \
  xfonts-utils \
  fonts-freefont-ttf \
  fonts-liberation \
  ttf-mscorefonts-installer \
  cabextract
msg_ok "Installed Dependencies"

msg_info "Setup OpenJDK"
$STD apt-get install -y \
  openjdk-17-jre-headless
msg_ok "Setup OpenJDK"

msg_info "Installing Apache Tika"
mkdir -p /opt/apache-tika
cd /opt/apache-tika
RELEASE="$(wget -qO- https://dlcdn.apache.org/tika/ | grep -oP '(?<=href=")[0-9]+\.[0-9]+\.[0-9]+(?=/")' | sort -V | tail -n1)"
wget -q "https://dlcdn.apache.org/tika/${RELEASE}/tika-server-standard-${RELEASE}.jar"
mv tika-server-standard-${RELEASE}.jar tika-server-standard.jar
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Apache Tika"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/apache-tika.service
[Unit]
Description=Apache Tika
Documentation=https://tika.apache.org/
After=syslog.target network.target

[Service]
User=root
Restart=always
Type=simple
ExecStart=java -jar /opt/apache-tika/tika-server-standard.jar --host 0.0.0.0 --port 9998
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now apache-tika
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
