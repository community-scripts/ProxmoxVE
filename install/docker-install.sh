#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
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

PORTAINER_AGENT_LATEST_VERSION=$(get_latest_github_release "portainer/agent")

setup_docker

# Every choice below can be supplied up front so the install runs unattended.
# Same convention as install/forgejo-runner-install.sh: read the variable, and
# only ask when it was not set.
if [[ -z "${var_portainer:-}" ]]; then
  if prompt_confirm "${TAB3}Would you like to install Portainer (UI) via the community-scripts addon?" "n" 60; then
    var_portainer="yes"
  else
    var_portainer="no"
  fi
fi

if [[ "${var_portainer:-}" =~ ^([yY]|[yY][eE][sS])$ ]]; then
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/portainer.sh)" <<<"y"
else
  if [[ -z "${var_portainer_agent:-}" ]]; then
    read -r -p "${TAB3}Would you like to install the Portainer Agent (for remote management)? <y/N> " var_portainer_agent
  fi
  if [[ "${var_portainer_agent:-}" =~ ^([yY]|[yY][eE][sS])$ ]]; then
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

if [[ -z "${var_docker_socket:-}" ]]; then
  read -r -p "${TAB3}Expose Docker TCP socket (insecure) ? [n = No, l = Local only (127.0.0.1), a = All interfaces (0.0.0.0)] <n/l/a>: " var_docker_socket
fi
case "${var_docker_socket:-}" in
l | L | local | Local)
  socket="tcp://127.0.0.1:2375"
  ;;
a | A | all | All)
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
  jq --arg sock "$socket" '. + { "hosts": ["unix:///var/run/docker.sock", $sock] }' /etc/docker/daemon.json >"$tmpfile" && mv "$tmpfile" /etc/docker/daemon.json

  mkdir -p /etc/systemd/system/docker.service.d
  cat <<EOF >/etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=$(command -v dockerd || echo /usr/sbin/dockerd)
EOF

  $STD systemctl daemon-reexec
  $STD systemctl daemon-reload

  if systemctl restart docker; then
    msg_ok "Docker TCP socket available on $socket"
  else
    msg_error "Docker failed to restart. Check journalctl -xeu docker.service"
    exit 150
  fi
fi

motd_ssh
customize
cleanup_lxc
