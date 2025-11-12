#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.stirlingpdf.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt install -y \
  automake \
  autoconf \
  libtool \
  libleptonica-dev \
  pkg-config \
  zlib1g-dev \
  make \
  g++ \
  unpaper \
  fonts-urw-base35 \
  qpdf \
  poppler-utils \
  jbig2
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv
JAVA_VERSION="21" setup_java

read -r -p "${TAB3}Do you want to use Stirling-PDF with Login? (no/n = without Login) [Y/n] " response
response=${response,,} # Convert to lowercase
login_mode="false"
if [[ "$response" == "y" || "$response" == "yes" || -z "$response" ]]; then
  USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "stirling-pdf" "Stirling-Tools/Stirling-PDF" "singlefile" "latest" "/opt/Stirling-PDF" "Stirling-PDF-with-login.jar"
  mv /opt/Stirling-PDF/Stirling-PDF-with-login.jar /opt/Stirling-PDF/Stirling-PDF.jar
  touch ~/.Stirling-PDF-login
  login_mode="true"
else
  USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "stirling-pdf" "Stirling-Tools/Stirling-PDF" "singlefile" "latest" "/opt/Stirling-PDF" "Stirling-PDF.jar"
fi

msg_info "Installing LibreOffice Components"
$STD apt install -y \
  libreoffice-writer \
  libreoffice-calc \
  libreoffice-impress \
  libreoffice-core \
  libreoffice-common \
  libreoffice-base-core \
  libreoffice-script-provider-python \
  libreoffice-java-common \
  pngquant \
  weasyprint
msg_ok "Installed LibreOffice Components"

msg_info "Installing Python Dependencies"
mkdir -p /tmp/stirling-pdf
$STD uv venv /opt/.venv
export PATH="/opt/.venv/bin:$PATH"
source /opt/.venv/bin/activate
$STD uv pip install --upgrade pip
$STD uv pip install \
  opencv-python-headless \
  ocrmypdf \
  pillow \
  pdf2image
$STD apt install -y python3-uno python3-pip
$STD pip3 install --break-system-packages --timeout=120 unoserver
ln -sf /opt/.venv/bin/python3 /usr/local/bin/python3
ln -sf /opt/.venv/bin/pip /usr/local/bin/pip
msg_ok "Installed Python Dependencies"

msg_info "Installing Language Packs (Patience)"
$STD apt install -y 'tesseract-ocr-*'
msg_ok "Installed Language Packs"

msg_info "Creating Environment Variables"
cat <<EOF >/opt/Stirling-PDF/.env
# Java tuning
JAVA_BASE_OPTS="-XX:+UnlockExperimentalVMOptions -XX:MaxRAMPercentage=75 -XX:InitiatingHeapOccupancyPercent=20 -XX:+G1PeriodicGCInvokesConcurrent -XX:G1PeriodicGCInterval=10000 -XX:+UseStringDeduplication -XX:G1PeriodicGCSystemLoadThreshold=70"
JAVA_CUSTOM_OPTS=""

# LibreOffice
PATH=/opt/.venv/bin:/usr/lib/libreoffice/program:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
UNO_PATH=/usr/lib/libreoffice/program
URE_BOOTSTRAP=file:///usr/lib/libreoffice/program/fundamentalrc
PYTHONPATH=/usr/lib/libreoffice/program:/opt/.venv/lib/python3.12/site-packages
LD_LIBRARY_PATH=/usr/lib/libreoffice/program

STIRLING_TEMPFILES_DIRECTORY=/tmp/stirling-pdf
TMPDIR=/tmp/stirling-pdf
TEMP=/tmp/stirling-pdf
TMP=/tmp/stirling-pdf

# Paths
PATH=/opt/.venv/bin:/usr/lib/libreoffice/program:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EOF

if [[ "$login_mode" == "true" ]]; then
  cat <<EOF >>/opt/Stirling-PDF/.env
# activate Login
DISABLE_ADDITIONAL_FEATURES=false
SECURITY_ENABLELOGIN=true

# login credentials
SECURITY_INITIALLOGIN_USERNAME=admin
SECURITY_INITIALLOGIN_PASSWORD=stirling
EOF
fi
msg_ok "Created Environment Variables"

msg_info "Refreshing Font Cache"
$STD fc-cache -fv
msg_ok "Font Cache Updated"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/libreoffice-listener.service
[Unit]
Description=LibreOffice Headless Listener Service
After=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/lib/libreoffice/program/soffice --headless --invisible --nodefault --nofirststartwizard --nolockcheck --nologo --accept="socket,host=127.0.0.1,port=2002;urp;StarOffice.ComponentContext"
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/stirlingpdf.service
[Unit]
Description=Stirling-PDF service
After=syslog.target network.target libreoffice-listener.service
Requires=libreoffice-listener.service

[Service]
SuccessExitStatus=143
Type=simple
User=root
Group=root
EnvironmentFile=/opt/Stirling-PDF/.env
WorkingDirectory=/opt/Stirling-PDF
ExecStart=/usr/bin/java -jar Stirling-PDF.jar
ExecStop=/bin/kill -15 %n
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/unoserver.service
[Unit]
Description=UnoServer RPC Interface
After=libreoffice-listener.service
Requires=libreoffice-listener.service

[Service]
Type=simple
ExecStart=/usr/local/bin/unoserver --port 2003 --interface 127.0.0.1
Restart=always
EnvironmentFile=/opt/Stirling-PDF/.env

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now libreoffice-listener
systemctl enable -q --now stirlingpdf
systemctl enable -q --now unoserver
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f /tmp/jbig2enc.tar.gz
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
