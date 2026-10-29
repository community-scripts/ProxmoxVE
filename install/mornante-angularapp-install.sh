#!/usr/bin/env bash

# Copyright (c) 2021-2026 Mornante ORG
# Author: Kristian Skov
# License: MIT | https://github.com/Mornante/ProxmoxVE/raw/main/LICENSE
# Source: https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/linux-nginx?view=aspnetcore-9.0&tabs=linux-ubuntu

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
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
  nodejs \
  npm \
  vsftpd \
  nginx
msg_ok "Installed Dependencies"

msg_info "Installing Angular CLI"
$STD npm install -g @angular/cli
msg_ok "Installed Angular CLI"

var_project_name="default"
read -r -p "${TAB3}Type the name of the Angular project: " var_project_name

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
} >>~/ftp.creds

msg_ok "FTP server setup completed"

msg_info "Setting up Nginx Server"
rm -f /var/www/html/index.nginx-debian.html

cat >/etc/nginx/sites-available/default <<EOF
server {
  listen        80;
  server_name   ${var_project_name}.com *.${var_project_name}.com;
  root          /var/www/html;
  index         index.html;
  location / {
      try_files \$uri \$uri/ /index.html;
  }
  location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
      expires 1y;
      add_header Cache-Control "public, immutable";
  }
}
EOF

systemctl reload nginx
msg_ok "Nginx Server Created"

msg_info "Creating Angular Service"
cat <<EOF >/etc/systemd/system/angular-${var_project_name}.service
[Unit]
Description=Angular App - ${var_project_name}
After=network.target
[Service]
WorkingDirectory=/var/www/html
ExecStart=/usr/bin/ng serve --host 0.0.0.0 --port 4200 --disable-host-check
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=angular-${var_project_name}
User=ftpuser
Environment=NODE_ENV=production
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now angular-${var_project_name}
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
