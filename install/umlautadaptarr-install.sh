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
setup_deb822_repo \
  "microsoft" \
  "https://packages.microsoft.com/keys/microsoft.asc" \
  "https://packages.microsoft.com/debian/12/prod/" \
  "bookworm" \
  "main"
$STD apt install -y \
  dotnet-sdk-8.0 \
  aspnetcore-runtime-8.0
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "UmlautAdaptarr" "PCJones/Umlautadaptarr" "prebuild" "latest" "/opt/UmlautAdaptarr" "linux-x64.zip"

msg_info "Setting up UmlautAdaptarr"
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
msg_ok "Setup UmlautAdaptarr"

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
systemctl enable -q --now umlautadaptarr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
