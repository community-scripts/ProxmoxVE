#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/NeptuneHub/AudioMuse-AI

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  git \
  ffmpeg \
  libchromaprint-tools \
  libsndfile1 \
  libgomp1
msg_ok "Installed Dependencies"

PG_VERSION="16" setup_postgresql
PG_DB_NAME="audiomuse" PG_DB_USER="audiomuse" setup_postgresql_db
UV_PYTHON="3.12" setup_uv
setup_hwaccel

fetch_and_deploy_gh_release "audiomuse-ai" "NeptuneHub/AudioMuse-AI" "tarball"

var_backend="${var_backend:-auto}"
if [[ "$var_backend" == "auto" ]]; then
  if ! grep -qm1 avx2 /proc/cpuinfo; then
    var_backend="cpu-noavx2"
  elif [[ "${HWACCEL_VENDOR:-none}" == "nvidia" ]]; then
    var_backend="gpu"
  else
    var_backend="cpu"
  fi
fi

REQ_COMMON="common.txt"
case "$var_backend" in
gpu)
  REQ_ACCEL="gpu.txt"
  [[ "$(uname -m)" == "aarch64" ]] && REQ_ACCEL="gpu-arm64.txt"
  ;;
cpu)
  REQ_ACCEL="cpu.txt"
  ;;
cpu-noavx2)
  REQ_COMMON="common-noavx2.txt"
  REQ_ACCEL="cpu-noavx2.txt"
  ;;
*)
  msg_error "Unknown var_backend '${var_backend}' (expected auto, gpu, cpu or cpu-noavx2)"
  exit 1
  ;;
esac

msg_info "Setting up Python Environment (${var_backend}, Patience)"
cd /opt/audiomuse-ai
$STD uv venv --seed --python 3.12 /opt/audiomuse-ai/.venv
$STD uv pip install --python /opt/audiomuse-ai/.venv \
  -r "/opt/audiomuse-ai/requirements/${REQ_COMMON}" \
  -r "/opt/audiomuse-ai/requirements/${REQ_ACCEL}"
mkdir -p /opt/audiomuse-ai_data
echo "$var_backend" >/opt/audiomuse-ai_data/.backend
msg_ok "Set up Python Environment (${var_backend})"

MODEL_DIR="/opt/audiomuse-ai_data/model"
MODEL_URL="https://github.com/NeptuneHub/AudioMuse-AI/releases/download/v5.0.0-model"
DCLAP_URL="https://github.com/NeptuneHub/AudioMuse-AI-DCLAP/releases/download/v1"

msg_info "Downloading ML Models (Patience)"
mkdir -p "$MODEL_DIR/huggingface"
for FILE in musicnn_embedding.onnx musicnn_prediction.onnx clap_text_model.onnx; do
  curl -fsSL "${MODEL_URL}/${FILE}" -o "${MODEL_DIR}/${FILE}"
done
for FILE in model_epoch_36.onnx model_epoch_36.onnx.data; do
  curl -fsSL "${DCLAP_URL}/${FILE}" -o "${MODEL_DIR}/${FILE}"
done
for BUNDLE in lyrics_model_whisper lyrics_model_silero_vad lyrics_model_gte_vnni; do
  curl -fsSL "${MODEL_URL}/${BUNDLE}.tar.gz" -o "/tmp/${BUNDLE}.tar.gz"
  tar -xzf "/tmp/${BUNDLE}.tar.gz" -C "$MODEL_DIR"
  rm -f "/tmp/${BUNDLE}.tar.gz"
done
curl -fsSL "${MODEL_URL}/huggingface_models.tar.gz" -o /tmp/huggingface_models.tar.gz
tar -xzf /tmp/huggingface_models.tar.gz -C "${MODEL_DIR}/huggingface"
rm -f /tmp/huggingface_models.tar.gz
HF_HUB_DIR="${MODEL_DIR}/huggingface/hub"
rm -rf "${HF_HUB_DIR}/models--bert-base-uncased" "${HF_HUB_DIR}/models--facebook--bart-base"
if [[ -d "${HF_HUB_DIR}/models--roberta-base" ]]; then
  find "${HF_HUB_DIR}/models--roberta-base/blobs" -type f -size +10M -delete
  find "${HF_HUB_DIR}/models--roberta-base/snapshots" \( -name "model.safetensors" -o -name "pytorch_model.bin" \) -delete
fi
msg_ok "Downloaded ML Models"

