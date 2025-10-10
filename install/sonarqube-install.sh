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

msg_info "Installing Postgresql"
DB_NAME="sonarqube"
DB_USER="sonarqube"
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
$STD sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
{
  echo "Application Credentials"
  echo "DB_NAME: $DB_NAME"
  echo "DB_USER: $DB_USER"
  echo "DB_PASS: $DB_PASS"
} >>~/sonarqube.creds
msg_ok "Installed PostgreSQL"

msg_info "Configuring SonarQube"
temp_file=$(mktemp)
RELEASE=$(curl -fsSL https://api.github.com/repos/SonarSource/sonarqube/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
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

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
