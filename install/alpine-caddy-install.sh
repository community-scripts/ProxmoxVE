#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: cobalt (cobaltgit)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://caddyserver.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Caddy"
$STD apk add --no-cache caddy caddy-openrc
cat <<EOF >/etc/caddy/Caddyfile
:80 {
        # Set this path to your site's directory.
        root * /var/www/html

        # Enable the static file server.
        file_server

        # Another common task is to set up a reverse proxy:
        # reverse_proxy localhost:8080

        # Or serve a PHP site through php-fpm:
        # php_fastcgi localhost:9000
}
EOF
mkdir -p /var/www/html
cat <<EOF >/var/www/html/index.html
<!DOCTYPE html>
<html>
  <head>
    <title>Caddy works!</title>
  </head>
  <body>
    <h1>Hello Caddy!</h1>
    <p>For more information, refer to the Caddy <a href="https://caddyserver.com/docs/">documentation</a><p>
  </body>
</html>
EOF
msg_ok "Installed Caddy"

read -r -p "${TAB3}Would you like to install xCaddy Addon? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  GO_VERSION="$(curl -fsSL https://go.dev/VERSION?m=text | head -1 | cut -c3-)" setup_go
  msg_info "Setup xCaddy"
  cd /opt
  RELEASE=$(curl -fsSL https://api.github.com/repos/caddyserver/xcaddy/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  curl -fsSL "https://github.com/caddyserver/xcaddy/releases/download/${RELEASE}/xcaddy_${RELEASE:1}_linux_amd64.tar.gz" -o "xcaddy_${RELEASE:1}_linux_amd64.tar.gz"
  $STD tar xzf xcaddy_"${RELEASE:1}"_linux_amd64.tar.gz -C /usr/local/bin xcaddy
  rm -rf /opt/xcaddy*
  $STD xcaddy build
  msg_ok "Setup xCaddy"
fi

msg_info "Enabling Caddy Service"
$STD rc-update add caddy default
msg_ok "Enabled Caddy Service"

msg_info "Starting Caddy"
$STD service caddy start
msg_ok "Started Caddy"

motd_ssh
customize
