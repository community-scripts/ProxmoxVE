#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  git \
  automake \
  autoconf \
  libtool \
  libleptonica-dev \
  pkg-config \
  zlib1g-dev \
  make \
  g++ \
  unpaper \
  qpdf \
  poppler-utils
msg_ok "Installed Dependencies"

msg_info "Installing LibreOffice Components"
$STD apt-get install -y \
  libreoffice-writer \
  libreoffice-calc \
  libreoffice-impress
msg_ok "Installed LibreOffice Components"

msg_info "Installing Python Dependencies"
$STD apt-get install -y \
  python3 \
  python3-pip
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
$STD pip3 install \
  uno \
  opencv-python-headless \
  unoconv \
  pngquant \
  WeasyPrint 
msg_ok "Installed Python Dependencies"

msg_info "Installing Azul Zulu"
wget -qO /etc/apt/trusted.gpg.d/zulu-repo.asc "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xB1998361219BD9C9"
wget -q https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-3_all.deb
$STD dpkg -i zulu-repo_1.0.0-3_all.deb
$STD apt-get update
$STD apt-get -y install zulu17-jdk
msg_ok "Installed Azul Zulu"

msg_info "Installing JBIG2"
$STD git clone https://github.com/agl/jbig2enc /opt/jbig2enc
cd /opt/jbig2enc
$STD bash ./autogen.sh
$STD bash ./configure
$STD make
$STD make install
msg_ok "Installed JBIG2"

msg_info "Installing Language Packs (Patience)"
$STD apt-get install -y 'tesseract-ocr-*'
msg_ok "Installed Language Packs"

msg_info "Installing Stirling-PDF (Additional Patience)"
RELEASE=$(curl -s https://api.github.com/repos/Stirling-Tools/Stirling-PDF/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q https://github.com/Stirling-Tools/Stirling-PDF/archive/refs/tags/v$RELEASE.tar.gz
tar -xzf v$RELEASE.tar.gz
cd Stirling-PDF-$RELEASE
chmod +x ./gradlew
$STD ./gradlew build
mkdir -p /opt/Stirling-PDF
touch /opt/Stirling-PDF/.env
mv ./build/libs/Stirling-PDF-*.jar /opt/Stirling-PDF/
mv scripts /opt/Stirling-PDF/
ln -s /opt/Stirling-PDF/Stirling-PDF-$RELEASE.jar /opt/Stirling-PDF/Stirling-PDF.jar
ln -s /usr/share/tesseract-ocr/5/tessdata/ /usr/share/tessdata
msg_ok "Installed Stirling-PDF v$RELEASE"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/stirlingpdf.service
[Unit]
Description=Stirling-PDF service
After=syslog.target network.target

[Service]
SuccessExitStatus=143

User=root
Group=root

Type=simple
EnvironmentFile=/opt/Stirling-PDF/.env
WorkingDirectory=/opt/Stirling-PDF
ExecStart=/usr/bin/java -jar Stirling-PDF.jar
ExecStop=/bin/kill -15 %n

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now stirlingpdf.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf v$RELEASE.tar.gz /zulu-repo_1.0.0-3_all.deb
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
