#!/usr/bin/env bash

# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/muety/wakapi | Website: https://wakapi.dev

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  ca-certificates \
  curl
msg_ok "Installed Dependencies"

msg_info "Creating Directories"
mkdir -p /opt/wakapi/bin
mkdir -p /opt/wakapi/data
msg_ok "Created Directories"

msg_info "Downloading Wakapi"
fetch_and_deploy_gh_release "wakapi" "muety/wakapi" "prebuild" "latest" "/opt/wakapi/bin" "wakapi_linux_*.zip"
msg_ok "Downloaded Wakapi"

msg_info "Verifying Installation"
ls -la /opt/wakapi/bin/
chmod +x /opt/wakapi/bin/wakapi
msg_ok "Verified Installation"

msg_info "Generating Configuration"
# Generate a random password salt (avoid SIGPIPE by using openssl)
PASSWORD_SALT=$(openssl rand -hex 16 2>/dev/null || head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)

cat <<EOF >/opt/wakapi/config.yml
env: production
quick_start: false
skip_migrations: false
enable_pprof: false

server:
  listen_ipv4: 0.0.0.0
  listen_ipv6: '-'
  listen_socket:
  listen_socket_mode: 0666
  timeout_sec: 30
  tls_cert_path:
  tls_key_path:
  port: 3000
  base_path: /
  public_url: http://localhost:3000

app:
  leaderboard_enabled: true
  leaderboard_scope: 7_days
  leaderboard_generation_time: '0 0 6 * * *,0 0 18 * * *'
  leaderboard_require_auth: false
  aggregation_time: '0 15 2 * * *'
  report_time_weekly: '0 0 18 * * 5'
  data_cleanup_time: '0 0 6 * * 0'
  optimize_database_time: '0 0 8 1 * *'
  inactive_days: 7
  import_enabled: true
  import_backoff_min: 5
  import_max_rate: 24
  import_batch_size: 50
  heartbeat_max_age: '4320h'
  data_retention_months: -1
  max_inactive_months: 12
  warm_caches: true
  custom_languages:
    vue: Vue
    jsx: JSX
    tsx: TSX
    cjs: JavaScript
    ipynb: Python
    svelte: Svelte
    astro: Astro
  canonical_language_names:
    'java': 'Java'
    'ini': 'INI'
    'xml': 'XML'
    'jsx': 'JSX'
    'tsx': 'TSX'
    'php': 'PHP'
    'yaml': 'YAML'
    'toml': 'TOML'
    'sql': 'SQL'
    'css': 'CSS'
    'scss': 'SCSS'
    'jsp': 'JSP'
    'svg': 'SVG'
    'csv': 'CSV'
  avatar_url_template: api/avatar/{username_hash}.svg
  date_format: Mon, 02 Jan 2006
  datetime_format: Mon, 02 Jan 2006 15:04

db:
  host:
  port:
  socket:
  user:
  password:
  name: /opt/wakapi/data/wakapi.db
  dialect: sqlite3
  charset: utf8mb4
  max_conn: 10
  ssl: false
  compress: false
  automigrate_fail_silently: false

security:
  password_salt: ${PASSWORD_SALT}
  insecure_cookies: true
  cookie_max_age: 172800
  allow_signup: true
  oidc_allow_signup: true
  disable_local_auth: false
  disable_webauthn: true
  signup_captcha: false
  invite_codes: true
  disable_frontpage: false
  expose_metrics: false
  enable_proxy: false
  trusted_header_auth: false
  trusted_header_auth_key: Remote-User
  trusted_header_auth_allow_signup: false
  trust_reverse_proxy_ips:
  signup_max_rate: 5/1h
  login_max_rate: 10/1m
  password_reset_max_rate: 5/1h
  oidc: []

sentry:
  dsn:
  enable_tracing: true
  sample_rate: 0.75
  sample_rate_heartbeats: 0.1

subscriptions:
  enabled: false
  expiry_notifications: true
  stripe_api_key:
  stripe_secret_key:
  stripe_endpoint_secret:
  standard_price_id:

mail:
  enabled: false
  provider: smtp
  sender: Wakapi <wakapi@example.org>
  skip_verify_mx_record: false
  smtp:
    host:
    port:
    username:
    password:
    tls:
EOF
msg_ok "Generated Configuration"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wakapi.service
[Unit]
Description=Wakapi - Coding Statistics
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/wakapi
ExecStart=/opt/wakapi/bin/wakapi -config /opt/wakapi/config.yml
Restart=on-failure
RestartSec=5

# Environment variables
Environment=WAKAPI_PASSWORD_SALT=${PASSWORD_SALT}

# Resource limits
LimitNOFILE=65535
TimeoutStartSec=60
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wakapi
msg_ok "Created Service"

msg_info "Creating Info File"
cat <<EOF >/opt/wakapi/README.md
# Wakapi Installation

Wakapi is a minimalist, self-hosted WakaTime-compatible backend for coding statistics.

## Access

- Web Interface: http://<IP>:3000
- API Endpoint: http://<IP>:3000/api

## Configuration

Configuration file: /opt/wakapi/config.yml
Database: /opt/wakapi/data/wakapi.db

## First Time Setup

1. Access the web interface at http://<IP>:3000
2. Create your account (first user becomes admin)
3. Get your API key from Settings

## WakaTime Client Setup

Edit your ~/.wakatime.cfg file:

[settings]
api_url = http://<IP>:3000/api
api_key = <your-api-key>

## Useful Commands

- Check status: systemctl status wakapi
- Restart: systemctl restart wakapi
- View logs: journalctl -u wakapi -f

## Documentation

- GitHub: https://github.com/muety/wakapi
- Website: https://wakapi.dev
- API Docs: http://<IP>:3000/swagger-ui
EOF
msg_ok "Created Info File"

motd_ssh
customize
cleanup_lxc
