#!/usr/bin/env bash
# Copyright (c) 2021-2025 community-scripts ORG
# Author: prop4n
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.sonarsource.com/sonarqube-server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

JAVA_VERSION="21" setup_java
PG_VERSION="17" setup_postgresql
PG_DB_NAME="sonarqube" PG_DB_USER="sonarqube" setup_postgresql_db

msg_info "Setting up SonarQube"
temp_file=$(mktemp)
RELEASE=$(get_latest_github_release "SonarSource/sonarqube")
curl -fsSL "https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${RELEASE}.zip" -o $temp_file
unzip -q "$temp_file" -d /opt
mv /opt/sonarqube-* /opt/sonarqube
$STD useradd -r -m -U -d /opt/sonarqube -s /bin/bash sonarqube
chown -R sonarqube:sonarqube /opt/sonarqube
chmod -R 755 /opt/sonarqube
mkdir -p /opt/sonarqube/conf
cat <<EOF >/opt/sonarqube/conf/sonar.properties
sonar.jdbc.username=${DB_USER}
sonar.jdbc.password=${DB_PASS}
sonar.jdbc.url=jdbc:postgresql://localhost/${DB_NAME}
sonar.web.host=0.0.0.0
sonar.web.port=9000
EOF
chmod +x /opt/sonarqube/bin/linux-x86-64/sonar.sh
echo ${RELEASE} >>~/.sonarqube
msg_ok "Configured SonarQube"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube service
After=postgresql.service

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonarqube
Group=sonarqube
Restart=on-failure
LimitNOFILE=131072
LimitNPROC=8192

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now sonarqube
msg_ok "Service Created"

motd_ssh
customize
cleanup_lxc
