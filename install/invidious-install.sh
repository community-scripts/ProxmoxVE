#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/iv-org/invidious

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  git \
  pkg-config \
  libssl-dev \
  libxml2-dev \
  libyaml-dev \
  libgmp-dev \
  libreadline-dev \
  librsvg2-bin \
  libsqlite3-dev \
  zlib1g-dev \
  libpcre2-dev \
  libevent-dev \
  fonts-open-sans
msg_ok "Installed Dependencies"

if [[ "$(arch_resolve amd64 arm64)" == "amd64" ]]; then
  setup_deb822_repo "crystal" "https://download.opensuse.org/repositories/devel:/languages:/crystal/Debian_13/Release.key" "https://download.opensuse.org/repositories/devel:/languages:/crystal/Debian_13/" "./"
  $STD apt install -y crystal
else
  fetch_and_deploy_gh_release "Crystal" "crystal-lang/crystal" "prebuild" "latest" "/opt/crystal" "crystal-*-linux-aarch64-bundled.tar.gz"
  ln -sf /opt/crystal/bin/crystal /usr/local/bin/crystal
  ln -sf /opt/crystal/bin/shards /usr/local/bin/shards
fi

PG_VERSION="17" setup_postgresql
PG_DB_NAME="invidious" PG_DB_USER="invidious" setup_postgresql_db
fetch_and_deploy_gh_release "Invidious" "iv-org/invidious" "tarball" "latest" "/opt/invidious"
fetch_and_deploy_gh_release "Invidious Companion" "iv-org/invidious-companion" "prebuild" "latest" "/opt/invidious-companion" "invidious_companion-$(arch_resolve x86_64 aarch64)-unknown-linux-gnu.tar.gz"

msg_info "Building Invidious"
cd /opt/invidious
INVIDIOUS_VERSION="$(cat ~/.invidious 2>/dev/null || echo "unknown")"
INVIDIOUS_VERSION="${INVIDIOUS_VERSION#v}"
sed -i \
  -e "s~^\(\s*CURRENT_BRANCH\s*=\).*~\1 \"master\"~" \
  -e "s~^\(\s*CURRENT_COMMIT\s*=\).*~\1 \"\"~" \
  -e "s~^\(\s*CURRENT_VERSION\s*=\).*~\1 \"${INVIDIOUS_VERSION}\"~" \
  -e "s~^\(\s*CURRENT_TAG\s*=\).*~\1 \"${INVIDIOUS_VERSION}\"~" \
  -e "s~^\(\s*ASSET_COMMIT\s*=\).*~\1 \"\"~" \
  src/invidious.cr
$STD make
msg_ok "Built Invidious"

msg_info "Configuring Invidious"
SECRET_KEY="$(openssl rand -hex 8)"
HMAC_KEY="$(openssl rand -hex 32)"
sed -e '\~^db:~,\~dbname:~d' \
  -e "s~^#database_.*~database_url: postgres://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}~" \
  -e 's~^#check_tables.*~check_tables: true~' \
  -e 's~^#invidious_companion:~invidious_companion:~' \
  -e 's~^#  - private_~  - private_~' \
  -e "s~^#invidious_companion_key:.*~invidious_companion_key: \"${SECRET_KEY}\"~" \
  -e "s~^hmac_key:.*~hmac_key: \"${HMAC_KEY}\"~" \
  /opt/invidious/config/config.example.yml >/opt/invidious/config/config.yml
chmod 600 /opt/invidious/config/config.yml

cat <<EOF >/etc/logrotate.d/invidious.logrotate
/opt/invidious/invidious.log {
  rotate 4
  weekly
  notifempty
  missingok
  compress
  minsize 1048576
}
EOF
chmod 0644 /etc/logrotate.d/invidious.logrotate
msg_ok "Configured Invidious"

msg_info "Migrating database"
$STD ./invidious --migrate
msg_ok "Migrated database"

msg_info "Configuring services"
sed -e 's|^User=invidious|User=root|' \
  -e 's|^Group=invidious|Group=root|' \
  -e 's|/home/invidious/invidious|/opt/invidious|g' \
  /opt/invidious/invidious.service >/etc/systemd/system/invidious.service
mkdir -p /var/tmp/youtubei.js
cat <<EOF >/etc/systemd/system/invidious-companion.service
[Unit]
Description=Invidious Companion
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/invidious-companion
Environment=SERVER_SECRET_KEY=${SECRET_KEY}
Environment=CACHE_DIRECTORY=/var/tmp/youtubei.js
ExecStart=/opt/invidious-companion/invidious_companion
Restart=always
RestartSec=2s

[Install]
WantedBy=multi-user.target
EOF
systemctl -q enable --now invidious invidious-companion
msg_ok "Configured services"

motd_ssh
customize
cleanup_lxc
