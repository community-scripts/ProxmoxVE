#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/plastic-labs/honcho

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y redis-server
msg_ok "Installed Dependencies"

PG_VERSION="17" PG_MODULES="pgvector" setup_postgresql
PG_DB_NAME="honcho" PG_DB_USER="honcho" PG_DB_EXTENSIONS="vector,pg_trgm" setup_postgresql_db
PYTHON_VERSION="3.13" setup_uv
fetch_and_deploy_gh_release "honcho" "plastic-labs/honcho" "tarball" "latest" "/opt/honcho" "" "v"

msg_info "Installing Honcho"
cd /opt/honcho
$STD uv sync --frozen --no-dev
msg_ok "Installed Honcho"

if [[ -t 0 && -z "${var_honcho_provider:-}${var_honcho_api_key:-}${var_honcho_base_url:-}" ]]; then
  echo -e "${INFO}${YW} Honcho needs an LLM provider for memory, embeddings and chat; without a key it is installed but not started.${CL}"
  read -t 300 -rsp "${TAB3}OpenAI API key (Enter to set up a provider later): " var_honcho_api_key || true
  echo
fi

declare -A HONCHO_KEY=([openai]="" [anthropic]="" [gemini]="")
case "${var_honcho_provider:-openai}" in
anthropic)
  HONCHO_TRANSPORT="anthropic" HONCHO_MODEL="${var_honcho_model:-claude-haiku-4-5}"
  HONCHO_EMBEDDING="openai" HONCHO_EMBEDDING_MODEL="${var_honcho_embedding_model:-text-embedding-3-small}"
  HONCHO_KEY[anthropic]="${var_honcho_api_key:-}"
  HONCHO_KEY[openai]="${var_honcho_embedding_key:-}"
  ;;
gemini)
  HONCHO_TRANSPORT="gemini" HONCHO_MODEL="${var_honcho_model:-gemini-2.5-flash}"
  HONCHO_EMBEDDING="gemini" HONCHO_EMBEDDING_MODEL="${var_honcho_embedding_model:-gemini-embedding-001}"
  HONCHO_KEY[gemini]="${var_honcho_api_key:-}"
  ;;
*)
  HONCHO_TRANSPORT="openai" HONCHO_MODEL="${var_honcho_model:-gpt-5.4-mini}"
  HONCHO_EMBEDDING="openai" HONCHO_EMBEDDING_MODEL="${var_honcho_embedding_model:-text-embedding-3-small}"
  HONCHO_KEY[openai]="${var_honcho_api_key:-${var_honcho_base_url:+not-needed}}"
  ;;
esac

msg_info "Configuring Honcho"
mkdir -p /opt/honcho_data
cat <<EOF >/opt/honcho_data/.env
DB_CONNECTION_URI=postgresql+psycopg://honcho:${PG_DB_PASS}@localhost:5432/honcho
CACHE_ENABLED=true
CACHE_URL=redis://localhost:6379/0?suppress=true

# Every /v3 API request needs a JWT signed with this secret. Mint one with:
# cd /opt/honcho && .venv/bin/python scripts/generate_jwt.py --admin
AUTH_USE_AUTH=true
AUTH_JWT_SECRET=$(openssl rand -hex 32)
WEBHOOK_SECRET=$(openssl rand -hex 32)

# Transports: openai (OpenAI or any OpenAI-compatible endpoint), anthropic, gemini.
# Embeddings run on openai or gemini only. Apply changes with: systemctl restart honcho honcho-deriver
LLM_OPENAI_API_KEY=${HONCHO_KEY[openai]}
LLM_ANTHROPIC_API_KEY=${HONCHO_KEY[anthropic]}
LLM_GEMINI_API_KEY=${HONCHO_KEY[gemini]}

# An OpenAI-compatible endpoint (OpenRouter, Ollama, vLLM, LiteLLM) replaces api.openai.com through both lines:
#LLM_OPENAI_BASE_URL=http://192.168.1.50:11434/v1
#EMBEDDING_MODEL_CONFIG__OVERRIDES__BASE_URL=http://192.168.1.50:11434/v1
# Endpoints without OpenAI Structured Outputs need:
#DERIVER_MODEL_CONFIG__STRUCTURED_OUTPUT_MODE=json_object

EMBEDDING_MODEL_CONFIG__TRANSPORT=${HONCHO_EMBEDDING}
EMBEDDING_MODEL_CONFIG__MODEL=${HONCHO_EMBEDDING_MODEL}
# A model with another vector size works only while nothing is embedded yet: set it here, then run
# cd /opt/honcho && .venv/bin/python scripts/configure_embeddings.py --yes
#EMBEDDING_VECTOR_DIMENSIONS=1536

# The deriver waits for about 512 new tokens per peer, or 30 minutes, before it calls the LLM
#DERIVER_FLUSH_ENABLED=true

# Models for the deriver, summaries, dreams and dialectic chat; they must support tool calling
EOF
for prefix in DERIVER SUMMARY DREAM_DEDUCTION DREAM_INDUCTION DIALECTIC_LEVELS__{minimal,low,medium,high,max}_; do
  cat <<EOF >>/opt/honcho_data/.env
${prefix}_MODEL_CONFIG__TRANSPORT=${HONCHO_TRANSPORT}
${prefix}_MODEL_CONFIG__MODEL=${HONCHO_MODEL}
EOF
done
if [[ -n "${var_honcho_base_url:-}" ]]; then
  cat <<EOF >>/opt/honcho_data/.env

LLM_OPENAI_BASE_URL=${var_honcho_base_url}
EMBEDDING_MODEL_CONFIG__OVERRIDES__BASE_URL=${var_honcho_base_url}
EOF
fi
if [[ -n "${var_honcho_embedding_dims:-}" ]]; then
  cat <<EOF >>/opt/honcho_data/.env
EMBEDDING_VECTOR_DIMENSIONS=${var_honcho_embedding_dims}
EOF
fi
chmod 600 /opt/honcho_data/.env
ln -sf /opt/honcho_data/.env /opt/honcho/.env
msg_ok "Configured Honcho"

msg_info "Migrating Honcho Database"
$STD .venv/bin/python scripts/provision_db.py
$STD .venv/bin/python scripts/configure_embeddings.py --yes
msg_ok "Migrated Honcho Database"

msg_info "Creating Honcho Services"
cat <<EOF >/etc/systemd/system/honcho.service
[Unit]
Description=Honcho API
After=network.target postgresql.service redis-server.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/honcho
Environment=PYTHONUNBUFFERED=1
ExecStart=/opt/honcho/.venv/bin/fastapi run --host 0.0.0.0 --port 8000 src/main.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/honcho-deriver.service
[Unit]
Description=Honcho Deriver
After=network.target postgresql.service redis-server.service honcho.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/honcho
Environment=PYTHONUNBUFFERED=1
ExecStart=/opt/honcho/.venv/bin/python -m src.deriver
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
msg_ok "Created Honcho Services"

if [[ -n "${HONCHO_KEY[$HONCHO_TRANSPORT]}" && -n "${HONCHO_KEY[$HONCHO_EMBEDDING]}" ]]; then
  msg_info "Starting Honcho"
  systemctl enable -q --now honcho honcho-deriver
  msg_ok "Started Honcho"
else
  msg_warn "No LLM provider key (with Anthropic also an OpenAI key for embeddings): Honcho stays stopped until it is set in /opt/honcho_data/.env"
fi

motd_ssh
customize
cleanup_lxc
