#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wger-project/wger

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
  git \
  gnupg \
  apache2 \
  libapache2-mod-wsgi-py3
msg_ok "Installed Dependencies"

msg_info "Installing Python"
$STD apt-get install -y python3-pip
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
msg_ok "Installed Python"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install -g yarn sass
msg_ok "Installed Node.js"

msg_info "Setting up wger"
$STD adduser wger --disabled-password --gecos ""
mkdir /home/wger/db
touch /home/wger/db/database.sqlite
chown :www-data -R /home/wger/db
chmod g+w /home/wger/db /home/wger/db/database.sqlite
mkdir /home/wger/{static,media}
chmod o+w /home/wger/media
temp_dir=$(mktemp -d)
cd $temp_dir
RELEASE=$(curl -s https://api.github.com/repos/wger-project/wger/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')
wget -q "https://github.com/wger-project/wger/archive/refs/tags/$RELEASE.tar.gz"
tar xzf $RELEASE.tar.gz
mv wger-$RELEASE /home/wger/src
cd /home/wger/src
$STD pip install -r requirements_prod.txt
$STD pip install -e .
$STD wger create-settings --database-path /home/wger/db/database.sqlite
sed -i "s#home/wger/src/media#home/wger/media#g" /home/wger/src/settings.py
sed -i "/MEDIA_ROOT = '\/home\/wger\/media'/a STATIC_ROOT = '/home/wger/static'" /home/wger/src/settings.py
$STD wger bootstrap
$STD python3 manage.py collectstatic
echo "${RELEASE}" >/opt/wger_version.txt
msg_ok "Finished setting up wger"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/wger.conf
<Directory /home/wger/src>
    <Files wsgi.py>
        Require all granted
    </Files>
</Directory>

<VirtualHost *:80>
    WSGIApplicationGroup %{GLOBAL}
    WSGIDaemonProcess wger python-path=/home/wger/src python-home=/home/wger
    WSGIProcessGroup wger
    WSGIScriptAlias / /home/wger/src/wger/wsgi.py
    WSGIPassAuthorization On

    Alias /static/ /home/wger/static/
    <Directory /home/wger/static>
        Require all granted
    </Directory>

    Alias /media/ /home/wger/media/
    <Directory /home/wger/media>
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/wger-error.log
    CustomLog /var/log/apache2/wger-access.log combined
</VirtualHost>
EOF
$STD a2dissite 000-default.conf
$STD a2ensite wger
systemctl restart apache2
cat <<EOF >/etc/systemd/system/wger.service
[Unit]
Description=wger Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/wger start -a 0.0.0.0 -p 3000
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wger
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf $temp_dir
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize
