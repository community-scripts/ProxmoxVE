#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: community-scripts
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gitea.com/gitea/runner

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb_based() {
  msg_info "Installing Dependencies"
  $STD apt install -y git
  msg_ok "Installed Dependencies"

  setup_docker

  msg_info "Installing Gitea Runner"
  RELEASE=$(curl -fsSL https://gitea.com/api/v1/repos/gitea/runner/releases/latest | jq -r .tag_name | sed 's/^v//')
  $STD curl -fsSL -o /usr/local/bin/gitea-runner "https://gitea.com/gitea/runner/releases/download/v${RELEASE}/gitea-runner-${RELEASE}-linux-$(arch_resolve)"
  chmod +x /usr/local/bin/gitea-runner
  ln -sf /usr/local/bin/gitea-runner /usr/local/bin/act_runner
  echo "${RELEASE}" >~/.gitea-runner
  msg_ok "Installed Gitea Runner v${RELEASE}"

  msg_info "Configuring Gitea Runner"
  mkdir -p /etc/gitea-runner /var/lib/gitea-runner
  /usr/local/bin/gitea-runner config generate >/etc/gitea-runner/config.yaml
  sed -i 's|.*file:.*\.runner.*|  file: /var/lib/gitea-runner/.runner|' /etc/gitea-runner/config.yaml
  msg_ok "Configured Gitea Runner"

  if [[ -n "${var_gitea_url:-}" ]] && [[ -n "${var_gitea_token:-}" ]]; then
    msg_info "Registering Gitea Runner"
    $STD /usr/local/bin/gitea-runner register --no-interactive --config /etc/gitea-runner/config.yaml --instance "${var_gitea_url}" --token "${var_gitea_token}" --name "$(hostname)"
    msg_ok "Registered Gitea Runner"
  fi

  msg_info "Creating Service"
  cat <<EOF >/etc/systemd/system/gitea-runner.service
[Unit]
Description=Gitea Actions Runner
Documentation=https://docs.gitea.com/runner/
After=network-online.target docker.service
Wants=network-online.target docker.service

[Service]
Type=simple
ExecStart=/usr/local/bin/gitea-runner daemon --config /etc/gitea-runner/config.yaml
WorkingDirectory=/var/lib/gitea-runner
Environment=HOME=/var/lib/gitea-runner
Restart=on-failure
RestartSec=5s
TimeoutStopSec=3h

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q gitea-runner
  if [[ -s /var/lib/gitea-runner/.runner ]]; then
    systemctl start gitea-runner
  fi
  msg_ok "Created Service"
}

setup_alpine() {
  msg_info "Installing Docker"
  $STD apk add --no-cache docker docker-cli-compose git
  $STD rc-update add docker default
  $STD rc-service docker start
  msg_ok "Installed Docker"

  msg_info "Installing Gitea Runner"
  RELEASE=$(curl -fsSL https://gitea.com/api/v1/repos/gitea/runner/releases/latest | jq -r .tag_name | sed 's/^v//')
  $STD curl -fsSL -o /usr/local/bin/gitea-runner "https://gitea.com/gitea/runner/releases/download/v${RELEASE}/gitea-runner-${RELEASE}-linux-$(arch_resolve)"
  chmod +x /usr/local/bin/gitea-runner
  ln -sf /usr/local/bin/gitea-runner /usr/local/bin/act_runner
  echo "${RELEASE}" >~/.gitea-runner
  msg_ok "Installed Gitea Runner v${RELEASE}"

  msg_info "Configuring Gitea Runner"
  mkdir -p /etc/gitea-runner /var/lib/gitea-runner
  /usr/local/bin/gitea-runner config generate >/etc/gitea-runner/config.yaml
  sed -i 's|.*file:.*\.runner.*|  file: /var/lib/gitea-runner/.runner|' /etc/gitea-runner/config.yaml
  msg_ok "Configured Gitea Runner"

  if [[ -n "${var_gitea_url:-}" ]] && [[ -n "${var_gitea_token:-}" ]]; then
    msg_info "Registering Gitea Runner"
    $STD /usr/local/bin/gitea-runner register --no-interactive --config /etc/gitea-runner/config.yaml --instance "${var_gitea_url}" --token "${var_gitea_token}" --name "$(hostname)"
    msg_ok "Registered Gitea Runner"
  fi

  msg_info "Creating Service"
  cat <<'EOF' >/etc/init.d/gitea-runner
#!/sbin/openrc-run
name="gitea-runner"
description="Gitea Actions Runner"

export HOME="/var/lib/gitea-runner"
command="/usr/local/bin/gitea-runner"
command_args="daemon --config /etc/gitea-runner/config.yaml"
directory="/var/lib/gitea-runner"
command_background="yes"
pidfile="/run/gitea-runner.pid"
output_log="/var/log/gitea-runner.log"
error_log="/var/log/gitea-runner.log"

depend() {
  need net docker
  after firewall
}
EOF
  chmod +x /etc/init.d/gitea-runner
  $STD rc-update add gitea-runner default
  if [[ -s /var/lib/gitea-runner/.runner ]]; then
    $STD rc-service gitea-runner start
  fi
  msg_ok "Created Service"
}

run_os_setup

motd_ssh
customize
cleanup_lxc
