#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: madelyn (DysfunctionalProgramming)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://komga.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apt -y install \
  libarchive-dev \
  libjxl-dev \
  libheif-dev \
  libwebp-dev
msg_ok "Installed dependencies"

JAVA_VERSION="23" setup_java
fetch_and_deploy_gh_release "kepubify" "pgaskin/kepubify" "singlefile" "latest" "/usr/bin" "kepubify-linux-64bit"
USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "komga-org" "gotson/komga" "singlefile" "latest" "/opt/komga" "komga*.jar"
mv /opt/komga/komga-*.jar /opt/komga/komga.jar

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/komga.service
[Unit]
Description=Komga
After=syslog.target network.target

[Service]
Type=simple
WorkingDirectory=/opt/komga/
Environment=LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
ExecStart=/usr/bin/java --enable-native-access=ALL-UNNAMED -jar -Xmx2g komga.jar
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now komga
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
