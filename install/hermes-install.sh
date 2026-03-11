#!/usr/bin/env bash

# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/NousResearch/hermes-agent

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  build-essential \
  python3-dev \
  libffi-dev \
  ripgrep \
  ffmpeg
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.11" setup_uv

NODE_VERSION="22" setup_nodejs

msg_info "Cloning Hermes Agent Repository"
cd /opt
$STD git clone --recurse-submodules https://github.com/NousResearch/hermes-agent.git hermes-agent
cd /opt/hermes-agent
msg_ok "Cloned Repository"

msg_info "Installing Python Dependencies"
$STD uv venv .venv --python 3.11
export VIRTUAL_ENV="/opt/hermes-agent/.venv"
$STD uv pip install -e ".[all]"

msg_info "Installing Submodules"
if [[ -d "mini-swe-agent" && -f "mini-swe-agent/pyproject.toml" ]]; then
  $STD uv pip install -e "./mini-swe-agent"
fi
if [[ -d "tinker-atropos" && -f "tinker-atropos/pyproject.toml" ]]; then
  $STD uv pip install -e "./tinker-atropos"
fi
msg_ok "Installed Python Dependencies"

msg_info "Creating Configuration Directory"
mkdir -p /root/.hermes/{cron,sessions,logs,pairing,hooks,image_cache,audio_cache,memories,skills,whatsapp/session}
msg_ok "Created Configuration Directory"

msg_info "Creating Environment File"
if [[ -f "/opt/hermes-agent/.env.example" ]]; then
  cp /opt/hermes-agent/.env.example /root/.hermes/.env
else
  cat <<EOF >/root/.hermes/.env
# Hermes Agent Configuration
# Add your LLM provider API keys below

# OpenAI (optional)
# OPENAI_API_KEY=sk-...

# OpenRouter (optional)
# OPENROUTER_API_KEY=sk-or-...

# Nous Portal (optional)
# NOUS_API_KEY=...

# Server configuration
HERMES_HOST=0.0.0.0
HERMES_PORT=8000
EOF
fi
msg_ok "Created Environment File"

msg_info "Creating Config File"
if [[ -f "/opt/hermes-agent/cli-config.yaml.example" ]]; then
  cp /opt/hermes-agent/cli-config.yaml.example /root/.hermes/config.yaml
fi
msg_ok "Created Config File"

msg_info "Creating SOUL.md Persona File"
cat <<'EOF' >/root/.hermes/SOUL.md
# Hermes Agent Persona

<!--
This file defines the agent's personality and tone.
The agent will embody whatever you write here.
Edit this to customize how Hermes communicates with you.

Examples:
  - "You are a warm, playful assistant who uses kaomoji occasionally."
  - "You are a concise technical expert. No fluff, just facts."
  - "You speak like a friendly coworker who happens to know everything."

This file is loaded fresh each message -- no restart needed.
Delete the contents (or this file) to use the default personality.
-->
EOF
msg_ok "Created SOUL.md"

msg_info "Creating Symlink for Hermes Command"
mkdir -p /root/.local/bin
ln -sf /opt/hermes-agent/.venv/bin/hermes /root/.local/bin/hermes
msg_ok "Created Symlink"

msg_info "Syncing Bundled Skills"
if [[ -d "/opt/hermes-agent/skills" ]]; then
  $STD /opt/hermes-agent/.venv/bin/python /opt/hermes-agent/tools/skills_sync.py 2>/dev/null || \
    cp -r /opt/hermes-agent/skills/* /root/.hermes/skills/ 2>/dev/null || true
fi
msg_ok "Synced Skills"

msg_info "Installing Node.js Dependencies (for browser tools)"
if [[ -f "/opt/hermes-agent/package.json" ]]; then
  cd /opt/hermes-agent
  $STD npm install --silent 2>/dev/null || true
  msg_info "Installing Playwright Browser"
  $STD npx --yes playwright install chromium 2>/dev/null || true
fi

if [[ -f "/opt/hermes-agent/scripts/whatsapp-bridge/package.json" ]]; then
  cd /opt/hermes-agent/scripts/whatsapp-bridge
  $STD npm install --silent 2>/dev/null || true
fi
msg_ok "Installed Node.js Dependencies"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/hermes-agent.service
[Unit]
Description=Hermes Agent - Self-improving AI Agent
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/hermes-agent
Environment=PATH=/root/.local/bin:/usr/local/bin:/usr/bin:/bin
EnvironmentFile=/root/.hermes/.env
ExecStart=/opt/hermes-agent/.venv/bin/hermes gateway
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now hermes-agent
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
