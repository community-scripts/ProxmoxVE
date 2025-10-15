#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.home-assistant.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

get_latest_release() {
  curl -fsSL https://api.github.com/repos/$1/releases/latest | grep '"tag_name":' | cut -d'"' -f4
}

PORTAINER_LATEST_VERSION=$(get_latest_release "portainer/portainer")
PORTAINER_AGENT_LATEST_VERSION=$(get_latest_release "portainer/agent")

if $STD mount | grep 'on / type zfs' >null && echo "ZFS"; then
  msg_info "Enabling ZFS support."
  mkdir -p /etc/containers
  cat <<'EOF' >/usr/local/bin/overlayzfsmount
#!/bin/sh
exec /bin/mount -t overlay overlay "$@"
EOF
  chmod +x /usr/local/bin/overlayzfsmount
  cat <<'EOF' >/etc/containers/storage.conf
[storage]
driver = "overlay"
runroot = "/run/containers/storage"
graphroot = "/var/lib/containers/storage"

[storage.options]
pull_options = {enable_partial_images = "false", use_hard_links = "false", ostree_repos=""}
mount_program = "/usr/local/bin/overlayzfsmount"

[storage.options.overlay]
mountopt = "nodev"
EOF
fi

msg_info "Installing Podman"
$STD apt -y install podman
$STD systemctl enable --now podman.socket
echo -e 'unqualified-search-registries=["docker.io"]' >>/etc/containers/registries.conf
msg_ok "Installed Podman"

read -r -p "${TAB3}Would you like to add Portainer? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Installing Portainer $PORTAINER_LATEST_VERSION"
  podman volume create portainer_data >/dev/null
  $STD podman run -d \
    -p 8000:8000 \
    -p 9443:9443 \
    --name=portainer \
    --restart=always \
    -v /run/podman/podman.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest
  msg_ok "Installed Portainer $PORTAINER_LATEST_VERSION"
else
  read -r -p "${TAB3}Would you like to add the Portainer Agent? <y/N> " prompt
  if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
    msg_info "Installing Portainer agent $PORTAINER_AGENT_LATEST_VERSION"
    podman volume create temp >/dev/null
    podman volume remove temp >/dev/null
    $STD podman run -d \
      -p 9001:9001 \
      --name portainer_agent \
      --restart=always \
      -v /run/podman/podman.sock:/var/run/docker.sock \
      -v /var/lib/containers/storage/volumes:/var/lib/docker/volumes \
      portainer/agent
    msg_ok "Installed Portainer Agent $PORTAINER_AGENT_LATEST_VERSION"
  fi
fi

msg_info "Pulling Home Assistant Image"
$STD podman pull docker.io/homeassistant/home-assistant:stable
msg_ok "Pulled Home Assistant Image"

msg_info "Installing Home Assistant"
$STD podman volume create hass_config
$STD podman run -d \
  --name homeassistant \
  --restart unless-stopped \
  -v /dev:/dev \
  -v hass_config:/config \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  --net=host \
  homeassistant/home-assistant:stable
podman generate systemd \
  --new --name homeassistant \
  >/etc/systemd/system/homeassistant.service
$STD systemctl enable --now homeassistant
msg_ok "Installed Home Assistant"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
