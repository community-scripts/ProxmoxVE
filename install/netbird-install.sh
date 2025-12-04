#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: TechHutTV
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://netbird.io/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

echo ""
echo '  _   _      _   ____  _         _   _     __   _______ '
echo ' | \ | |    | | |  _ \(_)       | | | |    \ \ / / ____|'
echo ' |  \| | ___| |_| |_) |_ _ __ __| | | |     \ V / |     '
echo ' | . ` |/ _ \ __|  _ <| | '\''__/ _` | | |      > <| |     '
echo ' | |\  |  __/ |_| |_) | | | | (_| | | |____ / . \ |____ '
echo ' |_| \_|\___|\__|____/|_|_|  \__,_| |______/_/ \_\_____|'
echo ""

msg_info "Installing Dependencies"
$STD apt install -y \
    curl \
    ca-certificates \
    gnupg
msg_ok "Installed Dependencies"

msg_info "Setting up NetBird Repository"
curl -sSL https://pkgs.netbird.io/debian/public.key \
    | gpg --dearmor -o /usr/share/keyrings/netbird-archive-keyring.gpg
chmod 0644 /usr/share/keyrings/netbird-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/netbird-archive-keyring.gpg] https://pkgs.netbird.io/debian stable main' \
    | tee /etc/apt/sources.list.d/netbird.list > /dev/null
$STD apt update
msg_ok "Set up NetBird Repository"

msg_info "Installing NetBird"
$STD apt install -y netbird
msg_ok "Installed NetBird"

msg_info "Enabling NetBird Service"
$STD netbird service install 2>/dev/null || true
$STD netbird service start 2>/dev/null || true
$STD systemctl enable netbird
msg_ok "Enabled NetBird Service"

# NetBird Connection Setup
echo ""
echo -e "${BL}NetBird Connection Setup${CL}"
echo "─────────────────────────────────────────"
echo "Choose how to connect to your NetBird network:"
echo ""
echo "  1) Setup Key (default) - Use a pre-generated setup key"
echo "  2) SSO Login - Authenticate via browser with your identity provider"
echo "  3) Skip - Configure later with 'netbird up'"
echo ""

read -rp "Select authentication method [1]: " AUTH_METHOD
AUTH_METHOD="${AUTH_METHOD:-1}"

case "$AUTH_METHOD" in
    1)
        # Setup Key authentication
        echo ""
        echo "Enter your NetBird setup key from the NetBird dashboard."
        echo ""
        read -rp "Setup key: " NETBIRD_SETUP_KEY
        echo ""

        if [[ -z "$NETBIRD_SETUP_KEY" ]]; then
            msg_warn "No setup key provided. Run 'netbird up' within the container to connect."
        else
            echo -e "Setup key: ${GN}${NETBIRD_SETUP_KEY}${CL}"
            read -rp "Press Enter to continue or Ctrl+C to cancel..."

            msg_info "Connecting to NetBird with setup key"
            if netbird up -k "$NETBIRD_SETUP_KEY"; then
                msg_ok "Connected to NetBird"
            else
                msg_warn "Connection failed. Run 'netbird up -k <key>' within the container to retry."
            fi
        fi
        ;;
    2)
        # SSO authentication
        echo ""
        echo -e "${BL}SSO Authentication${CL}"
        echo "─────────────────────────────────────────"
        echo "A login URL will appear below."
        echo "Copy the URL and open it in your browser to authenticate."
        echo ""

        msg_info "Starting SSO login"
        netbird login 2>&1 || true
        echo ""

        msg_info "Connecting to NetBird"
        if netbird up; then
            msg_ok "Connected to NetBird"
        else
            msg_warn "Connection failed. Run 'netbird up' within the container to retry."
        fi
        ;;
    3)
        msg_info "Skipping NetBird connection"
        msg_ok "Run 'netbird up' within the container to connect."
        ;;
    *)
        msg_warn "Invalid selection. Run 'netbird up' within the container to connect."
        ;;
esac

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
msg_ok "Cleaned"
