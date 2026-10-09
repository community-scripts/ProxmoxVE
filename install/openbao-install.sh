#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Marc Went (Dunky13)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://openbao.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "openbao" "openbao/openbao" "binary" "latest" "/opt/openbao" "openbao_*_linux_$(arch_resolve).deb"

msg_info "Configuring CLI Environment"
cat <<EOF >/etc/profile.d/openbao.sh
export BAO_ADDR=https://127.0.0.1:8200
export BAO_SKIP_VERIFY=true
EOF
source /etc/profile.d/openbao.sh
msg_ok "Configured CLI Environment"

msg_info "Starting OpenBao"
systemctl enable -q --now openbao
for _ in {1..30}; do
  curl -fsSk -o /dev/null "https://127.0.0.1:8200/v1/sys/seal-status" && break
  sleep 2
done
msg_ok "Started OpenBao"

msg_info "Initializing OpenBao"
(
  umask 077
  cat <<'EOF' >/etc/openbao/openbao-init.json
EOF
)
bao operator init -key-shares=1 -key-threshold=1 -format=json >/etc/openbao/openbao-init.json
chmod 600 /etc/openbao/openbao.env
chown root:root /etc/openbao/openbao.env
cat <<EOF >>/etc/openbao/openbao.env
BAO_ADDR=https://127.0.0.1:8200
BAO_SKIP_VERIFY=true
BAO_UNSEAL_KEY=$(jq -r '.unseal_keys_b64[0]' /etc/openbao/openbao-init.json)
BAO_ROOT_TOKEN=$(jq -r '.root_token' /etc/openbao/openbao-init.json)
EOF
rm -f /etc/openbao/openbao-init.json
msg_ok "Initialized OpenBao"

msg_info "Enabling Auto-Unseal"
mkdir -p /etc/systemd/system/openbao.service.d
cat <<'EOF' >/etc/systemd/system/openbao.service.d/unseal.conf
[Service]
ExecStartPost=-/usr/bin/bao operator unseal ${BAO_UNSEAL_KEY}
EOF
systemctl daemon-reload
systemctl restart openbao
for _ in {1..15}; do
  bao status -format=json 2>/dev/null | jq -e '.sealed == false' >/dev/null && break
  sleep 2
done
msg_ok "Enabled Auto-Unseal"

motd_ssh
customize
cleanup_lxc
