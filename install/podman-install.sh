#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

if $STD mount | grep 'on / type zfs' > null && echo "ZFS"; then
    msg_info "Enabling ZFS support."
    cat <<'EOF' >/usr/local/bin/overlayzfsmount
#!/bin/sh
exec /bin/mount -t overlay overlay "$@"
EOF
    chmod +x /usr/local/bin/overlayzfsmount
    cat <<'EOF' >/etc/containers/storage.conf
[storage]
driver = "overlay"
runroot = "/run/containers/storage"
graphroot = "/var/lib/containers/storage"

[storage.options]
pull_options = {enable_partial_images = "false", use_hard_links = "false", ostree_repos=""}
mount_program = "/usr/local/bin/overlayzfsmount"

[storage.options.overlay]
mountopt = "nodev"
EOF
fi

msg_info "Installing Podman"
$STD apt-get -y install podman
$STD systemctl enable --now podman.socket
echo -e 'unqualified-search-registries=["docker.io"]' >> /etc/containers/registries.conf
msg_ok "Installed Podman"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
