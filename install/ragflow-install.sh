#!/usr/bin/env bash

# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/infiniflow/ragflow

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# ==============================================================================
# RAGFlow Bare-Metal Installation Script
# ==============================================================================
# This script installs RAGFlow with all dependencies directly on the LXC container:
# - MariaDB (MySQL-compatible, metadata storage)
# - Elasticsearch 8.11 (document/vector search)
# - Redis (caching)
# - MinIO (object storage)
# - Python 3.12 (backend)
# - Node.js 22 (frontend build)
# - Nginx (frontend reverse proxy)
# ==============================================================================

# ==============================================================================
# SYSTEM PREPARATION
# ==============================================================================

msg_info "Configuring System Parameters for Elasticsearch"
# Elasticsearch requires vm.max_map_count >= 262144
if [[ $(sysctl -n vm.max_map_count) -lt 262144 ]]; then
  sysctl -w vm.max_map_count=262144
  echo "vm.max_map_count=262144" >>/etc/sysctl.conf
fi
msg_ok "Configured System Parameters"

# ==============================================================================
# DEPENDENCIES INSTALLATION
# ==============================================================================

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  wget \
  git \
  gnupg \
  apt-transport-https \
  ca-certificates \
  lsb-release \
  build-essential \
  libjemalloc-dev \
  pkg-config \
  libmariadb-dev \
  libmariadb-dev-compat \
  default-libmysqlclient-dev \
  libpq-dev \
  libssl-dev \
  libffi-dev \
  libxml2-dev \
  libxslt1-dev \
  libjpeg-dev \
  libpng-dev \
  zlib1g-dev \
  libtiff-dev \
  libfreetype6-dev \
  liblcms2-dev \
  libwebp-dev \
  libharfbuzz-dev \
  libfribidi-dev \
  libxcb1-dev \
  libgl1 \
  libglib2.0-dev \
  libopenblas-dev \
  liblapack-dev \
  gfortran \
  ffmpeg \
  poppler-utils \
  tesseract-ocr \
  tesseract-ocr-eng \
  tesseract-ocr-chi-sim \
  libreoffice-writer \
  libreoffice-calc \
  libreoffice-impress \
  antiword \
  catdoc \
  html2text \
  unrtf \
  pandoc
msg_ok "Installed Dependencies"

# ==============================================================================
# DATABASE SETUP (MariaDB)
# ==============================================================================

# Install MariaDB server first
setup_mariadb

MARIADB_DB_NAME="rag_flow"
MARIADB_DB_USER="rag_flow"
setup_mariadb_db

# Configure MariaDB for RAGFlow
msg_info "Configuring MariaDB for RAGFlow"
$STD mysql -u root -e "SET GLOBAL max_allowed_packet=1073741824;"
cat <<EOF >/etc/mysql/mariadb.conf.d/ragflow.cnf
[mariadb]
max_allowed_packet=1073741824
max_connections=900
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
EOF
systemctl restart mariadb
msg_ok "Configured MariaDB"

# ==============================================================================
# REDIS INSTALLATION
# ==============================================================================

msg_info "Installing Redis"
REDIS_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c16)

$STD apt-get install -y redis-server

# Stop Redis if running to apply new configuration
systemctl stop redis-server 2>/dev/null || true

# Write Redis configuration with password
cat <<EOF >/etc/redis/redis.conf
bind 127.0.0.1
port 6379
requirepass ${REDIS_PASS}
maxmemory 2gb
maxmemory-policy allkeys-lru
daemonize no
supervised systemd
logfile /var/log/redis/redis-server.log
dir /var/lib/redis
EOF

mkdir -p /var/log/redis
chown -R redis:redis /var/log/redis /var/lib/redis

# Enable and start Redis with new configuration
systemctl enable -q redis-server
systemctl start redis-server

# Wait for Redis to be ready and verify password works
for i in {1..30}; do
  if redis-cli -a "${REDIS_PASS}" ping 2>/dev/null | grep -q "PONG"; then
    break
  fi
  sleep 1
done
msg_ok "Redis Installed"

# ==============================================================================
# ELASTICSEARCH INSTALLATION
# ==============================================================================

msg_info "Installing Elasticsearch 8.11"
ES_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c16)

# Add Elasticsearch repository
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elasticsearch.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" >/etc/apt/sources.list.d/elasticsearch.list
$STD apt-get update
$STD apt-get install -y elasticsearch=8.11.3

# Configure Elasticsearch for single-node
cat <<EOF >/etc/elasticsearch/elasticsearch.yml
cluster.name: ragflow-cluster
node.name: ragflow-node-1
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 127.0.0.1
http.port: 9200
discovery.type: single-node
xpack.security.enabled: true
xpack.security.enrollment.enabled: false
xpack.security.http.ssl.enabled: false
xpack.security.transport.ssl.enabled: false
xpack.license.self_generated.type: basic
indices.query.bool.max_clause_count: 262144
search.max_buckets: 100000
EOF

# Configure JVM heap (use 4GB for 16GB+ RAM systems)
ES_HEAP="4g"
if [[ $(free -m | awk '/Mem:/ {print $2}') -lt 16384 ]]; then
  ES_HEAP="2g"
