#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Kristian Skov
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get update
$STD apt-get install -y \
  ssh \
  software-properties-common
$STD add-apt-repository -y ppa:dotnet/backports
$STD apt-get install -y \
  dotnet-sdk-9.0 \
  vsftpd \
  nginx
msg_ok "Installed Dependencies"

msg_info "Configure Application"
var_project_name="default"
read -r -p "Type the assembly name of the project: " var_project_name
echo "Target assembly: '${var_project_name}'"
msg_ok "Application Configured"

msg_info "Setting up FTP Server"
useradd ftpuser
FTP_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
usermod --password $(echo ${FTP_PASS} | openssl passwd -1 -stdin) ftpuser
mkdir -p /var/www/html
usermod -d /var/www/html ftp
usermod -d /var/www/html ftpuser 
chown ftpuser /var/www/html

sed -i "s|#write_enable=YES|write_enable=YES|g" /etc/vsftpd.conf
sed -i "s|#chroot_local_user=YES|chroot_local_user=NO|g" /etc/vsftpd.conf

systemctl restart -q vsftpd.service

{
    echo "FTP-Credentials"
    echo "Username: ftpuser"
    echo "Password: $FTP_PASS"
} >> ~/ftp.creds

msg_ok "FTP server setup completed"

msg_info "Setting up Nginx Server"
rm -f /var/www/html/index.nginx-debian.html

sed "s/\$var_project_name/$var_project_name/g" >myfile <<'EOF' >/etc/nginx/sites-available/default
map $http_connection $connection_upgrade {
  "~*Upgrade" $http_connection;
  default keep-alive;
}
server {
  listen        80;
  server_name   $var_project_name.com *.$var_project_name.com;
  location / {
      proxy_pass         http://127.0.0.1:5000/;
      proxy_http_version 1.1;
      proxy_set_header   Upgrade $http_upgrade;
      proxy_set_header   Connection $connection_upgrade;
      proxy_set_header   Host $host;
      proxy_cache_bypass $http_upgrade;
      proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header   X-Forwarded-Proto $scheme;
  }
}
EOF
systemctl reload nginx
msg_ok "Nginx Server Created"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/kestrel-aspnetapi.service
[Unit]
Description=.NET Web API App running on Linux

[Service]
WorkingDirectory=/var/www/html
ExecStart=/usr/bin/dotnet /var/www/html/$var_project_name.dll
Restart=always
# Restart service after 10 seconds if the dotnet service crashes:
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=dotnet-${var_project_name}
User=root
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_NOLOGO=true

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now kestrel-aspnetapi.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
