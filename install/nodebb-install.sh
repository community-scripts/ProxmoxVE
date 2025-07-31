#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/NodeBB/NodeBB

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y \
  build-essential \
  redis-server \
  expect \
  ca-certificates
msg_ok "Installed Dependencies"

setup_mongodb
NODE_VERSION="22" setup_nodejs

msg_info "Configuring MongoDB"
MONGO_ADMIN_USER="admin"
MONGO_ADMIN_PWD="$(openssl rand -base64 18 | cut -c1-13)"
NODEBB_USER="nodebb"
NODEBB_PWD="$(openssl rand -base64 18 | cut -c1-13)"
MONGO_CONNECTION_STRING="mongodb://${NODEBB_USER}:${NODEBB_PWD}@localhost:27017/nodebb"
NODEBB_SECRET=$(uuidgen)
{
  echo "NodeBB-Credentials"
  echo "Mongo Database User: $MONGO_ADMIN_USER"
  echo "Mongo Database Password: $MONGO_ADMIN_PWD"
  echo "NodeBB User: $NODEBB_USER"
  echo "NodeBB Password: $NODEBB_PWD"
  echo "NodeBB Secret: $NODEBB_SECRET"
} >>~/nodebb.creds

$STD mongosh <<EOF
use admin
db.createUser({
  user: "$MONGO_ADMIN_USER",
  pwd: "$MONGO_ADMIN_PWD",
  roles: [{ role: "root", db: "admin" }]
})

use nodebb
db.createUser({
  user: "$NODEBB_USER",
  pwd: "$NODEBB_PWD",
  roles: [
    { role: "readWrite", db: "nodebb" },
    { role: "clusterMonitor", db: "admin" }
  ]
})
quit()
EOF
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf
sed -i '/security:/d' /etc/mongod.conf
bash -c 'echo -e "\nsecurity:\n  authorization: enabled" >> /etc/mongod.conf'
systemctl restart mongod
msg_ok "MongoDB configured"

fetch_and_deploy_gh_release "nodebb" "NodeBB/NodeBB" "tarball"

msg_info "Configuring NodeBB"
cd /opt/nodebb
touch pidfile
expect <<EOF >/dev/null 2>&1
log_file /dev/null
set timeout -1

spawn ./nodebb setup
expect "URL used to access this NodeBB" {
    send "http://localhost:4567\r"
}
expect "Please enter a NodeBB secret" {
    send "$NODEBB_SECRET\r"
}
expect "Would you like to submit anonymous plugin usage to nbbpm? (yes)" {
    send "no\r"
}
expect "Which database to use (mongo)" {
    send "mongo\r"
}
expect "Format: mongodb://*" {
    send "$MONGO_CONNECTION_STRING\r"
}
expect "Administrator username" {
    send "helper-scripts\r"
}
expect "Administrator email address" {
    send "helper-scripts@local.com\r"
}
expect "Password" {
    send "helper-scripts\r"
}
expect "Confirm Password" {
    send "helper-scripts\r"
}
expect eof
EOF
msg_ok "Configured NodeBB"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/nodebb.service
[Unit]
Description=NodeBB
Documentation=https://docs.nodebb.org
After=system.slice multi-user.target mongod.service

[Service]
Type=forking
User=root

WorkingDirectory=/opt/nodebb
PIDFile=/opt/nodebb/pidfile
ExecStart=/usr/bin/node /opt/nodebb/loader.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now nodebb
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
