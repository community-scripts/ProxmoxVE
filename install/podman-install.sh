#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://podman.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PORTAINER_LATEST_VERSION=$(get_latest_github_release "portainer/portainer")
PORTAINER_AGENT_LATEST_VERSION=$(get_latest_github_release "portainer/agent")

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
$STD apt install -y podman
systemctl enable -q --now podman.socket
echo -e 'unqualified-search-registries=["docker.io"]' >>/etc/containers/registries.conf
msg_ok "Installed Podman"

mkdir -p /etc/containers/systemd

read -r -p "${TAB3}Would you like to add Portainer? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Installing Portainer $PORTAINER_LATEST_VERSION"
  podman volume create portainer_data >/dev/null
  cat <<EOF >/etc/containers/systemd/portainer.container
[Unit]
Description=Portainer Container
After=network-online.target

[Container]
Image=docker.io/portainer/portainer-ce:latest
ContainerName=portainer
PublishPort=8000:8000
PublishPort=9443:9443
Volume=/run/podman/podman.sock:/var/run/docker.sock
Volume=portainer_data:/data

[Service]
Restart=always

[Install]
WantedBy=default.target multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable -q --now portainer
  msg_ok "Installed Portainer $PORTAINER_LATEST_VERSION"
else
  read -r -p "${TAB3}Would you like to add the Portainer Agent? <y/N> " prompt
  if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
    msg_info "Installing Portainer agent $PORTAINER_AGENT_LATEST_VERSION"
    cat <<EOF >/etc/containers/systemd/portainer-agent.container
[Unit]
Description=Portainer Agent Container
After=network-online.target

[Container]
Image=docker.io/portainer/agent:latest
ContainerName=portainer_agent
PublishPort=9001:9001
Volume=/run/podman/podman.sock:/var/run/docker.sock
Volume=/var/lib/containers/storage/volumes:/var/lib/docker/volumes

[Service]
Restart=always

[Install]
WantedBy=default.target multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable -q --now portainer-agent
    msg_ok "Installed Portainer Agent $PORTAINER_AGENT_LATEST_VERSION"
  fi
fi

motd_ssh
customize
cleanup_lxc
