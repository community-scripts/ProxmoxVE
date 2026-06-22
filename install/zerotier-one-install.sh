#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.zerotier.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_warn "WARNING: This script will run an external installer from a third-party source (https://install.zerotier.com)."
msg_warn "The following code is NOT maintained or audited by our repository."
msg_warn "If you have any doubts or concerns, please review the installer code before proceeding:"
msg_custom "${TAB3}${GATEWAY}${BGN}${CL}" "\e[1;34m" "→  https://install.zerotier.com"
echo
read -r -p "${TAB3}Do you want to continue? [y/N]: " CONFIRM
if [[ ! $CONFIRM =~ ^([yY][eE][sS]|[yY])$ ]]; then
  msg_error "Aborted by user. No changes have been made."
  exit 10
fi

msg_info "Setting up Zerotier-One"
curl -fsSL https://raw.githubusercontent.com/zerotier/ZeroTierOne/main/doc/contact%40zerotier.com.gpg | gpg --import >/dev/null 2>&1
curl -fsSL https://install.zerotier.com -o /tmp/zerotier-install.sh
if gpg --verify /tmp/zerotier-install.sh >/dev/null 2>&1; then
  $STD bash /tmp/zerotier-install.sh
else
  msg_warn "Could not verify signature of Zerotier-One install script. Exiting..."
  exit 250
fi
msg_ok "Setup Zerotier-One"

msg_info "Setting up UI"
if [[ "$(arch_resolve)" == "arm64" ]]; then
  $STD apt-get install -y build-essential python3 openssl
  NODE_VERSION="20" setup_nodejs
  curl -fsSL "https://github.com/key-networks/ztncui/archive/refs/heads/master.tar.gz" -o /tmp/ztncui.tar.gz
  $STD tar -xzf /tmp/ztncui.tar.gz -C /tmp
  mkdir -p /opt/key-networks
  cp -r /tmp/ztncui-master/src /opt/key-networks/ztncui
  cd /opt/key-networks/ztncui
  $STD npm install --omit=dev
  cp etc/default.passwd etc/passwd
  mkdir -p etc/tls
  openssl req -x509 -sha256 -nodes -days 3650 -newkey rsa:2048 \
    -keyout etc/tls/privkey.pem -out etc/tls/fullchain.pem \
    -subj "/C=XX/ST=YY/L=ZZ/O=Security/OU=SelfSigned/CN=example.com" >/dev/null 2>&1
  id -u ztncui &>/dev/null || useradd --system --home-dir /opt/key-networks/ztncui --shell /usr/sbin/nologin ztncui
  chown -R ztncui:ztncui /opt/key-networks/ztncui
  cat <<'EOF' >/lib/systemd/system/ztncui.service
[Unit]
Description=ztncui - ZeroTier network controller user interface
Documentation=https://key-networks.com
After=network.target

[Service]
Type=simple
User=ztncui
WorkingDirectory=/opt/key-networks/ztncui
ExecStart=/usr/bin/node /opt/key-networks/ztncui/bin/www
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable -q ztncui
else
  curl -O https://s3-us-west-1.amazonaws.com/key-networks/deb/ztncui/1/x86_64/ztncui_0.8.14_amd64.deb
  dpkg -i ztncui_0.8.14_amd64.deb
fi
sh -c "echo ZT_TOKEN=$(cat /var/lib/zerotier-one/authtoken.secret) > /opt/key-networks/ztncui/.env"
echo HTTPS_PORT=3443 >>/opt/key-networks/ztncui/.env
echo NODE_ENV=production >>/opt/key-networks/ztncui/.env
chmod 400 /opt/key-networks/ztncui/.env
chown ztncui:ztncui /opt/key-networks/ztncui/.env
systemctl restart ztncui
msg_ok "Setup UI."

motd_ssh
customize
cleanup_lxc
