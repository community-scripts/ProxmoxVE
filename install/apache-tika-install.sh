#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Andy Grunwald (andygrunwald)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/apache/tika/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
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

JAVA_VERSION="21" setup_java

msg_info "Installing Apache Tika"
RELEASE="$(curl -fsSL https://dlcdn.apache.org/tika/ | grep -oP '(?<=href=")[0-9]+\.[0-9]+\.[0-9]+(?=/")' | sort -V | tail -n1)"
# As of 4.0.0, upstream ships tika-server-standard as a zip instead of a
# standalone jar: tika-server-standard-<version>.jar inside it is a thin
# launcher whose manifest Class-Path depends on a sibling lib/ (and
# plugins/) directory that has to be deployed alongside it -
# fetch_and_deploy_from_url handles that extraction.
fetch_and_deploy_from_url "https://dlcdn.apache.org/tika/${RELEASE}/tika-server-standard-${RELEASE}.zip" /opt/apache-tika
mv "/opt/apache-tika/tika-server-standard-${RELEASE}.jar" /opt/apache-tika/tika-server-standard.jar
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
cleanup_lxc
