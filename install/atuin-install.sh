#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: j4v3 (j4v3)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/atuinsh/atuin

# Import Functions und Setup
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Installing Dependencies
msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  pkg-config \
  libssl-dev \
  protobuf-compiler \
  postgresql \
  postgresql-contrib

# Configure PostgreSQL
msg_info "Configuring PostgreSQL"
# Start PostgreSQL service
$STD systemctl start postgresql
$STD systemctl enable postgresql

# Create a database and user for Atuin
$STD sudo -u postgres psql -c "CREATE USER atuin WITH PASSWORD 'atuin';"
$STD sudo -u postgres psql -c "CREATE DATABASE atuin OWNER atuin;"
$STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE atuin TO atuin;"

# Allow local connections (no remote PostgreSQL access needed)
$STD sed -i "s/#listen_addresses = 'localhost'/listen_addresses = 'localhost'/g" /etc/postgresql/*/main/postgresql.conf
$STD systemctl restart postgresql
msg_ok "Configured PostgreSQL"

# Install Atuin using the official setup script
msg_info "Installing Atuin"
$STD curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

# Get the installed version
ATUIN_VERSION=$(~/.atuin/bin/atuin --version | awk '{print $2}')
msg_ok "Installed Atuin v${ATUIN_VERSION}"

# Create a symlink in /usr/local/bin for easy access
msg_info "Creating symlink for global access"
$STD ln -sf ~/.atuin/bin/atuin /usr/local/bin/atuin
msg_ok "Created symlink"

# Setup Atuin Server
msg_info "Setting up Atuin Server"
mkdir -p /etc/atuin/

# Create server configuration
cat <<EOF >/etc/atuin/server.toml
# Atuin server configuration
host = "0.0.0.0"
port = 8888
open_registration = true
db_uri = "postgres://atuin:atuin@localhost/atuin"
EOF

# Create systemd service for Atuin server
cat <<EOF >/etc/systemd/system/atuin-server.service
[Unit]
Description=Atuin sync server
After=network.target postgresql.service

[Service]
Type=simple
ExecStart=/usr/local/bin/atuin server start --config /etc/atuin/server.toml
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the Atuin server service
$STD systemctl enable atuin-server
$STD systemctl start atuin-server
msg_ok "Setup Atuin Server"

# Enable shell integration for local usage
msg_info "Setting up shell integration"

# For ZSH
if [ -f /bin/zsh ] || [ -f /usr/bin/zsh ]; then
  $STD echo 'eval "$(~/.atuin/bin/atuin init zsh)"' >>/etc/zsh/zshrc
fi

# For Bash
if [ -f /bin/bash ] || [ -f /usr/bin/bash ]; then
  # Install bash-preexec for bash integration
  $STD curl https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh -o /etc/bash-preexec.sh
  $STD echo '[[ -f /etc/bash-preexec.sh ]] && source /etc/bash-preexec.sh' >>/etc/bash.bashrc
  $STD echo 'eval "$(~/.atuin/bin/atuin init bash)"' >>/etc/bash.bashrc
fi

msg_ok "Setup shell integration"

# Create server info file
cat <<EOF >~/atuin-server-info.txt
Atuin Server Information
========================

Server Version: v${ATUIN_VERSION}
Server URL: http://$(hostname -I | awk '{print $1}'):8888

DATABASE CONFIGURATION:
----------------------
PostgreSQL Database: atuin
PostgreSQL User: atuin
PostgreSQL Password: atuin

SERVER CONFIGURATION:
-------------------
Config Location: /etc/atuin/server.toml
Current Settings:
- host = 0.0.0.0 (listens on all interfaces)
- port = 8888
- open_registration = true (new users can register)
- db_uri = postgres://atuin:atuin@localhost/atuin

You can modify these settings in /etc/atuin/server.toml and restart the server:
systemctl restart atuin-server

CONNECTING CLIENTS:
-----------------
On client machines, install Atuin and then run:

1. Configure client to use your server:
   atuin settings update sync_address http://$(hostname -I | awk '{print $1}'):8888

2. Register a new account:
   atuin register --username <USERNAME> --password <PASSWORD>

3. Or login with existing account:
   atuin login --username <USERNAME> --password <PASSWORD>

4. Start syncing:
   atuin sync

SECURITY CONSIDERATIONS:
----------------------
- The server has open registration enabled by default
- To disable open registration, set 'open_registration = false' in the config
- Consider setting up TLS for secure connections (see documentation)
- For production environments, consider stronger PostgreSQL credentials

ENABLING TLS:
-----------
To enable TLS, modify /etc/atuin/server.toml to include:

[tls]
enable = true
cert_path = "/path/to/fullchain.pem"
pkey_path = "/path/to/privkey.pem"

For more information, visit: https://docs.atuin.sh/self-hosting/server-setup/
EOF

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
