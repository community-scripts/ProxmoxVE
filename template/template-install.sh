#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: community-scripts ORG
# CO-Author: EnterYourUsernameHere
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Installing Dependencies, these 3 dependencies are our core dependencies and should always be present! 
# All others are supplemented with \ 
msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y \
  curl \
  sudo \
  mc
msg_ok "Installed Dependencies"
# More Examples:
#  php8.2-{bz2,curl,fpm,gd,imagick,intl,ldap,mbstring,mysql,sqlite3,tidy,xml,zip} (not all needed, just an example!)
#  composer 
#  libapache2-mod-php 
#  apache2 
#  python3 
#  cmake 
#  g++ 
#  build-essential 
# _______________________________________________________________________________________________________________________________________________

# Now an example of how the NodeJS installation should always look:
# Info: If you use NodeJS, then add "ca-certificates" and "gpupg" to Installing Dependencies
msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
# Optionally you can add other package managers here (e.g. Yarn, PNPM..)
# $STD npm install -g yarn
# $STD npm install -g pnpm
msg_ok "Installed Node.js"
# _______________________________________________________________________________________________________________________________________________

# Setting up Postgresql:
# Add "postgresql" in Installing Dependencies
msg_info "Setting up PostgreSQL"
DB_NAME=project_db
DB_USER=projectuser
DB_PASS="$(openssl rand -base64 18 | cut -c1-13)"
PROJECT_SECRET="$(openssl rand -base64 32 | cut -c1-24)" # if needed
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
$STD sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" 
$STD sudo -u postgres psql -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"
$STD sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"
{
    echo "ProjectName-Credentials"
    echo "ProjectName Database User: $DB_USER"
    echo "ProjectName Database Password: $DB_PASS"
    echo "ProjectName Database Name: $DB_NAME"
    echo "ProjectName Secret: $PROJECT_SECRET"
} >> ~/projectname.creds
msg_ok "Set up PostgreSQL"
# _______________________________________________________________________________________________________________________________________________

# Setting up Mysql-DB (MariaDB):
# Add "mariadb-server" in Installing Dependencies
msg_info "Setting up MariaDB"
DB_NAME=project_db
DB_USER=projectuser
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
PROJECT_SECRET="$(openssl rand -base64 32 | cut -c1-24)" # if needed
$STD sudo mysql -u root -e "CREATE DATABASE $DB_NAME;"
$STD sudo mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password AS PASSWORD('$DB_PASS');"
$STD sudo mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
    echo "ProjectName-Credentials"
    echo "ProjectName Database User: $DB_USER"
    echo "ProjectName Database Password: $DB_PASS"
    echo "ProjectName Database Name: $DB_NAME"
    echo "ProjectName Secret: $PROJECT_SECRET"
} >> ~/projectname.creds
msg_ok "Set up MariaDB"
# _______________________________________________________________________________________________________________________________________________

msg_info "Setup ProjectName (Patience)"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/project_user/project_folder/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/project_user/project_folder/archive/refs/tags/v${RELEASE}.zip"
unzip -q v${RELEASE}.zip
mv ProjectName-${RELEASE} /opt/projectname
cd /opt/projectname

# if you need to change an .env, please use sed -i, for example:
cp .env.example .env
sudo sed -i \
    -e "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" \
    -e "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" \
    -e "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" \
    /opt/projectname/.env
	
# Rest of build code
# Rest of build code
# Rest of build code

echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed ProjectName"

msg_info "Creating Service"
# Service as Apache2, Php, Python3, and so on.
# There is no uniform standard for this. Ideally, it is described in the original project, otherwise here are some examples:

# Apache2 (Grocy Example): https://github.com/community-scripts/ProxmoxVE/blob/c229c9cb4a4a3059e9a1343923fe1fbe7ea3b476/install/grocy-install.sh#L44-L61
# start.sh (Open WebUI Example): https://github.com/community-scripts/ProxmoxVE/blob/c229c9cb4a4a3059e9a1343923fe1fbe7ea3b476/install/openwebui-install.sh#L86-L102
# Javascript (Node/NPM/Yarn): https://github.com/community-scripts/ProxmoxVE/blob/c229c9cb4a4a3059e9a1343923fe1fbe7ea3b476/install/tianji-install.sh#L83-L101
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/v${RELEASE}.zip
$STD apt-get autoremove
$STD apt-get autoclean
msg_ok "Cleaned"