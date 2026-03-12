#!/usr/bin/env bash

# Author: Heretek-AI
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/vxcontrol/pentagi

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  wget \
  ca-certificates \
  gnupg \
  lsb-release \
  jq
msg_ok "Installed Dependencies"

msg_info "Installing Docker"
# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker packages
$STD apt-get update
$STD apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
msg_ok "Installed Docker"

msg_info "Creating Directories"
mkdir -p /opt/pentagi
mkdir -p /opt/pentagi/data
mkdir -p /opt/pentagi/ssl
mkdir -p /var/log/pentagi
msg_ok "Created Directories"

msg_info "Downloading PentAGI Configuration"
curl -fsSL https://raw.githubusercontent.com/vxcontrol/pentagi/master/docker-compose.yml -o /opt/pentagi/docker-compose.yml
curl -fsSL https://raw.githubusercontent.com/vxcontrol/pentagi/master/.env.example -o /opt/pentagi/.env.example
msg_ok "Downloaded PentAGI Configuration"

msg_info "Generating Secure Configuration"
# Generate random passwords and salts
POSTGRES_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
COOKIE_SALT=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
INSTALLATION_ID=$(cat /proc/sys/kernel/random/uuid)

# Create .env file from template
cp /opt/pentagi/.env.example /opt/pentagi/.env

# Strip inline comments (Go env parser doesn't handle them)
# Remove everything after # on lines that have = (but keep the value)
sed -i 's/=\([^#]*\)#.*/=\1/' /opt/pentagi/.env
# Trim trailing whitespace from values
sed -i 's/ *= */=/' /opt/pentagi/.env
sed -i 's/ *$//' /opt/pentagi/.env

# Set secure defaults
sed -i "s/^PENTAGI_POSTGRES_PASSWORD=.*/PENTAGI_POSTGRES_PASSWORD=${POSTGRES_PASSWORD}/" /opt/pentagi/.env
sed -i "s/^COOKIE_SIGNING_SALT=.*/COOKIE_SIGNING_SALT=${COOKIE_SALT}/" /opt/pentagi/.env
sed -i "s/^INSTALLATION_ID=.*/INSTALLATION_ID=${INSTALLATION_ID}/" /opt/pentagi/.env

# Set public URL to container IP
LOCAL_IP=$(hostname -I | awk '{print $1}')
sed -i "s|^PUBLIC_URL=.*|PUBLIC_URL=https://${LOCAL_IP}:8443|" /opt/pentagi/.env
sed -i "s|^CORS_ORIGINS=.*|CORS_ORIGINS=https://${LOCAL_IP}:8443,https://localhost:8443|" /opt/pentagi/.env
# Listen on all interfaces for external access
sed -i "s|^PENTAGI_LISTEN_IP=.*|PENTAGI_LISTEN_IP=0.0.0.0|" /opt/pentagi/.env

# Set scraper credentials
SCRAPER_USER="pentagi"
SCRAPER_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 16)
sed -i "s/^LOCAL_SCRAPER_USERNAME=.*/LOCAL_SCRAPER_USERNAME=${SCRAPER_USER}/" /opt/pentagi/.env
sed -i "s/^LOCAL_SCRAPER_PASSWORD=.*/LOCAL_SCRAPER_PASSWORD=${SCRAPER_PASS}/" /opt/pentagi/.env
sed -i "s|^SCRAPER_PRIVATE_URL=.*|SCRAPER_PRIVATE_URL=https://${SCRAPER_USER}:${SCRAPER_PASS}@scraper/|" /opt/pentagi/.env

# Set Langfuse passwords
LANGFUSE_POSTGRES_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
LANGFUSE_REDIS_AUTH=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
LANGFUSE_SALT=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
LANGFUSE_ENCRYPTION_KEY=$(openssl rand -hex 32)
LANGFUSE_NEXTAUTH_SECRET=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
LANGFUSE_S3_ACCESS_KEY_ID=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 16)
LANGFUSE_S3_SECRET_ACCESS_KEY=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
LANGFUSE_INIT_USER_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 16)
LANGFUSE_INIT_PROJECT_PUBLIC_KEY="pk-lf-$(cat /proc/sys/kernel/random/uuid | tr -d '-')"
LANGFUSE_INIT_PROJECT_SECRET_KEY="sk-lf-$(cat /proc/sys/kernel/random/uuid | tr -d '-')"

