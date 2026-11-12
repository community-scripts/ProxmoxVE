#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Kristian Skov
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://learn.microsoft.com/en-us/dotnet/core/install/linux-debian

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  vsftpd \
  nginx
msg_ok "Installed Dependencies"

setup_deb822_repo \
  "microsoft" \
  "https://packages.microsoft.com/keys/microsoft-2025.asc" \
  "https://packages.microsoft.com/debian/13/prod/" \
  "trixie" \
  "main"

if [[ -z "${var_dotnet_version:-}" && -t 0 ]]; then
  read -r -t 60 -p "${TAB3}.NET SDK version, 10 (LTS) or 11 [10]: " var_dotnet_version || echo
fi
var_dotnet_version="${var_dotnet_version:-10}"
var_dotnet_version="${var_dotnet_version%%.*}"
if ! apt-cache show "dotnet-sdk-${var_dotnet_version}.0" &>/dev/null; then
  msg_warn ".NET SDK ${var_dotnet_version} is not available for this system, using 10"
  var_dotnet_version="10"
fi

if [[ -z "${var_project_name:-}" && -t 0 ]]; then
  read -r -t 60 -p "${TAB3}Assembly name of the project [testproject]: " var_project_name || echo
fi
var_project_name="${var_project_name:-testproject}"

msg_info "Installing .NET SDK ${var_dotnet_version}"
$STD apt install -y "dotnet-sdk-${var_dotnet_version}.0"
msg_ok "Installed .NET SDK ${var_dotnet_version}"

msg_info "Setting up FTP Server"
useradd ftpuser
FTP_PASS=$(random_password 13)
usermod --password $(echo ${FTP_PASS} | openssl passwd -1 -stdin) ftpuser
mkdir -p /var/www/html
usermod -d /var/www/html ftp
usermod -d /var/www/html ftpuser
chown ftpuser /var/www/html

sed -i "s|#write_enable=YES|write_enable=YES|g" /etc/vsftpd.conf
sed -i "s|#chroot_local_user=YES|chroot_local_user=NO|g" /etc/vsftpd.conf

systemctl restart -q vsftpd.service

cat <<EOF >~/ftp.creds
FTP-Credentials
Username: ftpuser
Password: $FTP_PASS
EOF

msg_ok "FTP server setup completed"

msg_info "Setting up Nginx Server"
rm -f /var/www/html/index.nginx-debian.html

sed "s/\$var_project_name/$var_project_name/g" <<'EOF' >/etc/nginx/sites-available/default
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
ConditionPathExists=/var/www/html/$var_project_name.dll

[Service]
WorkingDirectory=/var/www/html
ExecStart=/usr/bin/dotnet /var/www/html/$var_project_name.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=dotnet-${var_project_name}
User=root
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_NOLOGO=true

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/kestrel-aspnetapi.path
[Unit]
Description=Start the .NET Web API App once it is deployed

[Path]
PathExists=/var/www/html/$var_project_name.dll

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q kestrel-aspnetapi
systemctl enable -q --now kestrel-aspnetapi.path
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
