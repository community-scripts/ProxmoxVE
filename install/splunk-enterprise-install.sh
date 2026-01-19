#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: rcastley
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://www.splunk.com/en_us/download.html

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

echo -e "${TAB3}┌─────────────────────────────────────────────────────────────────────────┐"
echo -e "${TAB3}│                          SPLUNK GENERAL TERMS                           │"
echo -e "${TAB3}└─────────────────────────────────────────────────────────────────────────┘"
echo ""
echo -e "${TAB3}Before proceeding with the Splunk Enterprise installation, you must"
echo -e "${TAB3}review and accept the Splunk General Terms."
echo ""
echo -e "${TAB3}Please review the terms at:"
echo -e "${TAB3}${GATEWAY}${BGN}https://www.splunk.com/en_us/legal/splunk-general-terms.html${CL}"
echo ""

while true; do
    echo -e "${TAB3}Do you accept the Splunk General Terms? (y/N): \c"
    read -r response
    case $response in
        [Yy]|[Yy][Ee][Ss])
            msg_ok "Terms accepted. Proceeding with installation..."
            break
            ;;
        [Nn]|[Nn][Oo]|"")
            msg_error "Terms not accepted. Installation cannot proceed."
            msg_error "Please review the terms and run the script again if you wish to proceed."
            exit 1
            ;;
        *)
            msg_error "Invalid response. Please enter 'y' for yes or 'n' for no."
            ;;
    esac
done

msg_info "Setup Splunk Enterprise"
DOWNLOAD_URL=$(curl -s "https://www.splunk.com/en_us/download/splunk-enterprise.html" | grep -o 'data-link="[^"]*' | sed 's/data-link="//' | grep "https.*products/splunk/releases" | grep "linux-amd64\.tgz$")
RELEASE=$(echo "$DOWNLOAD_URL" | sed 's|.*/releases/\([^/]*\)/.*|\1|')
$STD curl -fsSL -o "splunk-enterprise.tgz" "$DOWNLOAD_URL" || {
    msg_error "Failed to download Splunk Enterprise from the provided link."
    exit 1
}
$STD tar -xzf "splunk-enterprise.tgz" -C /opt
rm -f "splunk-enterprise.tgz"
addgroup --system splunk
adduser --system --home /opt/splunk --shell /bin/bash --ingroup splunk --no-create-home splunk
chown -R splunk:splunk /opt/splunk
msg_ok "Setup Splunk Enterprise v${RELEASE}"

msg_info "Creating Splunk admin user"
ADMIN_USER="admin"
ADMIN_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
{
    echo "Splunk-Credentials"
    echo "Username: $ADMIN_USER"
    echo "Password: $ADMIN_PASS"
} >> ~/splunk.creds

cat << EOF > "/opt/splunk/etc/system/local/user-seed.conf"
[user_info]
USERNAME = $ADMIN_USER
PASSWORD = $ADMIN_PASS
EOF
msg_ok "Created Splunk admin user"

msg_info "Starting Service"
$STD sudo -u splunk /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt
$STD /opt/splunk/bin/splunk enable boot-start -user splunk
msg_ok "Started Service"

motd_ssh
customize
cleanup_lxc