sed -i "s/^LANGFUSE_POSTGRES_PASSWORD=.*/LANGFUSE_POSTGRES_PASSWORD=${LANGFUSE_POSTGRES_PASSWORD}/" /opt/pentagi/.env
sed -i "s/^LANGFUSE_REDIS_AUTH=.*/LANGFUSE_REDIS_AUTH=${LANGFUSE_REDIS_AUTH}/" /opt/pentagi/.env
sed -i "s/^LANGFUSE_SALT=.*/LANGFUSE_SALT=${LANGFUSE_SALT}/" /opt/pentagi/.env
sed -i "s/^LANGFUSE_ENCRYPTION_KEY=.*/LANGFUSE_ENCRYPTION_KEY=${LANGFUSE_ENCRYPTION_KEY}/" /opt/pentagi/.env
sed -i "s/^LANGFUSE_NEXTAUTH_SECRET=.*/LANGFUSE_NEXTAUTH_SECRET=${LANGFUSE_NEXTAUTH_SECRET}/" /opt/pentagi/.env
sed -i "s/^LANGFUSE_S3_ACCESS_KEY_ID=.*/LANGFUSE_S3_ACCESS_KEY_ID=${LANGFUSE_S3_ACCESS_KEY_ID}/" /opt/pentagi/.env
sed -i "s/^LANGFUSE_S3_SECRET_ACCESS_KEY=.*/LANGFUSE_S3_SECRET_ACCESS_KEY=${LANGFUSE_S3_SECRET_ACCESS_KEY}/" /opt/pentagi/.env
sed -i "s/^LANGFUSE_INIT_USER_PASSWORD=.*/LANGFUSE_INIT_USER_PASSWORD=${LANGFUSE_INIT_USER_PASSWORD}/" /opt/pentagi/.env
sed -i "s/^LANGFUSE_INIT_PROJECT_PUBLIC_KEY=.*/LANGFUSE_INIT_PROJECT_PUBLIC_KEY=${LANGFUSE_INIT_PROJECT_PUBLIC_KEY}/" /opt/pentagi/.env
sed -i "s/^LANGFUSE_INIT_PROJECT_SECRET_KEY=.*/LANGFUSE_INIT_PROJECT_SECRET_KEY=${LANGFUSE_INIT_PROJECT_SECRET_KEY}/" /opt/pentagi/.env

# Set Neo4j password for Graphiti
NEO4J_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
sed -i "s/^NEO4J_PASSWORD=.*/NEO4J_PASSWORD=${NEO4J_PASSWORD}/" /opt/pentagi/.env
msg_ok "Generated Secure Configuration"

msg_info "Creating Systemd Service"
cat <<EOF >/etc/systemd/system/pentagi.service
[Unit]
Description=PentAGI - AI-Powered Autonomous Penetration Testing
After=network.target network-online.target docker.service
Wants=network-online.target
Requires=docker.service

[Service]
Type=simple
WorkingDirectory=/opt/pentagi
EnvironmentFile=/opt/pentagi/.env
ExecStart=/usr/bin/docker compose up
ExecStop=/usr/bin/docker compose down
Restart=always
RestartSec=10
TimeoutStartSec=300
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
EOF
msg_ok "Created Systemd Service"

msg_info "Pulling Docker Images"
cd /opt/pentagi || exit
$STD docker compose pull
msg_ok "Pulled Docker Images"

msg_info "Starting PentAGI Service"
systemctl daemon-reload
systemctl enable -q pentagi
systemctl start pentagi
msg_ok "Started PentAGI Service"


# Store credentials for user reference
cat <<EOF >/opt/pentagi/CREDENTIALS.txt
PentAGI Credentials
===================

Web Interface:
  URL: https://${LOCAL_IP}:8443
  Default Username: admin@pentagi.com
  Default Password: admin

PostgreSQL Database:
  User: postgres
  Password: ${POSTGRES_PASSWORD}
  Database: pentagidb

Scraper Service:
  Username: ${SCRAPER_USER}
  Password: ${SCRAPER_PASS}

Langfuse (if enabled):
  Admin Email: admin@pentagi.com
  Admin Password: ${LANGFUSE_INIT_USER_PASSWORD}
  Project Public Key: ${LANGFUSE_INIT_PROJECT_PUBLIC_KEY}
  Project Secret Key: ${LANGFUSE_INIT_PROJECT_SECRET_KEY}

Neo4j (for Graphiti, if enabled):
  User: neo4j
  Password: ${NEO4J_PASSWORD}

IMPORTANT:
1. Change the default web interface password after first login
2. Configure at least one LLM provider API key in Settings
3. This file contains sensitive credentials - secure it appropriately
EOF
chmod 600 /opt/pentagi/CREDENTIALS.txt

msg_info "Creating Configuration Guide"
cat <<EOF >/opt/pentagi/CONFIGURATION.md
# PentAGI Configuration Guide

## Required Configuration

Before using PentAGI, you must configure at least one LLM provider.

### LLM Provider Configuration

