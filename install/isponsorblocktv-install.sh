#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Matthew Stern (sternma) | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dmunozv04/iSponsorBlockTV

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "isponsorblocktv" "dmunozv04/iSponsorBlockTV" "singlefile" "latest" "/opt/isponsorblocktv" "iSponsorBlockTV-x86_64-linux"

msg_info "Setting up iSponsorBlockTV"
install -d /var/lib/isponsorblocktv
msg_ok "Set up iSponsorBlockTV"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/isponsorblocktv.service
[Unit]
Description=iSponsorBlockTV
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
Environment=iSPBTV_data_dir=/var/lib/isponsorblocktv
ExecStart=/opt/isponsorblocktv/isponsorblocktv
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q isponsorblocktv
msg_ok "Created Service"

msg_info "Creating CLI wrapper"
cat <<'EOF' >/usr/local/bin/iSponsorBlockTV
#!/usr/bin/env bash
export iSPBTV_data_dir="/var/lib/isponsorblocktv"

set +e
/opt/isponsorblocktv/isponsorblocktv "$@"
status=$?
set -e

case "${1:-}" in
  setup|setup-cli)
    systemctl restart isponsorblocktv >/dev/null 2>&1 || true
    ;;
esac

exit $status
EOF
chmod +x /usr/local/bin/iSponsorBlockTV
ln -sf /usr/local/bin/iSponsorBlockTV /usr/bin/iSponsorBlockTV
msg_ok "Created CLI wrapper"

motd_ssh
customize
cleanup_lxc
