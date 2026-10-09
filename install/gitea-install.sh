#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# Co-author: Rogue-King
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://about.gitea.com/ | Github: https://github.com/go-gitea/gitea

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb_based() {
  msg_info "Installing Dependencies"
  $STD apt install -y \
    git \
    sqlite3
  msg_ok "Installed Dependencies"

  fetch_and_deploy_gh_release "gitea" "go-gitea/gitea" "singlefile" "latest" "/usr/local/bin" "gitea-*-linux-$(arch_resolve)"

  msg_info "Configuring Gitea"
  chmod +x /usr/local/bin/gitea
  $STD adduser --system --group --disabled-password --shell /bin/bash --home /etc/gitea gitea
  mkdir -p /var/lib/gitea/{custom,data,log}
  chown -R gitea:gitea /var/lib/gitea/
  chmod -R 750 /var/lib/gitea/
  chown gitea:gitea /etc/gitea
  chmod 750 /etc/gitea
  sudo -u gitea ln -s /var/lib/gitea/data/.ssh/ /etc/gitea/.ssh
  msg_ok "Configured Gitea"

  msg_info "Creating Service"
  cat <<EOF >/etc/systemd/system/gitea.service
[Unit]
Description=Gitea (Git with a cup of tea)
After=syslog.target
After=network.target

[Service]
# Uncomment notify and watchdog if you want to use them
# Uncomment the next line if you have repos with lots of files and get a HTTP 500 error because of that
# LimitNOFILE=524288:524288
RestartSec=2s
Type=simple
#Type=notify
User=gitea
Group=gitea
#The mount point we added to the container
WorkingDirectory=/var/lib/gitea
#Create directory in /run
RuntimeDirectory=gitea
ExecStart=/usr/local/bin/gitea web --config /etc/gitea/app.ini
Restart=always
Environment=USER=gitea HOME=/var/lib/gitea/data GITEA_WORK_DIR=/var/lib/gitea
#WatchdogSec=30s
#Capabilities to bind to low-numbered ports
#CapabilityBoundingSet=CAP_NET_BIND_SERVICE
#AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now gitea
  msg_ok "Created Service"
}

setup_alpine() {
  msg_info "Installing Gitea"
  $STD apk add --no-cache gitea
  msg_ok "Installed Gitea"

  msg_info "Enabling Gitea Service"
  $STD rc-update add gitea default
  msg_ok "Enabled Gitea Service"

  msg_info "Starting Gitea"
  $STD service gitea start
  msg_ok "Started Gitea"
}

run_os_setup

motd_ssh
customize
cleanup_lxc
