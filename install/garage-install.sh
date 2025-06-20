#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: phillarson-xyz
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://garagehq.deuxfleurs.fr/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apk add --no-cache curl bash wget openssl iptables ip6tables
msg_ok "Dependencies Installed"

msg_info "Installing Garage"
GARAGE_VERSION="v1.0.1"
ARCH="x86_64-unknown-linux-musl"
$STD wget -q "https://garagehq.deuxfleurs.fr/_releases/${GARAGE_VERSION}/${ARCH}/garage" -O /usr/local/bin/garage
chmod +x /usr/local/bin/garage
echo "${GARAGE_VERSION}" >/opt/${APPLICATION}_version.txt
msg_ok "Garage Installed"

msg_info "Creating Garage User and Directories"
adduser -D -s /bin/sh -h /var/lib/garage garage 2>/dev/null || true
mkdir -p /etc/garage /var/lib/garage/meta /var/lib/garage/data
chown -R garage:garage /etc/garage /var/lib/garage
msg_ok "User and Directories Created"

msg_info "Generating Configuration"
NODE_ID=$(cat /proc/sys/kernel/random/uuid)
RPC_SECRET=$(openssl rand -hex 32)
ADMIN_TOKEN=$(openssl rand -hex 32)
CONTAINER_IP=$(ip -4 addr show eth0 | awk '/inet / {print $2}' | cut -d'/' -f1)

cat > /etc/garage/garage.toml << EOF
metadata_dir = "/var/lib/garage/meta"
data_dir = "/var/lib/garage/data"
db_engine = "lmdb"

replication_factor = 1

rpc_bind_addr = "[::]:3901"
rpc_public_addr = "${CONTAINER_IP}:3901"
rpc_secret = "${RPC_SECRET}"

[s3_api]
s3_region = "garage"
api_bind_addr = "[::]:3900"
root_domain = ".s3.garage.local"

[s3_web]
bind_addr = "[::]:3902"
root_domain = ".web.garage.local"

[admin]
api_bind_addr = "[::]:3903"
admin_token = "${ADMIN_TOKEN}"
EOF

chown garage:garage /etc/garage/garage.toml
msg_ok "Configuration Generated"

msg_info "Creating Service"
cat > /etc/init.d/garage << 'EOFSVC'
#!/sbin/openrc-run

name="garage"
description="Garage S3-compatible storage"
command="/usr/local/bin/garage"
command_args="-c /etc/garage/garage.toml server"
command_background=true
pidfile="/run/garage.pid"
output_log="/var/log/garage.log"
error_log="/var/log/garage.log"

depend() {
    need net
}

start_pre() {
    checkpath -d -o garage:garage /var/lib/garage
    checkpath -f -o garage:garage /var/log/garage.log
}
EOFSVC

chmod +x /etc/init.d/garage
rc-update add garage default
msg_ok "Service Created"

msg_info "Starting Garage"
rc-service garage start
sleep 10
msg_ok "Garage Started"

msg_info "Initializing Cluster"
NODE_ID=$(/usr/local/bin/garage -c /etc/garage/garage.toml node id -q 2>/dev/null | cut -d'@' -f1)
if [ -n "$NODE_ID" ] && [ "$NODE_ID" != "unknown" ]; then
    /usr/local/bin/garage -c /etc/garage/garage.toml layout assign -z dc1 -c 1T ${NODE_ID} || true
    /usr/local/bin/garage -c /etc/garage/garage.toml layout apply --version 1 || true
    sleep 5
    
    msg_info "Creating Initial Access Key"
    GARAGE_KEY_INFO=$(/usr/local/bin/garage -c /etc/garage/garage.toml key create garage-admin 2>/dev/null || echo "")
    if [ -n "$GARAGE_KEY_INFO" ]; then
        KEY_ID=$(echo "$GARAGE_KEY_INFO" | grep "Key ID:" | awk '{print $3}')
        SECRET_KEY=$(echo "$GARAGE_KEY_INFO" | grep "Secret key:" | awk '{print $3}')
        
        # Create initial bucket
        /usr/local/bin/garage -c /etc/garage/garage.toml bucket create data || true
        /usr/local/bin/garage -c /etc/garage/garage.toml bucket allow --read --write data --key ${KEY_ID} || true
        
        cat > /root/garage-credentials.txt << EOF
=== Garage S3 Storage Credentials ===

Admin Token: ${ADMIN_TOKEN}
Access Key ID: ${KEY_ID}
Secret Access Key: ${SECRET_KEY}
Default Bucket: data

=== Endpoints ===
S3 API: http://${CONTAINER_IP}:3900
Admin API: http://${CONTAINER_IP}:3903  
Web Interface: http://${CONTAINER_IP}:3902

=== Usage Examples ===
# AWS CLI Configuration:
aws configure set aws_access_key_id ${KEY_ID}
aws configure set aws_secret_access_key ${SECRET_KEY}
aws configure set default.region garage
aws configure set default.s3.endpoint_url http://${CONTAINER_IP}:3900

# Test with AWS CLI:
aws s3 ls s3://data/

=== Next Steps ===
1. Configure your S3 client to use the endpoint above
2. Use the Access Key ID and Secret Access Key for authentication
3. Access the admin interface at http://${CONTAINER_IP}:3903 with admin token
4. View cluster status: garage -c /etc/garage/garage.toml status
EOF
        chmod 600 /root/garage-credentials.txt
        msg_ok "Access Key Created"
    fi
fi
msg_ok "Cluster Initialized"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /tmp/*
msg_ok "Cleaned"