#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.rabbitmq.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  lsb-release \
  apt-transport-https \
  make
msg_ok "Installed Dependencies"

msg_info "Adding RabbitMQ signing key"
curl -fsSL "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" | gpg --dearmor >/usr/share/keyrings/com.rabbitmq.team.gpg
msg_ok "Signing keys added"

msg_info "Adding RabbitMQ repository"
cat <<EOF >/etc/apt/sources.list.d/rabbitmq.list
## Modern Erlang/OTP releases
deb [arch=amd64 signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://deb1.rabbitmq.com/rabbitmq-erlang/debian/bookworm bookworm main
deb [arch=amd64 signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://deb2.rabbitmq.com/rabbitmq-erlang/debian/bookworm bookworm main

## Provides modern RabbitMQ releases
deb [arch=amd64 signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://deb1.rabbitmq.com/rabbitmq-server/debian/bookworm bookworm main
deb [arch=amd64 signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://deb2.rabbitmq.com/rabbitmq-server/debian/bookworm bookworm main
EOF
msg_ok "RabbitMQ repository added"

msg_info "Updating package list"
$STD apt update -y
msg_ok "Package list updated"

msg_info "Installing Erlang & RabbitMQ server"
$STD apt install -y erlang-base \
  erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets \
  erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
  erlang-runtime-tools erlang-snmp erlang-ssl \
  erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl \
  rabbitmq-server
msg_ok "RabbitMQ server installed"

msg_info "Starting RabbitMQ service"
systemctl enable -q --now rabbitmq-server
msg_ok "RabbitMQ service started"

msg_info "Enabling RabbitMQ management plugin"
$STD rabbitmq-plugins enable rabbitmq_management
$STD rabbitmqctl enable_feature_flag all
msg_ok "RabbitMQ management plugin enabled"

msg_info "Create User"
$STD rabbitmqctl add_user proxmox proxmox
$STD rabbitmqctl set_user_tags proxmox administrator
$STD rabbitmqctl set_permissions -p / proxmox ".*" ".*" ".*"
msg_ok "Created User"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
