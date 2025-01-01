#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.rabbitmq.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  sudo \
  lsb-release \
  curl \
  gnupg   \
  apt-transport-https \
  make \
  mc
msg_ok "Installed Dependencies"

msg_info "Adding RabbitMQ signing key"
wget -qO- "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" | gpg --dearmor >/usr/share/keyrings/com.rabbitmq.team.gpg
wget -qO- "https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key" | gpg --dearmor >/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg
wget -qO- "https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key" | gpg --dearmor >/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg
msg_ok "Signing keys added"

msg_info "Adding RabbitMQ repository"
cat <<EOF >/etc/apt/sources.list.d/rabbitmq.list
## Provides modern Erlang/OTP releases from a Cloudsmith mirror
deb [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/deb/debian $(lsb_release -cs) main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/deb/debian $(lsb_release -cs) main

## Provides RabbitMQ from a Cloudsmith mirror
deb [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/deb/debian $(lsb_release -cs) main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/deb/debian $(lsb_release -cs) main
EOF
msg_ok "RabbitMQ repository added"

msg_info "Updating package list"
$STD apt-get update -y
msg_ok "Package list updated"

msg_info "Installing Erlang & RabbitMQ server"
$STD apt-get install -y erlang-base \
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
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
