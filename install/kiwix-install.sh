#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ) | tewalds
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/kiwix/kiwix-tools

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y software-properties-common
msg_ok "Installed Dependencies"

msg_info "Adding Kiwix PPA"
add-apt-repository -y ppa:kiwixteam/release >>"$(get_active_logfile)" 2>&1
$STD apt update
msg_ok "Added Kiwix PPA"

msg_info "Installing Kiwix-Tools"
$STD apt install -y kiwix-tools
RELEASE=$(dpkg -s kiwix-tools 2>/dev/null | awk '/^Version:/{print $2}')
mkdir -p /data
echo "${RELEASE}" >/root/.kiwix
msg_ok "Installed Kiwix-Tools"

msg_info "Downloading Kiwix Test Archive"
ZIM_BASE_URL="https://download.kiwix.org/zim/wikipedia"
ZIM_FILE="$(CURL_TIMEOUT=60 CURL_CONNECT_TO=15 curl_with_retry "${ZIM_BASE_URL}/" "-" |
  grep -oE 'href="speedtest_en_blob_[0-9]{4}-[0-9]{2}\.zim"' |
  sed -E 's/^href="|"$//g' |
  sort -V |
  tail -n 1)" || true

if [[ -z "${ZIM_FILE}" ]]; then
  msg_warn "No Kiwix speedtest ZIM archive found - skipping optional download"
else
  ZIM_URL="${ZIM_BASE_URL}/${ZIM_FILE}"
  ZIM_TEMP="/data/.${ZIM_FILE}.tmp"
  ZIM_TARGET="/data/${ZIM_FILE}"
  if ! CURL_TIMEOUT=120 CURL_CONNECT_TO=15 curl_with_retry "${ZIM_URL}" "${ZIM_TEMP}"; then
    rm -f "${ZIM_TEMP}"
    msg_warn "Failed to download Kiwix ZIM archive - skipping optional download"
    ZIM_FILE=""
  elif [[ ! -s "${ZIM_TEMP}" ]]; then
    rm -f "${ZIM_TEMP}"
    msg_warn "Downloaded Kiwix ZIM archive is empty - skipping optional download"
    ZIM_FILE=""
  else
    mv "${ZIM_TEMP}" "${ZIM_TARGET}"
    msg_ok "Downloaded Kiwix Test Archive (${ZIM_FILE})"
  fi
fi

msg_info "Creating Service"
cat <<'EOF' >/etc/systemd/system/kiwix-serve.service
[Unit]
Description=Kiwix ZIM Server
After=network.target

[Service]
Type=simple
ExecStart=/bin/sh -c 'exec /usr/bin/kiwix-serve --port 8080 /data/*.zim'
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now kiwix-serve
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