msg_info "Configuring AudioMuse-AI"
mkdir -p /opt/audiomuse-ai_data/{temp_audio,ivf_cache,plugins,backup} /opt/audiomuse-ai_data/cache/numba
AUDIOMUSE_PASSWORD=$(openssl rand -base64 18)
JWT_SECRET=$(openssl rand -hex 32)
API_TOKEN=$(openssl rand -hex 32)
cat <<EOF >/opt/audiomuse-ai_data/audiomuse.env
POSTGRES_USER=audiomuse
POSTGRES_PASSWORD=${PG_DB_PASS}
POSTGRES_DB=audiomuse
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
TZ=UTC
AUTH_ENABLED=true
AUDIOMUSE_USER=admin
AUDIOMUSE_PASSWORD=${AUDIOMUSE_PASSWORD}
JWT_SECRET=${JWT_SECRET}
API_TOKEN=${API_TOKEN}
MEDIASERVER_TYPE=jellyfin
JELLYFIN_URL=http://YOUR_JELLYFIN_IP:8096
JELLYFIN_USER_ID=
JELLYFIN_TOKEN=
AI_MODEL_PROVIDER=NONE
APP_DATA_DIR=/opt/audiomuse-ai_data
TEMP_DIR=/opt/audiomuse-ai_data/temp_audio
BACKUP_DIR=/opt/audiomuse-ai_data/backup
RESTORE_LOG_DIR=/opt/audiomuse-ai_data/backup
XDG_CACHE_HOME=/opt/audiomuse-ai_data/cache
NUMBA_CACHE_DIR=/opt/audiomuse-ai_data/cache/numba
HF_HOME=${MODEL_DIR}/huggingface
HF_HUB_DISABLE_XET=1
HF_XET_DISABLE=1
EMBEDDING_MODEL_PATH=${MODEL_DIR}/musicnn_embedding.onnx
PREDICTION_MODEL_PATH=${MODEL_DIR}/musicnn_prediction.onnx
CLAP_AUDIO_MODEL_PATH=${MODEL_DIR}/model_epoch_36.onnx
CLAP_TEXT_MODEL_PATH=${MODEL_DIR}/clap_text_model.onnx
LYRICS_MODEL_DIR=${MODEL_DIR}
LYRICS_WHISPER_MODEL_DIR=${MODEL_DIR}/whisper-small-onnx
SILERO_VAD_ONNX_PATH=${MODEL_DIR}/silero_vad.onnx
LYRICS_GTE_ONNX_PATH=${MODEL_DIR}/gte-multilingual-base-int8.onnx
LYRICS_GTE_TOKENIZER_DIR=${MODEL_DIR}/gte-multilingual-base
EOF
{
  echo ""
  echo "AudioMuse-AI-Credentials"
  echo "Web UI User: admin"
  echo "Web UI Password: ${AUDIOMUSE_PASSWORD}"
} >>~/audiomuse-ai.creds
msg_ok "Configured AudioMuse-AI"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/audiomuse-ai.service
[Unit]
Description=AudioMuse-AI Web (Flask)
After=network-online.target postgresql.service
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/audiomuse-ai
EnvironmentFile=/opt/audiomuse-ai_data/audiomuse.env
ExecStart=/opt/audiomuse-ai/.venv/bin/gunicorn --bind 0.0.0.0:8000 --workers 1 --threads 4 --worker-class gthread --keep-alive 5 --timeout 300 app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/audiomuse-ai-worker.service
[Unit]
Description=AudioMuse-AI Queue Worker (default)
After=network-online.target postgresql.service audiomuse-ai.service
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/audiomuse-ai
EnvironmentFile=/opt/audiomuse-ai_data/audiomuse.env
ExecStart=/opt/audiomuse-ai/.venv/bin/python -u -m taskqueue.worker --queue default
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/audiomuse-ai-worker-high.service
[Unit]
Description=AudioMuse-AI Queue Worker (high)
After=network-online.target postgresql.service audiomuse-ai.service
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/audiomuse-ai
EnvironmentFile=/opt/audiomuse-ai_data/audiomuse.env
ExecStart=/opt/audiomuse-ai/.venv/bin/python -u -m taskqueue.worker --queue high
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/audiomuse-ai-janitor.service
[Unit]
Description=AudioMuse-AI Queue Maintenance
After=network-online.target postgresql.service audiomuse-ai.service
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/audiomuse-ai
EnvironmentFile=/opt/audiomuse-ai_data/audiomuse.env
ExecStart=/opt/audiomuse-ai/.venv/bin/python -u -m taskqueue.maintenance
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/audiomuse-ai-control.service
[Unit]
Description=AudioMuse-AI Config Restart Listener
After=network-online.target postgresql.service audiomuse-ai.service
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/audiomuse-ai
EnvironmentFile=/opt/audiomuse-ai_data/audiomuse.env
ExecStart=/opt/audiomuse-ai/.venv/bin/python -u -m taskqueue.control
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now audiomuse-ai audiomuse-ai-worker audiomuse-ai-worker-high audiomuse-ai-janitor audiomuse-ai-control
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
