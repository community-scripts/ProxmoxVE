#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://opencloud.eu

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

MAX_ATTEMPTS=3
servers=("opencloud" "collabora" "wopi")
attempt=0
for server in "${servers[@]}"; do
  until ((attempt >= MAX_ATTEMPTS)); do
    attempt=$((attempt + 1))
    read -rp "${TAB3}Enter the FQDN of your ${server^} server (ATTEMPT $attempt/$MAX_ATTEMPTS) (eg $server.domain.tld): " fqdn
    if [[ -z "$fqdn" ]]; then
      msg_warn "Domain cannot be empty!"
    elif [[ "$fqdn" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      msg_warn "IP address not allowed! Please use a FQDN"
    elif [[ "$fqdn" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ ]]; then
      export ${server^^}_FQDN="$fqdn"
      attempt=0
      break
    else
      msg_warn "Invalid domain format!"
    fi
  done
  if ((attempt >= MAX_ATTEMPTS)); then
    msg_error "No more attempts - aborting script!"
    exit 1
  fi
done

msg_info "Installing Collabora Online"
curl -fsSL https://collaboraoffice.com/downloads/gpg/collaboraonline-release-keyring.gpg -o /etc/apt/keyrings/collaboraonline-release-keyring.gpg
cat <<EOF >/etc/apt/sources.list.d/colloboraonline.sources
Types: deb
URIs: https://www.collaboraoffice.com/repos/CollaboraOnline/CODE-deb
Suites: ./
Signed-By: /etc/apt/keyrings/collaboraonline-release-keyring.gpg
EOF
$STD apt-get update
$STD apt-get install -y coolwsd code-brand
systemctl stop coolwsd
mkdir -p /etc/systemd/system/coolwsd.service.d
cat <<EOF >/etc/systemd/system/coolwsd.service.d/override.conf
[Unit]
Before=opencloud-wopi.service
EOF
systemctl daemon-reload
COOLPASS="$(openssl rand -base64 36)"
$STD sudo -u cool coolconfig set-admin-password --user=admin --password="$COOLPASS"
echo "$COOLPASS" >~/.coolpass
msg_ok "Installed Collabora Online"

fetch_and_deploy_gh_release "opencloud" "opencloud-eu/opencloud" "singlefile" "v5.0.2" "/usr/bin" "opencloud-*-linux-amd64"

msg_info "Configuring OpenCloud"
DATA_DIR="/var/lib/opencloud"
CONFIG_DIR="/etc/opencloud"
ENV_FILE="${CONFIG_DIR}/opencloud.env"
mkdir -p "$DATA_DIR" "$CONFIG_DIR"/web/assets/{apps,themes}

curl -fsSL https://raw.githubusercontent.com/opencloud-eu/opencloud-compose/refs/heads/main/config/opencloud/csp.yaml -o "$CONFIG_DIR"/csp.yaml
curl -fsSL https://raw.githubusercontent.com/opencloud-eu/opencloud-compose/refs/heads/main/config/opencloud/proxy.yaml -o "$CONFIG_DIR"/proxy.yaml.bak

cat <<EOF >"$ENV_FILE"
OC_URL=https://${OPENCLOUD_FQDN}
OC_INSECURE=false
IDM_CREATE_DEMO_USERS=false
OC_LOG_LEVEL=warning
OC_CONFIG_DIR=${CONFIG_DIR}
OC_BASE_DATA_PATH=${DATA_DIR}
STORAGE_SYSTEM_OC_ROOT=${DATA_DIR}/storage/metadata

## Web
WEB_ASSET_CORE_PATH=${CONFIG_DIR}/web/assets
WEB_ASSET_APPS_PATH=${CONFIG_DIR}/web/assets/apps
WEB_ASSET_THEMES_PATH=${CONFIG_DIR}/web/assets/themes
# WEB_UI_THEME_PATH=
## Uncomment below to create & modify your web UI config
# WEB_UI_CONFIG_FILE=${CONFIG_DIR}/web/config.json

## Frontend
FRONTEND_DISABLE_RADICALE=true
FRONTEND_GROUPWARE_ENABLED=false
GRAPH_INCLUDE_OCM_SHAREES=true

## Proxy
PROXY_TLS=false
PROXY_CSP_CONFIG_FILE_LOCATION=${CONFIG_DIR}/csp.yaml

## Collaboration - requires VALID TLS
COLLABORA_DOMAIN=${COLLABORA_FQDN}
COLLABORATION_APP_NAME="CollaboraOnline"
COLLABORATION_APP_PRODUCT="Collabora"
COLLABORATION_APP_ADDR=https://${COLLABORA_FQDN}
COLLABORATION_APP_INSECURE=false
COLLABORATION_HTTP_ADDR=0.0.0.0:9300
COLLABORATION_WOPI_SRC=https://${WOPI_FQDN}
COLLABORATION_JWT_SECRET=

## Notifications - Email settings
# NOTIFICATIONS_SMTP_HOST=
# NOTIFICATIONS_SMTP_PORT=
# NOTIFICATIONS_SMTP_SENDER=
# NOTIFICATIONS_SMTP_USERNAME=
# NOTIFICATIONS_SMTP_PASSWORD=
# NOTIFICATIONS_SMTP_AUTHENTICATION=login
## Encryption method. Possible values are 'starttls', 'ssltls' and 'none'
# NOTIFICATIONS_SMTP_ENCRYPTION=starttls
## Allow insecure connections. Defaults to false.
# NOTIFICATIONS_SMTP_INSECURE=false

## Start additional services at runtime
## Examples: notifications, antivirus etc.
## Do not uncomment unless configured above.
# OC_ADD_RUN_SERVICES="notifications"

## OpenID - via web browser
## uncomment for OpenID in general
# OC_EXCLUDE_RUN_SERVICES=idp
# OC_OIDC_ISSUER=<your auth URL>
# IDP_DOMAIN=<your auth URL>
# PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD=none
# PROXY_OIDC_REWRITE_WELLKNOWN=true
# PROXY_USER_OIDC_CLAIM=preferred_username
# PROXY_USER_CS3_CLAIM=username
## automatically create accounts
# PROXY_AUTOPROVISION_ACCOUNTS=true
# WEB_OIDC_SCOPE=openid profile email groups
# GRAPH_ASSIGN_DEFAULT_USER_ROLE=false
#
## uncomment below if using PocketID
# WEB_OIDC_CLIENT_ID=<generated in PocketID>
# WEB_OIDC_METADATA_URL=<your auth URL>/.well-known/openid-configuration

## Full Text Search - Apache Tika
## Requires a separate install of Tika - see https://community-scripts.github.io/ProxmoxVE/scripts?id=apache-tika
# SEARCH_EXTRACTOR_TYPE=tika
# FRONTEND_FULL_TEXT_SEARCH_ENABLED=true
# SEARCH_EXTRACTOR_TIKA_TIKA_URL=<your-tika-url>

## External storage test - Only NFS v4.2+ is supported
## User files
# STORAGE_USERS_POSIX_ROOT=<path-to-your-bind_mount>
EOF

cat <<EOF >/etc/systemd/system/opencloud.service
[Unit]
Description=OpenCloud server
After=network-online.target

[Service]
Type=simple
User=opencloud
Group=opencloud
EnvironmentFile=${ENV_FILE}
ExecStart=/usr/bin/opencloud server
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/opencloud-wopi.service
[Unit]
Description=OpenCloud WOPI Server
Wants=coolwsd.service
After=opencloud.service coolwsd.service

[Service]
Type=simple
User=opencloud
Group=opencloud
EnvironmentFile=${ENV_FILE}
ExecStartPre=/bin/sleep 10
ExecStart=/usr/bin/opencloud collaboration server
Restart=always
KillSignal=SIGKILL
KillMode=mixed
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
EOF

$STD sudo -u cool coolconfig set ssl.enable false
$STD sudo -u cool coolconfig set ssl.termination true
$STD sudo -u cool coolconfig set ssl.ssl_verification true
sed -i "s|-Policy\">|&frame-ancestors https://${OPENCLOUD_FQDN}|" /etc/coolwsd/coolwsd.xml
useradd -r -M -s /usr/sbin/nologin opencloud
chown -R opencloud:opencloud "$CONFIG_DIR" "$DATA_DIR"
sudo -u opencloud opencloud init --config-path "$CONFIG_DIR" --insecure no
OPENCLOUD_SECRET="$(sed -n '/jwt/p' "$CONFIG_DIR"/opencloud.yaml | awk '{print $2}')"
sed -i "s/JWT_SECRET=/&${OPENCLOUD_SECRET//&/\\&}/" "$ENV_FILE"
msg_ok "Configured OpenCloud"

msg_info "Starting services"
systemctl enable -q --now coolwsd opencloud
sleep 5
systemctl enable -q --now opencloud-wopi
msg_ok "Started services"

motd_ssh
customize
cleanup_lxc
