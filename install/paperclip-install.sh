#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Fabian Pulch (fpulch)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/paperclipai/paperclip

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
    ripgrep
msg_ok "Installed Dependencies"

NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs
PG_VERSION="17" setup_postgresql
PG_DB_NAME="paperclip" PG_DB_USER="paperclip" setup_postgresql_db

fetch_and_deploy_gh_release "paperclip-ai" "paperclipai/paperclip" "tarball"

msg_info "Building Paperclip"
cd /opt/paperclip-ai
export HUSKY=0
export NODE_OPTIONS="--max-old-space-size=8192"
$STD pnpm install --frozen-lockfile
$STD pnpm build
unset NODE_OPTIONS
msg_ok "Built Paperclip"

msg_info "Installing Agent CLIs"
$STD npm install -g \
    @anthropic-ai/claude-code@latest \
    @openai/codex@latest
msg_ok "Installed Agent CLIs"

msg_info "Configuring Paperclip"
PAPERCLIP_HOME="/opt/paperclip-data"
PAPERCLIP_CONFIG="${PAPERCLIP_HOME}/instances/default/config.json"

mkdir -p /opt/paperclip-data
mkdir -p /root/.claude /root/.codex
BETTER_AUTH_SECRET=$(openssl rand -hex 32)
cat <<EOF >/opt/paperclip-ai/.env
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@127.0.0.1:5432/${PG_DB_NAME}
HOST=0.0.0.0
PORT=3100
SERVE_UI=true
PAPERCLIP_HOME=${PAPERCLIP_HOME}
PAPERCLIP_CONFIG=${PAPERCLIP_CONFIG}
PAPERCLIP_INSTANCE_ID=default
PAPERCLIP_DEPLOYMENT_MODE=authenticated
PAPERCLIP_DEPLOYMENT_EXPOSURE=private
PAPERCLIP_PUBLIC_URL=http://${LOCAL_IP}:3100
BETTER_AUTH_SECRET=${BETTER_AUTH_SECRET}
EOF
msg_ok "Configured Paperclip"

msg_info "Running Database Migrations"
set -a && source /opt/paperclip-ai/.env && set +a
$STD pnpm db:migrate
msg_ok "Ran Database Migrations"

msg_info "Bootstrapping Paperclip"
PAPERCLIP_ONBOARD_LOG=/opt/paperclip-ai/paperclip-onboard.log
PAPERCLIP_BOOTSTRAP_LOG=/opt/paperclip-ai/paperclip-bootstrap.log

for PAPERCLIP_ONBOARD_CMD in \
    "pnpm paperclipai onboard --yes --bind lan" \
    "pnpm paperclipai onboard --yes"; do
    rm -f "$PAPERCLIP_ONBOARD_LOG"
    setsid env \
        PAPERCLIP_HOME="$PAPERCLIP_HOME" \
        PAPERCLIP_CONFIG="$PAPERCLIP_CONFIG" \
        bash -c 'cd /opt/paperclip-ai && exec "$@"' _ $PAPERCLIP_ONBOARD_CMD \
        >"$PAPERCLIP_ONBOARD_LOG" 2>&1 &
    PAPERCLIP_ONBOARD_PID=$!
    for _ in {1..60}; do
        if [[ -f "$PAPERCLIP_CONFIG" ]]; then
            break
        fi
        if ! kill -0 "$PAPERCLIP_ONBOARD_PID" 2>/dev/null; then
            break
        fi
        sleep 2
    done
    if kill -0 "$PAPERCLIP_ONBOARD_PID" 2>/dev/null; then
        kill -- -"${PAPERCLIP_ONBOARD_PID}" >/dev/null 2>&1 || true
        wait "$PAPERCLIP_ONBOARD_PID" 2>/dev/null || true
    fi
    [[ -f "$PAPERCLIP_CONFIG" ]] && break
    if ! grep -q "unknown option '--bind'" "$PAPERCLIP_ONBOARD_LOG"; then
        break
    fi
    msg_info "Retrying Paperclip Onboarding"
done

if [[ ! -f "$PAPERCLIP_CONFIG" ]]; then
    msg_error "Failed to bootstrap Paperclip"
    exit 1
fi

if grep -q 'authenticated' $PAPERCLIP_CONFIG; then
    pnpm paperclipai auth bootstrap-ceo >"$PAPERCLIP_BOOTSTRAP_LOG" 2>&1 || true
    PAPERCLIP_INVITE_URL=$(awk -F'Invite URL: ' '/Invite URL:/ {print $2; exit}' "$PAPERCLIP_BOOTSTRAP_LOG")
    PAPERCLIP_INVITE_EXPIRY=$(awk -F'Expires: ' '/Expires:/ {print $2; exit}' "$PAPERCLIP_BOOTSTRAP_LOG")
    if [[ -n "$PAPERCLIP_INVITE_URL" ]]; then
        cat <<EOF >~/paperclip.creds

Paperclip Admin Invite
Invite URL: ${PAPERCLIP_INVITE_URL}
Expires: ${PAPERCLIP_INVITE_EXPIRY}
EOF
        msg_ok "Generated Paperclip CEO Invite"
        echo -e "${INFO}${YW} Open this invite URL to finish Paperclip admin setup:${CL}"
        echo -e "${GATEWAY}${BGN}${PAPERCLIP_INVITE_URL}${CL}"
        [[ -n "$PAPERCLIP_INVITE_EXPIRY" ]] && echo -e "${TAB}${INFO}${YW}Invite expires: ${PAPERCLIP_INVITE_EXPIRY}${CL}"
    else
        msg_warn "Paperclip authenticated mode is enabled, but no CEO invite was generated automatically"
    fi
else
    msg_info "Paperclip Bootstrapped in Local Trusted Mode"
fi
rm -f "$PAPERCLIP_ONBOARD_LOG" "$PAPERCLIP_BOOTSTRAP_LOG"
msg_ok "Bootstrapped Paperclip"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/paperclip.service
[Unit]
Description=Paperclip
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/paperclip-ai
EnvironmentFile=/opt/paperclip-ai/.env
Environment=HOME=/root
Environment=CODEX_HOME=/root/.codex
Environment=PATH=/root/.local/bin:/usr/local/bin:/usr/bin:/bin
Environment=DISABLE_AUTOUPDATER=1
ExecStart=/usr/bin/env pnpm paperclipai run
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now paperclip
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
