#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: YourNameHere
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://kafka.apache.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# ----------------------------------------------------------------------------
# Base dependencies
# ----------------------------------------------------------------------------
msg_info "Installing Dependencies"
$STD apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    netcat-openbsd \
    jq
msg_ok "Installed Dependencies"

# ----------------------------------------------------------------------------
# Java runtime — Kafka 4.x requires JDK 17+; Debian 12 ships OpenJDK 17
# ----------------------------------------------------------------------------
msg_info "Installing OpenJDK 17"
$STD apt-get install -y openjdk-17-jre-headless
JAVA_HOME=$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")
echo "JAVA_HOME=${JAVA_HOME}" >/etc/environment
msg_ok "Installed OpenJDK 17"

# ----------------------------------------------------------------------------
# Kafka user — never run brokers as root
# ----------------------------------------------------------------------------
msg_info "Creating kafka system user"
groupadd --system kafka 2>/dev/null || true
useradd --system --gid kafka --home-dir /opt/kafka \
        --shell /usr/sbin/nologin kafka 2>/dev/null || true
msg_ok "Created kafka system user"

# ----------------------------------------------------------------------------
# Download latest stable Kafka from Apache
# ----------------------------------------------------------------------------
msg_info "Resolving latest Kafka release"
KAFKA_VERSION=$(curl -fsSL https://downloads.apache.org/kafka/ \
    | grep -oP '(?<=href=")[0-9]+\.[0-9]+\.[0-9]+(?=/")' \
    | sort -V | tail -1)
SCALA_VERSION="2.13"
TARBALL="kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
msg_ok "Resolved Kafka v${KAFKA_VERSION}"

msg_info "Downloading Kafka v${KAFKA_VERSION}"
cd /tmp
curl -fsSLO "https://downloads.apache.org/kafka/${KAFKA_VERSION}/${TARBALL}"
msg_ok "Downloaded Kafka v${KAFKA_VERSION}"

msg_info "Installing Kafka to /opt/kafka"
tar -xzf "${TARBALL}" -C /opt
mv "/opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}" /opt/kafka
rm -f "/tmp/${TARBALL}"
echo "${KAFKA_VERSION}" >/opt/kafka/.version
mkdir -p /var/lib/kafka/data /var/log/kafka
chown -R kafka:kafka /opt/kafka /var/lib/kafka /var/log/kafka
msg_ok "Installed Kafka"

# ----------------------------------------------------------------------------
# KRaft single-node config: combined broker + controller
# ----------------------------------------------------------------------------
msg_info "Configuring KRaft broker"
NODE_ID=1
LISTENER_PORT=9092
CONTROLLER_PORT=9093
HOST_IP=$(hostname -I | awk '{print $1}')

cat >/opt/kafka/config/server.properties <<EOF
# ---- Process roles (combined mode for single-node) -------------------------
process.roles=broker,controller
node.id=${NODE_ID}
controller.quorum.voters=${NODE_ID}@localhost:${CONTROLLER_PORT}

# ---- Listeners --------------------------------------------------------------
listeners=PLAINTEXT://0.0.0.0:${LISTENER_PORT},CONTROLLER://0.0.0.0:${CONTROLLER_PORT}
advertised.listeners=PLAINTEXT://${HOST_IP}:${LISTENER_PORT}
inter.broker.listener.name=PLAINTEXT
controller.listener.names=CONTROLLER
listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL

# ---- Storage ----------------------------------------------------------------
log.dirs=/var/lib/kafka/data
num.partitions=3
default.replication.factor=1
min.insync.replicas=1
auto.create.topics.enable=true

# ---- Internal topic replication (single-node safe) --------------------------
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
share.coordinator.state.topic.replication.factor=1
share.coordinator.state.topic.min.isr=1

# ---- Retention --------------------------------------------------------------
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000

# ---- Threading & performance ------------------------------------------------
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
num.recovery.threads.per.data.dir=1
EOF

