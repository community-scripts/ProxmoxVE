#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dotnetfactory/fluid-calendar

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  zip \
  gnupg \
  postgresql-common
msg_ok "Installed Dependencies"

msg_info "Installing Additional Dependencies"
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
echo "YES" | /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh &>/dev/null
$STD apt-get install -y postgresql-17 nodejs
msg_ok "Installed Additional Dependencies"

msg_info "Setting up Postgresql Database"
DB_NAME="fluiddb"
DB_USER="fluiduser"
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)"
NEXTAUTH_SECRET="$(openssl rand -base64 44 | tr -dc 'a-zA-Z0-9' | cut -c1-32)"
$STD sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME to $DB_USER;"
$STD sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"
{
    echo "${APPLICATION} Credentials"
    echo "Database User: $DB_USER"
    echo "Database Password: $DB_PASS"
    echo "Database Name: $DB_NAME"
    echo "NextAuth Secret: $NEXTAUTH_SECRET"
} >> ~/$APPLICATION.creds
msg_ok "Set up Postgresql Database"

msg_info "Setup ${APPLICATION}"
tmp_file=$(mktemp)
RELEASE=$(curl -s https://api.github.com/repos/dotnetfactory/fluid-calendar/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/dotnetfactory/fluid-calendar/archive/refs/tags/v${RELEASE}.zip" -O $tmp_file
unzip -q $tmp_file
mv ${APPLICATION}-${RELEASE}/ /opt/${APPLICATION}
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt

cat <<EOF >/opt/fluid-calendar/.env
DATABASE_URL="postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}"

# For OAuth integration with Google Calendar
# See https://console.cloud.google.com
GOOGLE_CLIENT_ID=""
GOOGLE_CLIENT_SECRET=""

# Change the URL below to your external URL
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="${NEXTAUTH_SECRET}"

# For optional Outlook Calendar Integration
# Create at https://portal.azure.com
AZURE_AD_CLIENT_ID=""
AZURE_AD_CLIENT_SECRET=""
AZURE_AD_TENANT_ID=""

# Logging configuration
# Options: debug, none (check logger.js for more details)
LOG_LEVEL="none"
DEBUG_ENABLED=0
EOF
export NEXT_TELEMETRY_DISABLED=1
cd /opt/fluid-calendar
$STD npm run setup
$STD npm run build
msg_ok "Setup ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/fluid-calendar.service
[Unit]
Description=Fluid Calendar Application
After=network.target postgresql.service

[Service]
Restart=always
WorkingDirectory=/opt/fluid-calendar
ExecStart=/usr/bin/npm run start

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now fluid-calendar.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f $tmp_file
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
