#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.plex.tv/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_hwaccel

msg_info "Setting Up Plex Media Server Repository"
curl -fsSL https://downloads.plex.tv/plex-keys/PlexSign.key | tee /usr/share/keyrings/PlexSign.asc >/dev/null
cat <<EOF >/etc/apt/sources.list.d/plexmediaserver.sources
Types: deb
URIs: https://downloads.plex.tv/repo/deb/
Suites: public
Components: main
Signed-By: /usr/share/keyrings/PlexSign.asc
EOF
msg_ok "Set Up Plex Media Server Repository"

msg_info "Installing Plex Media Server"
$STD apt update
$STD apt -o Dpkg::Options::="--force-confold" install -y plexmediaserver
if [[ "$CTTYPE" == "0" ]]; then
  sed -i -e 's/^ssl-cert:x:104:plex$/render:x:104:root,plex/' -e 's/^render:x:108:root$/ssl-cert:x:108:plex/' /etc/group
else
  sed -i -e 's/^ssl-cert:x:104:plex$/render:x:104:plex/' -e 's/^render:x:108:$/ssl-cert:x:108:/' /etc/group
fi
msg_ok "Installed Plex Media Server"

motd_ssh
customize
cleanup_lxc
