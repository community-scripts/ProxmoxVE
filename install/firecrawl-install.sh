#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: esatbayhan
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.firecrawl.dev/

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
  ccache \
  cmake \
  git \
  nftables \
  pkg-config \
  procps \
  python3 \
  rabbitmq-server \
  redis-server
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="pnpm@11.4.0" setup_nodejs
RUST_PROFILE="minimal" setup_rust
PG_VERSION="17" PG_MODULES="cron" setup_postgresql

fetch_and_deploy_gh_release "firecrawl" "firecrawl/firecrawl" "tarball" "latest" "/opt/firecrawl"
GO_VERSION="$(grep -m1 '^go ' /opt/firecrawl/apps/api/sharedLibs/go-html-to-md/go.mod | awk '{print $2}')" setup_go

msg_info "Configuring FDB"
FDB_VERSION="$(awk -F= '/^ARG FDB_VERSION=/{print $2; exit}' /opt/firecrawl/apps/api/Dockerfile)"
if [[ -z "$FDB_VERSION" ]]; then
  msg_error "FDB_VERSION pin not found in upstream Dockerfile"
  exit 1
fi
FDB_ARCH="$(get_system_arch)"
[[ "$FDB_ARCH" == "arm64" ]] && FDB_ARCH="aarch64"
fetch_and_deploy_gh_release "foundationdb-clients" "apple/foundationdb" "binary" "$FDB_VERSION" "/opt/foundationdb-clients" "foundationdb-clients_${FDB_VERSION}-1_${FDB_ARCH}.deb"
msg_ok "Configured FDB"

PG_DB_NAME="firecrawl" PG_DB_USER="firecrawl" PG_DB_EXTENSIONS="pgcrypto,pg_cron" PG_DB_CREDS_FILE="/dev/null" setup_postgresql_db

msg_info "Configuring pg_cron"
$STD runuser -u postgres -- psql -c "ALTER SYSTEM SET cron.use_background_workers = 'on';"
systemctl restart postgresql
until runuser -u postgres -- psql -c "SELECT 1;" &>/dev/null; do sleep 1; done
msg_ok "Configured pg_cron"

msg_info "Configuring RabbitMQ"
systemctl enable -q --now rabbitmq-server
until rabbitmqctl status &>/dev/null; do sleep 1; done
RABBITMQ_PASSWORD="$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c24)"
$STD rabbitmqctl add_user firecrawl "$RABBITMQ_PASSWORD"
$STD rabbitmqctl set_permissions -p / firecrawl ".*" ".*" ".*"
msg_ok "Configured RabbitMQ"

systemctl enable -q --now redis-server

msg_info "Importing NuQ Schema"
$STD runuser -u postgres -- psql -d firecrawl -f /opt/firecrawl/apps/nuq-postgres/nuq.sql
$STD runuser -u postgres -- psql -d firecrawl -c "GRANT USAGE ON SCHEMA nuq TO firecrawl;"
$STD runuser -u postgres -- psql -d firecrawl -c "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA nuq TO firecrawl;"
$STD runuser -u postgres -- psql -d firecrawl -c "GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA nuq TO firecrawl;"
$STD runuser -u postgres -- psql -d firecrawl -c "ALTER DEFAULT PRIVILEGES IN SCHEMA nuq GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO firecrawl;"
$STD runuser -u postgres -- psql -d firecrawl -c "ALTER DEFAULT PRIVILEGES IN SCHEMA nuq GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO firecrawl;"
msg_ok "Imported NuQ Schema"

msg_info "Generating Configuration"
cat <<EOF >/opt/firecrawl/.env
ENV=local
HOST=0.0.0.0
PORT=3002
USE_DB_AUTHENTICATION=false
BULL_AUTH_KEY=$(openssl rand -hex 32)
JWT_SECRET=$(openssl rand -hex 32)

REDIS_URL=redis://127.0.0.1:6379
REDIS_RATE_LIMIT_URL=redis://127.0.0.1:6379

PLAYWRIGHT_MICROSERVICE_URL=http://127.0.0.1:3000/scrape

POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_USER=${PG_DB_USER}
POSTGRES_PASSWORD=${PG_DB_PASS}
POSTGRES_DB=${PG_DB_NAME}
NUQ_DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@127.0.0.1:5432/${PG_DB_NAME}
NUQ_DATABASE_URL_LISTEN=postgresql://${PG_DB_USER}:${PG_DB_PASS}@127.0.0.1:5432/${PG_DB_NAME}

NUQ_BACKEND=pg
NUQ_RABBITMQ_URL=amqp://firecrawl:${RABBITMQ_PASSWORD}@127.0.0.1:5672/%2f

WORKER_PORT=3005
EXTRACT_WORKER_PORT=3004
NUQ_WORKER_START_PORT=3006
NUQ_WORKER_COUNT=5
NUQ_PREFETCH_WORKER_PORT=3011
NUQ_RECONCILER_WORKER_PORT=3012
HARNESS_STARTUP_TIMEOUT_MS=60000

LOGGING_LEVEL=INFO
MAX_CONCURRENT_PAGES=10
ALLOW_LOCAL_WEBHOOKS=false
BLOCK_MEDIA=false

OPENAI_API_KEY=
OPENAI_BASE_URL=
OLLAMA_BASE_URL=
MODEL_NAME=
MODEL_EMBEDDING_NAME=
SEARXNG_ENDPOINT=
SEARXNG_ENGINES=
SEARXNG_CATEGORIES=
PROXY_SERVER=
PROXY_USERNAME=
PROXY_PASSWORD=
SELF_HOSTED_WEBHOOK_URL=
SELF_HOSTED_WEBHOOK_HMAC_SECRET=
EOF
chmod 600 /opt/firecrawl/.env
msg_ok "Generated Configuration"

msg_info "Building Go Library"
cd /opt/firecrawl/apps/api/sharedLibs/go-html-to-md
$STD go build -o libhtml-to-markdown.so -buildmode=c-shared html-to-markdown.go
msg_ok "Built Go Library"

msg_info "Building Firecrawl API"
cd /opt/firecrawl/apps/api
$STD pnpm install --frozen-lockfile
$STD pnpm build
CI=true $STD pnpm prune --prod --ignore-scripts
msg_ok "Built Firecrawl API"

msg_info "Building Playwright Service"
cd /opt/firecrawl/apps/playwright-service-ts
$STD npm install
$STD npx playwright install chromium --with-deps
$STD npm run build
$STD npm prune --omit=dev
msg_ok "Built Playwright Service"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/firecrawl-playwright.service
[Unit]
Description=Firecrawl Playwright Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/firecrawl/apps/playwright-service-ts
EnvironmentFile=/opt/firecrawl/.env
Environment=PORT=3000
# /opt/firecrawl/.env also contains the API PORT=3002; force Playwright's private port here.
ExecStart=/usr/bin/env PORT=3000 /usr/bin/node /opt/firecrawl/apps/playwright-service-ts/dist/api.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/firecrawl.service
[Unit]
Description=Firecrawl API and Workers
After=network.target postgresql.service redis-server.service rabbitmq-server.service firecrawl-playwright.service
Requires=postgresql.service redis-server.service rabbitmq-server.service firecrawl-playwright.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/firecrawl/apps/api
EnvironmentFile=/opt/firecrawl/.env
Environment=NODE_ENV=production
# Upstream uses --start-docker to skip install/build and start compiled node dist entrypoints.
ExecStart=/usr/bin/node /opt/firecrawl/apps/api/dist/src/harness.js --start-docker
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now firecrawl-playwright
systemctl enable -q --now firecrawl
msg_ok "Created Services"

msg_info "Configuring Firewall"
cat <<'EOF' >/etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

table inet firecrawl_filter {
  chain input {
    type filter hook input priority 0; policy drop;

    iif "lo" accept
    ct state established,related accept

    ip protocol icmp accept
    ip6 nexthdr icmpv6 accept
    udp sport 67 udp dport 68 accept
    udp sport 547 udp dport 546 accept

    tcp dport { 22, 3002 } accept
  }

  chain forward {
    type filter hook forward priority 0; policy drop;
  }

  chain output {
    type filter hook output priority 0; policy accept;
  }
}
EOF
systemctl enable -q nftables
systemctl restart nftables
msg_ok "Configured Firewall"

motd_ssh
customize
cleanup_lxc
