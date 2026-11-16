#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ccfos/nightingale

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y redis-server
msg_ok "Installed Dependencies"

setup_mariadb
MARIADB_DB_NAME="nightingale" MARIADB_DB_USER="nightingale" setup_mariadb_db

fetch_and_deploy_gh_release "nightingale" "ccfos/nightingale" "prebuild" "latest" "/opt/nightingale" "n9e-v*-linux-$(arch_resolve).tar.gz"

msg_info "Configuring Nightingale"
mkdir -p /opt/nightingale_data
cat <<EOF >/opt/nightingale_data/config.toml
[Global]
RunMode = "release"

[Log]
Dir = "/opt/nightingale_data/logs"
Level = "INFO"
Output = "stdout"

[HTTP]
Host = "0.0.0.0"
Port = 17000
CertFile = ""
KeyFile = ""
PrintAccessLog = false
PProf = false
ExposeMetrics = true
ShutdownTimeout = 30
MaxContentLength = 67108864
ReadTimeout = 20
WriteTimeout = 40
IdleTimeout = 120

[HTTP.ShowCaptcha]
Enable = false

[HTTP.APIForAgent]
Enable = true

[HTTP.APIForService]
Enable = false

[HTTP.JWTAuth]
AccessExpired = 1500
RefreshExpired = 10080
RedisKeyPrefix = "/jwt/"

[HTTP.ProxyAuth]
Enable = false
HeaderUserNameKey = "X-User-Name"
DefaultRoles = ["Standard"]

[HTTP.TokenAuth]
Enable = true

[HTTP.RSA]
OpenRSA = false

[DB]
DBType = "mysql"
DSN = "nightingale:${MARIADB_DB_PASS}@tcp(127.0.0.1:3306)/nightingale?charset=utf8mb4&collation=utf8mb4_general_ci&parseTime=True&loc=Local&allowNativePasswords=true"
Debug = false
MaxLifetime = 7200
MaxOpenConns = 150
MaxIdleConns = 50

[Redis]
Address = "127.0.0.1:6379"
RedisType = "standalone"

[Alert]
[Alert.Heartbeat]
IP = ""
Interval = 1000
EngineName = "default"

[Alert.EvalLog]
MaxDiskGB = 1

[Center]
MetricsYamlFile = "/opt/nightingale/etc/metrics.yaml"
I18NHeaderKey = "X-Language"

[Center.AnonymousAccess]
PromQuerier = false
AlertDetail = true

[EmbeddedTSDB]
Enable = true
Dir = "/opt/nightingale_data/tsdb"
RetentionDuration = "15d"
MaxBytes = "4GiB"
OutOfOrderTimeWindow = "10m"
QueryTimeout = "1m"
QueryMaxSamples = 50000000
LookbackDelta = "5m"
BasicAuthUser = ""
BasicAuthPass = ""

[Pushgw]
LabelRewrite = true
ForceUseServerTS = true

[Ibex]
Enable = true
RPCListen = "0.0.0.0:20090"
EOF
chmod 600 /opt/nightingale_data/config.toml
msg_ok "Configured Nightingale"

msg_info "Creating Service"
# integrations/, agents/ and the AI skill cache resolve against the working directory, so it stays the release dir
cat <<EOF >/etc/systemd/system/nightingale.service
[Unit]
Description=Nightingale
After=network.target mariadb.service redis-server.service
Requires=mariadb.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/nightingale
ExecStart=/opt/nightingale/n9e --configs /opt/nightingale_data
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now nightingale
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
