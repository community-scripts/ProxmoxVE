#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nextcloudpi.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

confirm_external_installer "https://nextcloudpi.com/" "https://raw.githubusercontent.com/nextcloud/nextcloudpi/master/install.sh"

msg_info "Making ssh.service reloads behave like restarts"
mkdir -p /etc/systemd/system/ssh.service.d
cat <<'EOF' >/etc/systemd/system/ssh.service.d/reload-as-restart.conf
[Service]
ExecReload=
ExecReload=/usr/bin/systemd-run --no-block --quiet /bin/systemctl restart ssh.service
EOF
systemctl daemon-reload
msg_ok "Made ssh.service reloads behave like restarts"

msg_info "Installing NextCloudPi (Patience)"
$STD bash <(curl -fsSL https://raw.githubusercontent.com/nextcloud/nextcloudpi/master/install.sh)
msg_ok "Installed NextCloudPi"

motd_ssh
customize
cleanup_lxc
