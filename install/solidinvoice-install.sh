#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Pierre du Plessis
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/solidinvoice/solidinvoice

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Creating Directories"
mkdir -p /etc/solidinvoice /var/lib/solidinvoice
msg_ok "Created Directories"

fetch_and_deploy_gh_release "solidinvoice" "SolidInvoice/SolidInvoice" "singlefile" "latest" "/usr/bin" "solidinvoice-linux-$(arch_resolve)"

msg_info "Configuring SolidInvoice"
cat <<'EOF' >/etc/solidinvoice/solidinvoice.env
# SolidInvoice environment configuration
# This file is sourced by the systemd service unit.
# CLI flags always take precedence over values set here.

# ------------------------------------------------------------------
# Network
# ------------------------------------------------------------------

# Port to listen on (default: 8765)
#SOLIDINVOICE_PORT=8765

# IP address to bind to (default: auto-detected outbound IP)
#SOLIDINVOICE_SERVER_IP=0.0.0.0

# Domain name — required when using Let's Encrypt or custom certificates.
# When set, the application binds to https://<domain> instead of an IP.
#SOLIDINVOICE_DOMAIN=

# Bind the bundled webserver to every hostname so it answers regardless of the
# Host header — required behind a reverse proxy that forwards the original domain.
SOLIDINVOICE_DOCKER=true

# ------------------------------------------------------------------
# HTTPS / TLS
# ------------------------------------------------------------------

# Disable HTTPS and serve plain HTTP. Set to 1 when running behind a
# reverse proxy (nginx, Caddy, Traefik, etc.) that handles TLS termination.
# Remove or set to 0 when you want the application to manage its own certificates.
SOLIDINVOICE_DISABLE_HTTPS=1

# Enable automatic Let's Encrypt certificates (requires SOLIDINVOICE_DOMAIN).
# Incompatible with SOLIDINVOICE_DISABLE_HTTPS=1.
#SOLIDINVOICE_LETS_ENCRYPT=1

# Paths to a custom TLS certificate and private key (requires SOLIDINVOICE_DOMAIN).
# Incompatible with SOLIDINVOICE_DISABLE_HTTPS=1 and SOLIDINVOICE_LETS_ENCRYPT=1.
#SOLIDINVOICE_SSL_CERT=/etc/ssl/certs/solidinvoice.crt
#SOLIDINVOICE_SSL_KEY=/etc/ssl/private/solidinvoice.key

# ------------------------------------------------------------------
# Performance
# ------------------------------------------------------------------

# Enable FrankenPHP worker mode for improved performance (keeps PHP workers
# alive between requests). Recommended for high-traffic deployments.
# Set to 1 to enable.
#FRANKENPHP_WORKER_MODE=1

# Number of FrankenPHP worker threads when worker mode is enabled (default: 2).
#SOLIDINVOICE_WORKER_THREADS=2

# Number of background messenger worker processes (default: 1).
# Set to 0 to disable built-in workers (use the dedicated 'solidinvoice worker'
# command instead).
#SOLIDINVOICE_MESSENGER_WORKERS=1

# ------------------------------------------------------------------
# Application
# ------------------------------------------------------------------

# Application environment. Change to "dev" only for local development.
#SOLIDINVOICE_ENV=prod

# Enable debug mode (0 or 1). Never enable in production.
#SOLIDINVOICE_DEBUG=0

# Configuration directory — stores generated secrets, OAuth keys, and the
# SQLite database (when no external database is configured).
SOLIDINVOICE_CONFIG_DIR=/etc/solidinvoice

# Installation type identifier used for telemetry when opted in.
SOLIDINVOICE_INSTALL_TYPE=proxmox-community-scripts

# Skip the ASCII art / URL summary printed on startup.
SOLIDINVOICE_SKIP_INTRO=1

# Log format: "json" for structured logs (default for systemd), "console" for human-readable.
SOLIDINVOICE_LOG_FORMAT=json

# ------------------------------------------------------------------
# Database
# ------------------------------------------------------------------

# Database connection URL. Defaults to SQLite stored in SOLIDINVOICE_CONFIG_DIR
# when not set. Supported drivers: mysql, postgresql, sqlite.
#SOLIDINVOICE_DATABASE_URL=mysql://user:password@127.0.0.1:3306/solidinvoice

# ------------------------------------------------------------------
# Email
# ------------------------------------------------------------------

# Outbound mail transport DSN. Overrides the transport configured in the UI.
# See https://symfony.com/doc/current/mailer.html for DSN formats.
#SOLIDINVOICE_MAILER_DSN=smtp://user:password@localhost:25

# From address used for all outgoing emails. Overrides the address configured in the UI.
#SOLIDINVOICE_MAILER_SENDER=SolidInvoice <noreply@example.com>

# ------------------------------------------------------------------
# Async messaging
# ------------------------------------------------------------------

# Messenger transport DSN. Defaults to the database (doctrine) queue.
#SOLIDINVOICE_MESSENGER_DSN=doctrine://default?queue_name=async

# ------------------------------------------------------------------
# Search (optional)
# ------------------------------------------------------------------

# Meilisearch instance for full-text search. Leave blank to disable.
#SOLIDINVOICE_MEILISEARCH_URL=http://localhost:7700
#SOLIDINVOICE_MEILISEARCH_API_KEY=

# ------------------------------------------------------------------
# Localisation
# ------------------------------------------------------------------

# Default locale for the application interface (e.g. en, fr, de, nl).
#SOLIDINVOICE_LOCALE=en

# ------------------------------------------------------------------
# User registration
# ------------------------------------------------------------------

# Allow visitors to create their own accounts (0 = disabled, 1 = enabled).
#SOLIDINVOICE_ALLOW_REGISTRATION=0

# ------------------------------------------------------------------
# Monitoring (optional)
# ------------------------------------------------------------------

# Sentry DSN for error and performance monitoring.
#SOLIDINVOICE_SENTRY_DSN=

# Expose a Prometheus metrics endpoint on a dedicated port.
#SOLIDINVOICE_ENABLE_METRICS=1
#SOLIDINVOICE_METRICS_PORT=9090
EOF
chmod 640 /etc/solidinvoice/solidinvoice.env
msg_ok "Configured SolidInvoice"

msg_info "Creating Service"
cat <<'EOF' >/etc/systemd/system/solidinvoice.service
[Unit]
Description=SolidInvoice
Documentation=https://solidinvoice.co/docs
After=network.target

[Service]
Type=exec
User=root
WorkingDirectory=/var/lib/solidinvoice
ExecStart=/usr/bin/solidinvoice run
EnvironmentFile=/etc/solidinvoice/solidinvoice.env
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now solidinvoice
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
