#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://pi-hole.net/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  ufw
msg_ok "Installed Dependencies"

msg_info "Installing Pi-hole"
mkdir -p /etc/pihole
touch /etc/pihole/pihole.toml
$STD bash <(curl -fsSL https://install.pi-hole.net) --unattended
sed -i -E '
/^\s*upstreams =/ s|=.*|= ["8.8.8.8", "8.8.4.4"]|
/^\s*interface =/ s|=.*|= "eth0"|
/^\s*queryLogging =/ s|=.*|= true|
/^\s*size =/ s|=.*|= 10000|
/^\s*active =/ s|=.*|= true|
/^\s*listeningMode =/ s|=.*|= "LOCAL"|
/^\s*port =/ s|=.*|= "80o,443os,[::]:80o,[::]:443os"|
/^\s*pwhash =/ s|=.*|= ""|

# DHCP Disable
/^\s*\[dhcp\]/,/^\s*\[/{s/^\s*active = true/  active = false/}

# NTP Disable
/^\s*\[ntp.ipv4\]/,/^\s*\[/{s/^\s*active = true/  active = false/}
/^\s*\[ntp.ipv6\]/,/^\s*\[/{s/^\s*active = true/  active = false/}
/^\s*\[ntp.sync\]/,/^\s*\[/{s/^\s*active = true/  active = false/}
/^\s*\[ntp.sync\]/,/^\s*\[/{s/^\s*interval = [0-9]+/  interval = 0/}
/^\s*\[ntp.sync.rtc\]/,/^\s*\[/{s/^\s*set = true/  set = false/}

# set domainNeeded und expandHosts
/^\s*domainNeeded =/ s|=.*|= true|
/^\s*expandHosts =/ s|=.*|= true|
' /etc/pihole/pihole.toml

cat <<EOF > /etc/dnsmasq.d/01-pihole.conf
server=8.8.8.8
server=8.8.4.4
EOF
$STD pihole-FTL --config ntp.sync.interval 0
systemctl restart pihole-FTL.service
msg_ok "Installed Pi-hole"

read -r -p "Would you like to add Unbound? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  read -r -p "Unbound is configured as a recursive DNS server by default, would you like it to be configured as a forwarding DNS server (using DNS-over-TLS (DoT)) instead? <y/N> " prompt
  msg_info "Installing Unbound"
  $STD apt-get install -y unbound
  cat <<EOF >/etc/unbound/unbound.conf.d/pi-hole.conf
server:
  verbosity: 0
  interface: 127.0.0.1
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
EOF
  mkdir -p /etc/dnsmasq.d/
  cat <<EOF >/etc/dnsmasq.d/99-edns.conf
edns-packet-max=1232
EOF

  if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
    cat <<EOF >>/etc/unbound/unbound.conf.d/pi-hole.conf
  tls-cert-bundle: "/etc/ssl/certs/ca-certificates.crt"
forward-zone:
  name: "."
  forward-tls-upstream: yes
  forward-first: no

  forward-addr: 8.8.8.8@853#dns.google
  forward-addr: 8.8.4.4@853#dns.google
  forward-addr: 2001:4860:4860::8888@853#dns.google
  forward-addr: 2001:4860:4860::8844@853#dns.google

  #forward-addr: 1.1.1.1@853#cloudflare-dns.com
  #forward-addr: 1.0.0.1@853#cloudflare-dns.com
  #forward-addr: 2606:4700:4700::1111@853#cloudflare-dns.com
  #forward-addr: 2606:4700:4700::1001@853#cloudflare-dns.com

  #forward-addr: 9.9.9.9@853#dns.quad9.net
  #forward-addr: 149.112.112.112@853#dns.quad9.net
  #forward-addr: 2620:fe::fe@853#dns.quad9.net
  #forward-addr: 2620:fe::9@853#dns.quad9.net
EOF
  fi
cat <<EOF > /etc/dnsmasq.d/01-pihole.conf
server=127.0.0.1#5335
server=8.8.8.8
server=8.8.4.4
EOF

  sed -i -E '/^\s*upstreams\s*=\s*\[/,/^\s*\]/c\  upstreams = [\n    "127.0.0.1#5335",\n    "8.8.4.4"\n  ]' /etc/pihole/pihole.toml
  systemctl enable -q --now unbound
  systemctl restart pihole-FTL.service
  msg_ok "Installed Unbound"
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