fi
echo "-Xms${ES_HEAP}" >/etc/elasticsearch/jvm.options.d/heap.options
echo "-Xmx${ES_HEAP}" >>/etc/elasticsearch/jvm.options.d/heap.options

# Configure system limits for Elasticsearch
cat <<EOF >/etc/security/limits.d/elasticsearch.conf
elasticsearch soft nofile 65535
elasticsearch hard nofile 65535
elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited
EOF

# Create data and log directories
mkdir -p /var/lib/elasticsearch /var/log/elasticsearch
chown -R elasticsearch:elasticsearch /var/lib/elasticsearch /var/log/elasticsearch

systemctl enable -q --now elasticsearch

# Wait for Elasticsearch to be ready
for i in {1..60}; do
  if curl -s http://localhost:9200/_cluster/health 2>/dev/null | grep -q '"status"'; then
    break
  fi
  sleep 2
done

# Set Elasticsearch password
echo -e "${ES_PASS}\n${ES_PASS}" | $STD /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i -b 2>/dev/null || true
msg_ok "Elasticsearch Installed"

# ==============================================================================
# MINIO INSTALLATION
# ==============================================================================

msg_info "Installing MinIO"
MINIO_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c16)

# Download MinIO binary
curl -fsSL https://dl.min.io/server/minio/release/linux-amd64/minio -o /usr/local/bin/minio
chmod +x /usr/local/bin/minio

# Create MinIO directories
mkdir -p /var/lib/minio/data

# Create MinIO service (run as root in LXC)
cat <<EOF >/etc/systemd/system/minio.service
[Unit]
Description=MinIO Object Storage
After=network.target
Wants=network-online.target

[Service]
Type=notify
Environment="MINIO_ROOT_USER=rag_flow"
Environment="MINIO_ROOT_PASSWORD=${MINIO_PASS}"
Environment="MINIO_BROWSER=on"
ExecStart=/usr/local/bin/minio server /var/lib/minio/data --console-address ":9001"
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now minio

# Wait for MinIO to be ready
for i in {1..30}; do
  if curl -s http://localhost:9000/minio/health/live 2>/dev/null | grep -q .; then
    break
  fi
  sleep 1
done
msg_ok "MinIO Installed"

# ==============================================================================
# RAGFLOW INSTALLATION
# ==============================================================================

msg_info "Downloading RAGFlow"
fetch_and_deploy_gh_release "ragflow" "infiniflow/ragflow" "tarball" "v0.24.0" "/opt/ragflow"
msg_ok "Downloaded RAGFlow"

# ==============================================================================
# PYTHON ENVIRONMENT
# ==============================================================================

PYTHON_VERSION="3.12" setup_uv

msg_info "Installing Python Dependencies"
cd /opt/ragflow || exit
export UV_SYSTEM_PYTHON=1
$STD /usr/local/bin/uv sync --python 3.12 --frozen --index-strategy unsafe-best-match
$STD /usr/local/bin/uv run download_deps.py
msg_ok "Installed Python Dependencies"

# ==============================================================================
# RAGFLOW CONFIGURATION
# ==============================================================================

msg_info "Creating RAGFlow Configuration"

mkdir -p /opt/ragflow/conf /opt/ragflow/data /opt/ragflow/logs

cat <<EOF >/opt/ragflow/conf/service_conf.yaml
ragflow:
  host: 0.0.0.0
  http_port: 9380
admin:
  host: 0.0.0.0
  http_port: 9381
mysql:
  name: 'rag_flow'
  user: 'rag_flow'
  password: '${MARIADB_DB_PASS}'
  host: 'localhost'
  port: 3306
  max_connections: 900
  stale_timeout: 300
  max_allowed_packet: 1073741824
minio:
  user: 'rag_flow'
  password: '${MINIO_PASS}'
  host: 'localhost:9000'
  bucket: 'ragflow'
  prefix_path: ''
es:
  hosts: 'http://localhost:9200'
  username: 'elastic'
  password: '${ES_PASS}'
redis:
  db: 1
  username: ''
  password: '${REDIS_PASS}'
  host: 'localhost:6379'
user_default_llm:
  default_models:
    embedding_model:
      api_key: 'xxx'
      base_url: 'http://localhost:6380'
EOF

cat <<EOF >/opt/ragflow/.env
DOC_ENGINE=elasticsearch
DEVICE=cpu
COMPOSE_PROFILES=elasticsearch,cpu
STACK_VERSION=8.11.3
ES_HOST=localhost
ES_PORT=9200
ELASTIC_PASSWORD=${ES_PASS}
MYSQL_PASSWORD=${MARIADB_DB_PASS}
MYSQL_HOST=localhost
MYSQL_DBNAME=rag_flow
MYSQL_PORT=3306
MINIO_HOST=localhost
MINIO_PORT=9000
MINIO_USER=rag_flow
MINIO_PASSWORD=${MINIO_PASS}
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=${REDIS_PASS}
SVR_WEB_HTTP_PORT=80
SVR_WEB_HTTPS_PORT=443
SVR_HTTP_PORT=9380
ADMIN_SVR_HTTP_PORT=9381
SVR_MCP_PORT=9382
RAGFLOW_IMAGE=infiniflow/ragflow:v0.24.0
TZ=UTC
REGISTER_ENABLED=1
THREAD_POOL_MAX_WORKERS=128
EOF

msg_ok "Created RAGFlow Configuration"

# ==============================================================================
# SYSTEMD SERVICES
# ==============================================================================

msg_info "Creating Systemd Services"

cat <<EOF >/etc/systemd/system/ragflow-server.service
[Unit]
Description=RAGFlow Backend Server
After=network.target mariadb.service elasticsearch.service redis-server.service minio.service
Requires=mariadb.service elasticsearch.service redis-server.service minio.service

[Service]
Type=simple
WorkingDirectory=/opt/ragflow
Environment=PYTHONPATH=/opt/ragflow
Environment=LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/
Environment=NLTK_DATA=/opt/ragflow/nltk_data
ExecStartPre=/bin/sleep 10
ExecStart=/usr/local/bin/uv run --index-strategy unsafe-best-match python api/ragflow_server.py
Restart=on-failure
RestartSec=10
TimeoutStartSec=300
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/ragflow-task-executor.service
[Unit]
Description=RAGFlow Task Executor
After=network.target mariadb.service elasticsearch.service redis-server.service minio.service ragflow-server.service
Requires=mariadb.service elasticsearch.service redis-server.service minio.service

[Service]
Type=simple
WorkingDirectory=/opt/ragflow
Environment=PYTHONPATH=/opt/ragflow
Environment=LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/
Environment=NLTK_DATA=/opt/ragflow/nltk_data
ExecStart=/usr/local/bin/uv run --index-strategy unsafe-best-match python rag/svr/task_executor.py 0
Restart=on-failure
RestartSec=10
TimeoutStartSec=300
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

msg_ok "Created Systemd Services"

# ==============================================================================
# NGINX FRONTEND
# ==============================================================================

msg_info "Setting up Nginx Frontend"
$STD apt-get install -y nginx

NODE_VERSION="22" setup_nodejs

msg_info "Building RAGFlow Frontend"
mkdir -p /var/www/ragflow
cd /opt/ragflow/web || exit
$STD npm install
$STD npm run build
cp -r /opt/ragflow/web/dist/* /var/www/ragflow/
msg_ok "Built RAGFlow Frontend"

cat <<EOF >/etc/nginx/sites-available/ragflow.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    client_max_body_size 1G;

    location / {
        root /var/www/ragflow;
        try_files \$uri \$uri/ /index.html;
    }

    location /v1/ {
        proxy_pass http://127.0.0.1:9380/v1/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:9380/api/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
    }

    location /docs/ {
        proxy_pass http://127.0.0.1:9380/docs/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /static/ {
        alias /var/www/ragflow/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

$STD rm -f /etc/nginx/sites-enabled/default
$STD ln -sf /etc/nginx/sites-available/ragflow.conf /etc/nginx/sites-enabled/
$STD systemctl enable -q --now nginx
msg_ok "Nginx Frontend Configured"

# ==============================================================================
# START SERVICES
# ==============================================================================

msg_info "Starting RAGFlow Services"
systemctl start ragflow-server
sleep 5
systemctl start ragflow-task-executor
msg_ok "Started RAGFlow Services"

# ==============================================================================
# FINALIZATION
# ==============================================================================

motd_ssh
customize
cleanup_lxc

msg_ok "Completed Successfully!\n"
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo -e "${CREATING}${GN}RAGFlow has been successfully installed!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${LOCAL_IP}:80${CL}"
echo -e "${INFO}${YW} API endpoint: http://${LOCAL_IP}:9380${CL}"
echo -e "${INFO}${YW} MinIO Console: http://${LOCAL_IP}:9001${CL}"
echo -e ""
echo -e "${INFO}${YW} Credentials:${CL}"
echo -e "${TAB}- MariaDB User: rag_flow"
echo -e "${TAB}- MariaDB Password: ${MARIADB_DB_PASS}"
echo -e "${TAB}- Elasticsearch Password: ${ES_PASS}"
echo -e "${TAB}- Redis Password: ${REDIS_PASS}"
echo -e "${TAB}- MinIO User: rag_flow"
echo -e "${TAB}- MinIO Password: ${MINIO_PASS}"
echo -e ""
echo -e "${INFO}${YW} Configuration files:${CL}"
echo -e "${TAB}- /opt/ragflow/conf/service_conf.yaml"
echo -e "${TAB}- /opt/ragflow/.env"
echo -e ""
echo -e "${INFO}${YW} Important Notes:${CL}"
echo -e "${TAB}- Configure your LLM API key in the web interface"
echo -e "${TAB}- Default uses CPU for document processing"
echo -e "${TAB}- For GPU acceleration, additional configuration required"
echo -e "${TAB}- Elasticsearch may take 1-2 minutes to fully initialize"