chown kafka:kafka /opt/kafka/config/server.properties
msg_ok "Configured KRaft broker"

# ----------------------------------------------------------------------------
# Format storage with a generated cluster ID (one-time bootstrap)
# ----------------------------------------------------------------------------
msg_info "Formatting Kafka storage"
CLUSTER_ID=$(/opt/kafka/bin/kafka-storage.sh random-uuid)
sudo -u kafka /opt/kafka/bin/kafka-storage.sh format \
    --cluster-id "${CLUSTER_ID}" \
    --config /opt/kafka/config/server.properties \
    --ignore-formatted >/dev/null
msg_ok "Formatted storage (cluster-id: ${CLUSTER_ID})"

# ----------------------------------------------------------------------------
# JVM heap — sized for the 2 GB default container
# ----------------------------------------------------------------------------
msg_info "Tuning JVM heap"
cat >/opt/kafka/config/kafka-env.sh <<'EOF'
export KAFKA_HEAP_OPTS="-Xms512M -Xmx1G"
export KAFKA_JVM_PERFORMANCE_OPTS="-server -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:+ExplicitGCInvokesConcurrent -Djava.awt.headless=true"
export LOG_DIR=/var/log/kafka
EOF
chown kafka:kafka /opt/kafka/config/kafka-env.sh
msg_ok "Tuned JVM heap"

# ----------------------------------------------------------------------------
# systemd unit
# ----------------------------------------------------------------------------
msg_info "Creating systemd service"
cat >/etc/systemd/system/kafka.service <<'EOF'
[Unit]
Description=Apache Kafka (KRaft mode)
Documentation=https://kafka.apache.org/documentation/
Requires=network.target
After=network.target

[Service]
Type=simple
User=kafka
Group=kafka
EnvironmentFile=/opt/kafka/config/kafka-env.sh
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-failure
RestartSec=10
LimitNOFILE=100000
SuccessExitStatus=143
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable -q kafka
msg_ok "Created systemd service"

# ----------------------------------------------------------------------------
# Expose CLI tools globally (kafka-topics, kafka-console-producer, etc.)
# ----------------------------------------------------------------------------
msg_info "Linking Kafka CLI tools into /usr/local/bin"
for tool in /opt/kafka/bin/*.sh; do
    ln -sf "${tool}" "/usr/local/bin/$(basename "${tool}" .sh)"
done
msg_ok "Linked CLI tools"

# ----------------------------------------------------------------------------
# Persist credentials and connection info
# ----------------------------------------------------------------------------
msg_info "Saving credentials"
{
    echo "Kafka Version:       ${KAFKA_VERSION}"
    echo "Cluster ID:          ${CLUSTER_ID}"
    echo "Node ID:             ${NODE_ID}"
    echo "Bootstrap Server:    ${HOST_IP}:${LISTENER_PORT}"
    echo "Controller Quorum:   ${NODE_ID}@localhost:${CONTROLLER_PORT}"
    echo "Data Directory:      /var/lib/kafka/data"
    echo "Log Directory:       /var/log/kafka"
    echo "Config:              /opt/kafka/config/server.properties"
} >/root/kafka.creds
chmod 600 /root/kafka.creds
msg_ok "Saved credentials to /root/kafka.creds"

# ----------------------------------------------------------------------------
# Start broker and smoke-test the listener
# ----------------------------------------------------------------------------
msg_info "Starting Kafka"
systemctl start kafka
for _ in {1..30}; do
    if nc -z localhost "${LISTENER_PORT}" 2>/dev/null; then
        break
    fi
    sleep 1
done
if ! nc -z localhost "${LISTENER_PORT}" 2>/dev/null; then
    msg_error "Kafka failed to bind ${LISTENER_PORT} — check 'journalctl -u kafka'"
else
    msg_ok "Started Kafka (listening on ${LISTENER_PORT})"
fi

# ----------------------------------------------------------------------------
# Cleanup
# ----------------------------------------------------------------------------
motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
