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
CODENAME=$(get_os_info codename)
cat <<EOF >/etc/apt/sources.list.d/debian-backports.sources
Types: deb
URIs: http://deb.debian.org/debian
Suites: ${CODENAME}-backports
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
apt_update_safe
$STD apt install -y \
  chromium \
  fonts-crosextra-carlito \
  fonts-crosextra-caladea \
  fonts-liberation \
  fonts-liberation2 \
  fonts-dejavu \
  fonts-noto-cjk \
  fonts-noto-color-emoji \
  fonts-noto-core \
  fonts-urw-base35
# lok is built against the LibreOffice from backports
$STD apt install -y -t "${CODENAME}-backports" \
  libreoffice-writer \
  libreoffice-calc \
  libreoffice-impress \
  libreoffice-draw \
  libreoffice-math
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "gotenberg" "gotenberg/gotenberg" "tarball" "latest" "/opt/gotenberg"

GO_VERSION="$(awk '$1=="go"{print $2}' /opt/gotenberg/go.mod | cut -d. -f1,2)" setup_go

LOK_VERSION="$(awk -F= '/^ARG LOK_VERSION=/{print $2}' /opt/gotenberg/build/Dockerfile)"
fetch_and_deploy_gh_release "lok" "gotenberg/lok" "prebuild" "$LOK_VERSION" "/usr/local/bin" "lok_${LOK_VERSION#v}_linux_$(arch_resolve "amd64" "arm64").tar.gz"

msg_info "Building Gotenberg (Patience)"
cd /opt/gotenberg
export CGO_ENABLED=0
$STD go mod download
$STD go build -o /usr/local/bin/gotenberg \
  -ldflags "-s -w -X 'github.com/gotenberg/gotenberg/v9/cmd.Version=$(cat ~/.gotenberg)'" \
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
Environment=CHROMIUM_BIN_PATH=/usr/bin/chromium
Environment=CHROMIUM_HYPHEN_DATA_DIR_PATH=/opt/gotenberg/build/chromium-hyphen-data
Environment=LIBREOFFICE_BIN_PATH=/usr/lib/libreoffice/program/soffice.bin
Environment=LOK_BIN_PATH=/usr/local/bin/lok
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
