#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: elvito
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/PCJones/UmlautAdaptarr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD curl -fsSL https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -o packages-microsoft-prod.deb
$STD dpkg -i packages-microsoft-prod.deb
$STD apt-get update
$STD apt-get install -y \
  dotnet-sdk-8.0 \
  aspnetcore-runtime-8.0
msg_ok "Installed Dependencies"

msg_info "Installing Umlautadaptarr"
temp_file=$(mktemp)
RELEASE=$(curl -s https://api.github.com/repos/PCJones/Umlautadaptarr/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')
curl -fsSL "https://github.com/PCJones/Umlautadaptarr/releases/download/${RELEASE}/linux-x64.zip" -o $temp_file
$STD unzip -j $temp_file '*/**' -d /opt/UmlautAdaptarr
echo "${RELEASE}" >"/opt/UmlautAdaptarr_version.txt"
msg_ok "Installation completed"

msg_info "Creating appsettings.json"
cat <<EOF >/opt/UmlautAdaptarr/appsettings.json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    },
    "Console": {
      "TimestampFormat": "yyyy-MM-dd HH:mm:ss::"
    }
  },
  "AllowedHosts": "*",
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://[::]:5005"
      }
    }
  },
  "Settings": {
    "UserAgent": "UmlautAdaptarr/1.0",
    "UmlautAdaptarrApiHost": "https://umlautadaptarr.pcjones.de/api/v1",
    "IndexerRequestsCacheDurationInMinutes": 12
  },
  "Sonarr": [
    {
      "Enabled": false,
      "Name": "Sonarr",
      "Host": "http://192.168.1.100:8989",
      "ApiKey": "dein_sonarr_api_key"
    }
  ],
  "Radarr": [
    {
      "Enabled": false,
      "Name": "Radarr",
      "Host": "http://192.168.1.101:7878",
      "ApiKey": "dein_radarr_api_key"
    }
  ],
  "Lidarr": [
  {
    "Enabled": false,
    "Host": "http://192.168.1.102:8686",
    "ApiKey": "dein_lidarr_api_key"
  },
 ],
  "Readarr": [
  {
    "Enabled": false,
    "Host": "http://192.168.1.103:8787",
    "ApiKey": "dein_readarr_api_key"
  },
 ],
  "IpLeakTest": {
    "Enabled": false
  }
}
EOF
msg_ok "appsettings.json created"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/umlautadaptarr.service
[Unit]
Description=UmlautAdaptarr Service
After=network.target

[Service]
WorkingDirectory=/opt/UmlautAdaptarr
ExecStart=/usr/bin/dotnet /opt/UmlautAdaptarr/UmlautAdaptarr.dll --urls=http://0.0.0.0:5005
Restart=always
User=root
Group=root
Environment=ASPNETCORE_ENVIRONMENT=Production

[Install]
WantedBy=multi-user.target
EOF
systemctl -q --now enable umlautadaptarr
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f $temp_file
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
