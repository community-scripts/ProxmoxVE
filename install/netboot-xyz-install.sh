#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://netboot.xyz

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  nginx \
  tftpd-hpa
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "netboot-xyz" "netbootxyz/netboot.xyz" "prebuild" "latest" "/var/www/html" "menus.tar.gz"

# x86_64 UEFI bootloaders
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-efi" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz.efi"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-efi-dsk" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz.efi.dsk"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-snp" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-snp.efi"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-snp-dsk" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-snp.efi.dsk"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-snponly" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-snponly.efi"
# x86_64 metal (code-signed) UEFI bootloaders
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal.efi"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal-dsk" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal.efi.dsk"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal-snp" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal-snp.efi"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal-snp-dsk" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal-snp.efi.dsk"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal-snponly" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal-snponly.efi"
# x86_64 BIOS/Legacy bootloaders
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-kpxe" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz.kpxe"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-undionly" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-undionly.kpxe"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal-kpxe" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal.kpxe"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-lkrn" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz.lkrn"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-linux-bin" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-linux.bin"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-dsk" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz.dsk"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-pdsk" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz.pdsk"
# ARM64 bootloaders
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-arm64" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-arm64.efi"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-arm64-snp" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-arm64-snp.efi"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-arm64-snponly" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-arm64-snponly.efi"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal-arm64" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal-arm64.efi"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal-arm64-snp" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal-arm64-snp.efi"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal-arm64-snponly" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal-arm64-snponly.efi"
# ISO and IMG images (for virtual/physical media creation)
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-iso" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz.iso"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-img" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz.img"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-arm64-iso" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-arm64.iso"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-arm64-img" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-arm64.img"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-multiarch-iso" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-multiarch.iso"
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-multiarch-img" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-multiarch.img"
# SHA256 checksums
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-checksums" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-sha256-checksums.txt"

msg_info "Configuring Webserver"
rm -f /etc/nginx/sites-enabled/default
cat <<'EOF' >/etc/nginx/sites-available/netboot-xyz
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    server_name _;

    location / {
        autoindex on;
        add_header Access-Control-Allow-Origin "*";
        add_header Access-Control-Allow-Headers "Content-Type";
    }

    # The index.html from menus.tar.gz links bootloaders under /ipxe/ —
    # serve them from the same root directory via alias
    location /ipxe/ {
        alias /var/www/html/;
        autoindex on;
        add_header Access-Control-Allow-Origin "*";
    }
}
EOF
ln -sf /etc/nginx/sites-available/netboot-xyz /etc/nginx/sites-enabled/netboot-xyz
$STD systemctl reload nginx
msg_ok "Configured Webserver"

msg_info "Configuring TFTP Server"
cat <<EOF >/etc/default/tftpd-hpa
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/var/www/html"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure"
EOF
systemctl enable -q --now tftpd-hpa
msg_ok "Configured TFTP Server"

motd_ssh
customize
cleanup_lxc