Edit /opt/pentagi/.env and add your API key for at least one provider:

#### OpenAI
\`\`\`
OPEN_AI_KEY=your_openai_api_key
\`\`\`

#### Anthropic (Claude)
\`\`\`
ANTHROPIC_API_KEY=your_anthropic_api_key
\`\`\`

#### Google Gemini
\`\`\`
GEMINI_API_KEY=your_gemini_api_key
\`\`\`

#### AWS Bedrock
\`\`\`
BEDROCK_REGION=us-east-1
BEDROCK_DEFAULT_AUTH=true
# Or use static credentials:
# BEDROCK_ACCESS_KEY_ID=your_access_key
# BEDROCK_SECRET_ACCESS_KEY=your_secret_key
\`\`\`

#### Ollama (Local)
\`\`\`
OLLAMA_SERVER_URL=http://your-ollama-server:11434
OLLAMA_SERVER_MODEL=llama3.1:8b-instruct-q8_0
\`\`\`

### Optional: Enable Graphiti Knowledge Graph

To enable the knowledge graph feature:

1. Download the Graphiti compose file:
   \`\`\`
   cd /opt/pentagi
   curl -O https://raw.githubusercontent.com/vxcontrol/pentagi/master/docker-compose-graphiti.yml
   \`\`\`

2. Edit /etc/systemd/system/pentagi.service and change:
   \`\`\`
   ExecStart=/usr/bin/docker compose -f docker-compose.yml -f docker-compose-graphiti.yml up
   ExecStop=/usr/bin/docker compose -f docker-compose.yml -f docker-compose-graphiti.yml down
   \`\`\`

3. Enable Graphiti in .env:
   \`\`\`
   GRAPHITI_ENABLED=true
   GRAPHITI_URL=http://graphiti:8000
   \`\`\`

4. Reload and restart:
   \`\`\`
   systemctl daemon-reload
   systemctl restart pentagi
   \`\`\`

### Optional: Enable Langfuse Observability

To enable LLM observability:

1. Download the Langfuse compose file:
   \`\`\`
   cd /opt/pentagi
   curl -O https://raw.githubusercontent.com/vxcontrol/pentagi/master/docker-compose-langfuse.yml
   \`\`\`

2. Edit /etc/systemd/system/pentagi.service and change:
   \`\`\`
   ExecStart=/usr/bin/docker compose -f docker-compose.yml -f docker-compose-langfuse.yml up
   ExecStop=/usr/bin/docker compose -f docker-compose.yml -f docker-compose-langfuse.yml down
   \`\`\`

3. Enable Langfuse in .env:
   \`\`\`
   LANGFUSE_BASE_URL=http://langfuse-web:3000
   LANGFUSE_PUBLIC_KEY=<from CREDENTIALS.txt>
   LANGFUSE_SECRET_KEY=<from CREDENTIALS.txt>
   \`\`\`

4. Reload and restart:
   \`\`\`
   systemctl daemon-reload
   systemctl restart pentagi
   \`\`\`

## Service Management

- Start: \`systemctl start pentagi\`
- Stop: \`systemctl stop pentagi\`
- Restart: \`systemctl restart pentagi\`
- Status: \`systemctl status pentagi\`
- Logs: \`journalctl -u pentagi -f\`

## Updating

Run the update script from the Proxmox host:
\`\`\`
./ct/pentagi.sh
\`\`\`

Or manually:
\`\`\`
cd /opt/pentagi
docker compose pull
systemctl restart pentagi
\`\`\`

## External Access

To access PentAGI from other machines, edit /opt/pentagi/.env:

\`\`\`
PENTAGI_LISTEN_IP=0.0.0.0
PUBLIC_URL=https://your-server-ip:8443
CORS_ORIGINS=https://your-server-ip:8443,https://localhost:8443
\`\`\`

Then restart: \`systemctl restart pentagi\`

## More Information

- Documentation: https://github.com/vxcontrol/pentagi
- Discord: https://discord.gg/2xrMh7qX6m
- Telegram: https://t.me/+Ka9i6CNwe71hMWQy
EOF
msg_ok "Created Configuration Guide"

motd_ssh
customize
cleanup_lxc

echo ""
echo "=========================================="
echo " PentAGI Installation Complete!"
echo "=========================================="
echo ""
echo "Access the web interface at: https://${LOCAL_IP}:8443"
echo "Default credentials: admin@pentagi.com / admin"
echo ""
echo "IMPORTANT: Configure your LLM provider API key before use!"
echo "See /opt/pentagi/CONFIGURATION.md for detailed setup instructions."
echo "Credentials are stored in /opt/pentagi/CREDENTIALS.txt"
echo ""
echo "Start the service with: systemctl start pentagi"
echo "=========================================="
