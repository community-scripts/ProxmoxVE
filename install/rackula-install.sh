#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: gVNS (ggfevans)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/RackulaLives/Rackula

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y nginx
msg_ok "Installed Dependencies"

msg_info "Installing Bun"
ensure_dependencies unzip ca-certificates
BUN_VERSION="${BUN_VERSION:-1.3.14}"
case "$(uname -m)" in
x86_64) grep -q avx2 /proc/cpuinfo && BUN_VARIANT="x64" || BUN_VARIANT="x64-baseline" ;;
aarch64) BUN_VARIANT="aarch64" ;;
*)
  msg_error "Unsupported architecture: $(uname -m)"
  exit 1
  ;;
esac
BUN_TMP=$(mktemp -d)
curl_with_retry "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-${BUN_VARIANT}.zip" "$BUN_TMP/bun.zip"
$STD unzip -o "$BUN_TMP/bun.zip" -d "$BUN_TMP"
mkdir -p /usr/local/bun/bin
install -m 755 "$BUN_TMP/bun-linux-${BUN_VARIANT}/bun" /usr/local/bun/bin/bun
rm -rf "$BUN_TMP"
ln -sf /usr/local/bun/bin/bun /usr/local/bin/bun
ln -sf /usr/local/bun/bin/bun /usr/local/bin/bunx
msg_ok "Installed Bun"

fetch_and_deploy_gh_release "rackula" "RackulaLives/Rackula" "prebuild" "latest" "/opt/rackula" "rackula-lxc-*.tar.gz"

msg_info "Setting up Rackula"
mkdir -p /opt/rackula/data /etc/nginx/snippets

SECURITY_HEADERS_SRC="/opt/rackula/config/security-headers.conf"
if [ ! -f "$SECURITY_HEADERS_SRC" ]; then
  msg_error "Required config file missing: $SECURITY_HEADERS_SRC (release may be incomplete)"
  exit 1
fi
cp "$SECURITY_HEADERS_SRC" /etc/nginx/snippets/security-headers.conf

chown -R root:root /opt/rackula/frontend
find /opt/rackula/frontend -type d -exec chmod 755 {} \;
find /opt/rackula/frontend -type f -exec chmod 644 {} \;
chmod 750 /opt/rackula/data

API_WRITE_TOKEN=$(openssl rand -hex 32)
cat <<EOF >/opt/rackula/data/.env
RACKULA_API_WRITE_TOKEN=${API_WRITE_TOKEN}
CORS_ORIGIN=http://localhost
ALLOW_INSECURE_CORS=false
EOF
chmod 600 /opt/rackula/data/.env

cat <<EOF >/etc/nginx/snippets/rackula-api-token.conf
map \$host \$rackula_api_write_token {
  default "${API_WRITE_TOKEN}";
}
map \$host \$rackula_has_api_write_token {
  default 1;
}
EOF
chmod 640 /etc/nginx/snippets/rackula-api-token.conf
msg_ok "Set up Rackula"

msg_info "Configuring nginx"
cp /opt/rackula/config/nginx.conf /etc/nginx/sites-available/rackula
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/rackula /etc/nginx/sites-enabled/rackula
$STD nginx -t
msg_ok "Configured nginx"

msg_info "Creating Services"
cp /opt/rackula/config/rackula-api.service /etc/systemd/system/rackula-api.service
if grep -q '^User=' /etc/systemd/system/rackula-api.service; then
  sed -i 's/^User=.*/User=root/' /etc/systemd/system/rackula-api.service
else
  sed -i '/^\[Service\]/a User=root' /etc/systemd/system/rackula-api.service
fi
if grep -q '^Group=' /etc/systemd/system/rackula-api.service; then
  sed -i 's/^Group=.*/Group=root/' /etc/systemd/system/rackula-api.service
else
  sed -i '/^\[Service\]/a Group=root' /etc/systemd/system/rackula-api.service
fi
mkdir -p /etc/systemd/system/nginx.service.d
cp /opt/rackula/config/nginx.service.d-override.conf /etc/systemd/system/nginx.service.d/override.conf
systemctl daemon-reload
systemctl enable -q nginx rackula-api
systemctl restart nginx rackula-api
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
