#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.docker.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

get_latest_release() {
  curl -fsSL https://api.github.com/repos/"$1"/releases/latest | grep '"tag_name":' | cut -d'"' -f4
}

DOCKER_LATEST_VERSION=$(get_latest_release "moby/moby")
PORTAINER_LATEST_VERSION=$(get_latest_release "portainer/portainer")
PORTAINER_AGENT_LATEST_VERSION=$(get_latest_release "portainer/agent")
DOCKER_COMPOSE_LATEST_VERSION=$(get_latest_release "docker/compose")

msg_info "Installing Docker $DOCKER_LATEST_VERSION"
DOCKER_CONFIG_PATH='/etc/docker/daemon.json'
mkdir -p $(dirname $DOCKER_CONFIG_PATH)
echo -e '{\n  "log-driver": "journald"\n}' >/etc/docker/daemon.json
$STD sh <(curl -fsSL https://get.docker.com)
msg_ok "Installed Docker $DOCKER_LATEST_VERSION"

read -r -p "${TAB3}Install Docker Compose v2 plugin? <y/N> " prompt_compose
if [[ ${prompt_compose,,} =~ ^(y|yes)$ ]]; then
  msg_info "Installing Docker Compose $DOCKER_COMPOSE_LATEST_VERSION"
  mkdir -p /usr/local/lib/docker/cli-plugins
  curl -fsSL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_LATEST_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
  msg_ok "Installed Docker Compose $DOCKER_COMPOSE_LATEST_VERSION"
fi

read -r -p "${TAB3}Would you like to add Portainer (UI)? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Installing Portainer $PORTAINER_LATEST_VERSION"
  docker volume create portainer_data >/dev/null
  $STD docker run -d \
    -p 8000:8000 \
    -p 9443:9443 \
    --name=portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest
  msg_ok "Installed Portainer $PORTAINER_LATEST_VERSION"
else
  read -r -p "${TAB3}Would you like to install the Portainer Agent (for remote management)? <y/N> " prompt_agent
  if [[ ${prompt_agent,,} =~ ^(y|yes)$ ]]; then
    msg_info "Installing Portainer Agent $PORTAINER_AGENT_LATEST_VERSION"
    $STD docker run -d \
      -p 9001:9001 \
      --name portainer_agent \
      --restart=always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v /var/lib/docker/volumes:/var/lib/docker/volumes \
      portainer/agent
    msg_ok "Installed Portainer Agent $PORTAINER_AGENT_LATEST_VERSION"
  fi
fi

read -r -p "${TAB3}Expose Docker TCP socket (insecure) ? [n = No, l = Local only (127.0.0.1), a = All interfaces (0.0.0.0)] <n/l/a>: " socket_choice
case "${socket_choice,,}" in
  l)
    socket="tcp://127.0.0.1:2375"
    ;;
  a)
    socket="tcp://0.0.0.0:2375"
    ;;
  *)
    socket=""
    ;;
esac

if [[ -n "$socket" ]]; then
  msg_info "Enabling Docker TCP socket on $socket"
  $STD apt-get install -y jq

  tmpfile=$(mktemp)
  jq --arg sock "$socket" '. + { "hosts": ["unix:///var/run/docker.sock", $sock] }' /etc/docker/daemon.json > "$tmpfile" && mv "$tmpfile" /etc/docker/daemon.json

  mkdir -p /etc/systemd/system/docker.service.d
  cat <<EOF > /etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
EOF

  $STD systemctl daemon-reexec
  $STD systemctl daemon-reload

  if systemctl restart docker; then
    msg_ok "Docker TCP socket available on $socket"
  else
    msg_error "Docker failed to restart. Check journalctl -xeu docker.service"
    exit 1
  fi
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
