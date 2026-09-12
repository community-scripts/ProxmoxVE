#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/gotenberg/gotenberg

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  chromium \
  libreoffice-writer \
  libreoffice-calc \
  libreoffice-impress \
  libreoffice-draw \
  libreoffice-math \
  python3-uno \
  python-is-python3 \
  pdftk-java \
  qpdf \
  libimage-exiftool-perl \
  fonts-crosextra-carlito \
  fonts-crosextra-caladea \
  fonts-liberation \
  fonts-liberation2 \
  fonts-dejavu \
  fonts-noto-cjk \
  fonts-noto-color-emoji \
  fonts-noto-core
msg_ok "Installed Dependencies"

GO_VERSION="1.27" setup_go

fetch_and_deploy_gh_release "pdfcpu" "pdfcpu/pdfcpu" "prebuild" "latest" "/opt/pdfcpu" "pdfcpu_*_Linux_$(arch_resolve "x86_64" "arm64").tar.xz"
ln -sf "$(find /opt/pdfcpu -type f -name pdfcpu | head -n1)" /usr/local/bin/pdfcpu

msg_info "Installing unoconverter"
UNOCONVERTER_VERSION=$(get_latest_github_release "gotenberg/unoconverter" "false")
download_file "https://raw.githubusercontent.com/gotenberg/unoconverter/${UNOCONVERTER_VERSION}/unoconv" /usr/local/bin/unoconverter
chmod +x /usr/local/bin/unoconverter
msg_ok "Installed unoconverter"

fetch_and_deploy_gh_release "gotenberg" "gotenberg/gotenberg" "tarball" "latest" "/opt/gotenberg"

msg_info "Building Gotenberg (Patience)"
cd /opt/gotenberg
export CGO_ENABLED=0
$STD go mod download
$STD go build -o /usr/local/bin/gotenberg \
  -ldflags "-s -w -X 'github.com/gotenberg/gotenberg/v8/cmd.Version=$(cat ~/.gotenberg)'" \
  cmd/gotenberg/main.go
msg_ok "Built Gotenberg"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/gotenberg.service
[Unit]
Description=Gotenberg
Documentation=https://gotenberg.dev
After=network.target

[Service]
Type=simple
User=root
Environment=LANG=C.UTF-8
Environment=LC_ALL=C.UTF-8
Environment=PDFTK_BIN_PATH=/usr/bin/pdftk
Environment=QPDF_BIN_PATH=/usr/bin/qpdf
Environment=EXIFTOOL_BIN_PATH=/usr/bin/exiftool
Environment=PDFCPU_BIN_PATH=/usr/local/bin/pdfcpu
Environment=CHROMIUM_BIN_PATH=/usr/bin/chromium
Environment=CHROMIUM_HYPHEN_DATA_DIR_PATH=/opt/gotenberg/build/chromium-hyphen-data
Environment=LIBREOFFICE_BIN_PATH=/usr/lib/libreoffice/program/soffice.bin
Environment=UNOCONVERTER_BIN_PATH=/usr/local/bin/unoconverter
Environment=OTEL_TRACES_EXPORTER=none
Environment=OTEL_METRICS_EXPORTER=none
Environment=OTEL_LOGS_EXPORTER=none
ExecStart=/usr/local/bin/gotenberg --api-port=3000
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now gotenberg
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
