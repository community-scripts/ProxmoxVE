#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: rcastley
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
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
    [Yy] | [Yy][Ee][Ss])
        msg_ok "Terms accepted. Proceeding with installation..."
        break
        ;;
    [Nn] | [Nn][Oo] | "")
        msg_error "Terms not accepted. Installation cannot proceed."
        msg_error "Please review the terms and run the script again if you wish to proceed."
        exit 254
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
    exit 250
}
$STD tar -xzf "splunk-enterprise.tgz" -C /opt
rm -f "splunk-enterprise.tgz"
# Splunk Enterprise 10.2 and later will not start as root. The OS account
# must exist before the first start, and it must own $SPLUNK_HOME.
$STD addgroup --system splunk
$STD adduser --system --home /opt/splunk --shell /bin/bash --ingroup splunk --no-create-home splunk
chown -R splunk:splunk /opt/splunk
msg_ok "Setup Splunk Enterprise v${RELEASE}"

msg_info "Creating Splunk admin user"
ADMIN_USER="admin"
ADMIN_PASS=$(random_password 13)
cat <<EOF >~/splunk.creds
Splunk-Credentials
Username: $ADMIN_USER
Password: $ADMIN_PASS
EOF
chmod 600 ~/splunk.creds

install -d -o splunk -g splunk -m 755 /opt/splunk/etc/system/local
cat <<EOF >/opt/splunk/etc/system/local/user-seed.conf
[user_info]
USERNAME = $ADMIN_USER
PASSWORD = $ADMIN_PASS
EOF
chown splunk:splunk /opt/splunk/etc/system/local/user-seed.conf
chmod 600 /opt/splunk/etc/system/local/user-seed.conf
if ! grep -q '^SPLUNK_OS_USER=' /opt/splunk/etc/splunk-launch.conf; then
    echo 'SPLUNK_OS_USER=splunk' >>/opt/splunk/etc/splunk-launch.conf
fi
chown splunk:splunk /opt/splunk/etc/splunk-launch.conf
msg_ok "Created Splunk admin user"

msg_info "Starting Service"
# First-time setup has to run as splunk. Starting the CLI as root is rejected
# on 10.2+, and the default init script would launch splunkd as root at boot.
$STD sudo -H -u splunk /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt
$STD sudo -H -u splunk /opt/splunk/bin/splunk stop --answer-yes --no-prompt
# Writing the systemd unit requires root. User= and Group= in that unit keep
# splunkd running as the splunk account.
$STD /opt/splunk/bin/splunk enable boot-start \
    -systemd-managed 1 \
    -user splunk \
    -group splunk \
    --accept-license \
    --answer-yes \
    --no-prompt
chown -R splunk:splunk /opt/splunk
$STD systemctl daemon-reload
if [[ -f /etc/systemd/system/Splunkd.service ]]; then
    $STD systemctl enable --now Splunkd
else
    $STD systemctl enable --now splunkd
fi
msg_ok "Started Service"

motd_ssh
customize
cleanup_lxc
