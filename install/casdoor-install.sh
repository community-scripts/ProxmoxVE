#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/casdoor/casdoor

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PG_VERSION="17" setup_postgresql
PG_DB_NAME="casdoor" PG_DB_USER="casdoor" setup_postgresql_db

fetch_and_deploy_gh_release "casdoor" "casdoor/casdoor" "prebuild" "latest" "/opt/casdoor" "casdoor_Linux_$(arch_resolve "x86_64" "arm64").tar.gz"

msg_info "Configuring Casdoor"
mkdir -p /opt/casdoor_data/conf
cat <<EOF >/opt/casdoor_data/conf/app.conf
appname = casdoor
httpport = 8000
runmode = prod
copyrequestbody = true
driverName = postgres
dataSourceName = user=casdoor password=${PG_DB_PASS} host=localhost port=5432 sslmode=disable dbname=casdoor
dbName = casdoor
tableNamePrefix =
showSql = false
redisEndpoint =
defaultStorageProvider =
isCloudIntranet = false
authState = "casdoor"
socks5Proxy =
verificationCodeTimeout = 10
initScore = 0
logPostOnly = true
isUsernameLowered = false
origin = http://${LOCAL_IP}:8000
originFrontend =
staticBaseUrl = "https://cdn.casbin.org"
isDemoMode = false
batchSize = 100
showGithubCorner = false
forceLanguage = ""
defaultLanguage = "en"
defaultApplication = "app-built-in"
maxItemsForFlatMenu = 7
enableErrorMask = false
enableGzip = true
inactiveTimeoutMinutes =
ldapServerPort = 389
ldapsCertId = ""
ldapsServerPort = 636
radiusServerPort = 1812
radiusDefaultOrganization = "built-in"
radiusSecret = "$(random_password)"
quota = {"organization": -1, "user": -1, "application": -1, "provider": -1}
logConfig = {"adapter":"console", "color":false}
initDataNewOnly = false
initDataFile = "./init_data.json"
frontendBaseDir = "/opt/casdoor/web/build"
EOF
chmod 600 /opt/casdoor_data/conf/app.conf
msg_ok "Configured Casdoor"

msg_info "Creating Service"
# Casdoor resolves conf/app.conf, files/ (uploads) and tmp/ (sessions) against its working directory
cat <<EOF >/etc/systemd/system/casdoor.service
[Unit]
Description=Casdoor
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/casdoor_data
ExecStart=/opt/casdoor/casdoor
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now casdoor
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
