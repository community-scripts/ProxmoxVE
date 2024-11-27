#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: wimb0
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
$STD apt-get install -y \
  sudo \
  curl \
  mc 
msg_ok "Installed Dependencies"

msg_info "Installing Unbound"
$STD apt-get install -y \
  unbound \
  unbound-host
msg_info "Installed Unbound"

cat <<EOF >/etc/unbound/unbound.conf.d/unbound-lxe.conf
server:
  verbosity: 0
  interface: 0.0.0.0
  port: 5335
  do-ip6: no
  do-ip4: yes
  do-udp: yes
  do-tcp: yes
  num-threads: 1
  hide-identity: yes
  hide-version: yes
  harden-glue: yes
  harden-dnssec-stripped: yes
  harden-referral-path: yes
  use-caps-for-id: no
  harden-algo-downgrade: no
  qname-minimisation: yes
  aggressive-nsec: yes
  rrset-roundrobin: yes
  cache-min-ttl: 300
  cache-max-ttl: 14400
  msg-cache-slabs: 8
  rrset-cache-slabs: 8
  infra-cache-slabs: 8
  key-cache-slabs: 8
  serve-expired: yes
  root-hints: /var/lib/unbound/root.hints
  serve-expired-ttl: 3600
  edns-buffer-size: 1232
  prefetch: yes
  prefetch-key: yes
  target-fetch-policy: "3 2 1 1 1"
  unwanted-reply-threshold: 10000000
  rrset-cache-size: 256m
  msg-cache-size: 128m
  so-rcvbuf: 1m
  private-address: 192.168.0.0/16
  private-address: 169.254.0.0/16
  private-address: 172.16.0.0/12
  private-address: 10.0.0.0/8
  private-address: fd00::/8
  private-address: fe80::/10
  access-control: 192.168.0.0/16 allow
  access-control: 172.16.0.0/12 allow
  access-control: 10.0.0.0/8 allow
  chroot: ""
  logfile: /var/log/unbound.log
  verbosity: 1
  log-queries: yes
  statistics-interval: 0
  extended-statistics: yes
  harden-below-nxdomain: yes
EOF

# Update Root hints from Internic (This file holds the information on root name servers needed to initialize cache of Internet domain name servers)
wget -qO /var/lib/unbound/root.hints https://www.internic.net/domain/named.root
# Set unbound user as owner of the root hints file
chown unbound:unbound /var/lib/unbound/root.hints

touch /var/log/unbound.log
chown unbound:unbound /var/log/unbound.log

systemctl restart unbound
msg_ok "Installed Unbound"

msg_ok "Configuring Logrotate"
cat <<EOF >/etc/logrotate.d/unbound
/var/log/unbound.log {
  daily
  rotate 7
  missingok
  notifempty
  compress
  delaycompress
  sharedscripts
  create 644
  postrotate
    /usr/sbin/unbound-control log_reopen
  endscript
}
EOF

systemctl restart logrotate
msg_ok "Restarted Logrotate"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
