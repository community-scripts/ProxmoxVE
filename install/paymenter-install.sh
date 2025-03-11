#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Nícolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.paymenter.org

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
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
    git \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    php8.2 \
    php8.2-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} \
    mariadb-server \
    nginx \
    redis-server
$STD curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
msg_ok "Installed Dependencies"

msg_info "Installing Paymenter"
RELEASE=$(curl -s https://api.github.com/repos/paymenter/paymenter/releases/latest | grep '"tag_name"' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
mkdir -p /opt/paymenter
cd /opt/paymenter
wget -q "https://github.com/paymenter/paymenter/releases/download/${RELEASE}/paymenter.tar.gz"
$STD tar -xzvf paymenter.tar.gz
chmod -R 755 storage/* bootstrap/cache/
msg_ok "Installed Paymenter"

msg_info "Setting up database"
DB_NAME=paymenter
DB_USER=paymenter
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql mysql
mysql -u root -e "CREATE DATABASE $DB_NAME;"
mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' WITH GRANT OPTION;"
{
    echo "Paymenter Database Credentials"
    echo "Database: $DB_NAME"
    echo "Username: $DB_USER"
    echo "Password: $DB_PASS"
} >> ~/paymenter_db.creds
cp .env.example .env
$STD composer install --no-dev --optimize-autoloader --no-interaction
$STD php artisan key:generate --force
$STD php artisan storage:link
sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${DB_NAME}/" .env
sed -i "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USER}/" .env
sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASS}/" .env
$STD php artisan migrate --force --seed
msg_ok "Set up database"

msg_info "Creating Admin User"
$STD php artisan p:user:create <<EOF
admin@paymenter.org
paymenter
admin
paymenter
0
EOF
msg_ok "Created Admin User"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/paymenter.conf
server {
    listen 80;
    listen [::]:80;
    server_name localhost;
    root /opt/paymenter/public;

    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
ln -s /etc/nginx/sites-available/paymenter.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
$STD systemctl reload nginx
chown -R www-data:www-data /opt/paymenter/*
msg_ok "Configured Nginx"

msg_info "Setting up Cronjob"
echo "* * * * * php /opt/paymenter/artisan schedule:run >> /dev/null 2>&1" | crontab -
msg_ok "Setup Cronjob"

msg_info "Setting up Service"
cat <<EOF >/etc/systemd/system/paymenter.service
[Unit]
Description=Paymenter Queue Worker

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /opt/paymenter/artisan queue:work
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
$STD systemctl enable --now paymenter.service
msg_ok "Setup Service"

msg_info "Cleaning up"
rm -rf /opt/paymenter/paymenter.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize
