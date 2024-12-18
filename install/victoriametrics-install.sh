#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: Denys Holius https://github.com/denisgolius
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://victoriametrics.com/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
          curl \
          sudo \
          mc

msg_ok "Installed Dependencies"

msg_info "Installing VictoriaMetrics"
RELEASE=$(curl -s https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
mkdir -p /etc/victoriametrics
mkdir -p /var/lib/victoriametrics
groupadd -r victoriametrics
useradd -g victoriametrics -d /var/lib/victoriametrics -s /sbin/nologin --system victoriametrics
chown -R victoriametrics:victoriametrics /var/lib/victoria-metrics
wget -q https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${RELEASE}/victoria-metrics-linux-amd64-${RELEASE}.tar.gz
tar -xf victoria-metrics-linux-amd64-${RELEASE}.tar.gz
chmod +x /usr/bin/victoria-metrics-prod
chown root:root /usr/bin/victoria-metrics-prod

cat <<END >/etc/victoriametrics/scrape.yml
# Scrape config example
#
scrape_configs:
  - job_name: self_scrape
    scrape_interval: 10s
    static_configs:
      - targets: ['127.0.0.1:8428'] 
END

mv victoria-metrics-prod /usr/local/bin/
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed VictoriaMetrics"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/victoriametrics.service
[Unit]
Description=VictoriaMetrics is a fast, cost-effective and scalable monitoring solution and time series database.
# https://docs.victoriametrics.com
# See https://docs.victoriametrics.com/#list-of-command-line-flags to get more information about supported command-line flags
Description=VictoriaMetrics
Wants=network-online.target
After=network-online.target

[Service]
ExecStop=/bin/kill -s SIGTERM \$MAINPID
ExecReload=/bin/kill -HUP \$MAINPID
User=root
Restart=always
Type=simple
ExecStart=/usr/local/bin/victoria-metrics-prod \
    -promscrape.config=/etc/victoriametrics/scrape.yml \
    -storageDataPath=/var/lib/victoriametrics \
    -retentionPeriod=12 \
    -httpListenAddr=:8428 \
    -graphiteListenAddr=:2003 \
    -opentsdbListenAddr=:4242 \
    -influxListenAddr=:8089 \
    -enableTCP6

LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=victoriametrics

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now victoriametrics
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
rm -rf victoria-metrics-linux-amd64-${RELEASE}.tar.gz
msg_ok "Cleaned"
