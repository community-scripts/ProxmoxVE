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

msg_info "Installing Blocky"
if systemctl is-active systemd-resolved > /dev/null 2>&1; then
  systemctl disable -q --now systemd-resolved
fi
mkdir /opt/blocky
RELEASE=$(curl -s https://api.github.com/repos/0xERR0R/blocky/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -qO- https://github.com/0xERR0R/blocky/releases/download/v${RELEASE}/blocky_v${RELEASE}_Linux_x86_64.tar.gz | tar -xzf - -C /opt/blocky/

cat <<EOF >/opt/blocky/config.yml
# configuration documentation: https://0xerr0r.github.io/blocky/latest/configuration/

upstreams:
  groups:
    # these external DNS resolvers will be used. Blocky picks 2 random resolvers from the list for each query
    # format for resolver: [net:]host:[port][/path]. net could be empty (default, shortcut for tcp+udp), tcp+udp, tcp, udp, tcp-tls or https (DoH). If port is empty, default port will be used (53 for udp and tcp, 853 for tcp-tls, 443 for https (Doh))
    # this configuration is mandatory, please define at least one external DNS resolver
    default:
      # Cloudflare
      - 1.1.1.1
      # Quad9 DNS-over-TLS server (DoT)
      - tcp-tls:dns.quad9.net

# optional: use allow/denylists to block queries (for example ads, trackers, adult pages etc.)
blocking:
  # definition of denylist groups. Can be external link (http/https) or local file
  denylists:
    ads:
      - https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
  # definition: which groups should be applied for which client
  clientGroupsBlock:
    # default will be used, if no special definition for a client name exists
    default:
      - ads

# optional: write query information (question, answer, client, duration etc.) to daily csv file
queryLog:
  # optional one of: mysql, postgresql, csv, csv-client. If empty, log to console
  type:

# optional: use these DNS servers to resolve denylist urls and upstream DNS servers. It is useful if no system DNS resolver is configured, and/or to encrypt the bootstrap queries.
bootstrapDns:
  - upstream: tcp-tls:one.one.one.one
    ips:
      - 1.1.1.1

# optional: logging configuration
log:
  # optional: Log level (one from trace, debug, info, warn, error). Default: info
  level: info
EOF
msg_ok "Installed Blocky"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/blocky.service
[Unit]
Description=Blocky
After=network.target
[Service]
User=root
WorkingDirectory=/opt/blocky
ExecStart=/opt/blocky/./blocky --config config.yml
[Install]
WantedBy=multi-user.target
EOF
$STD systemctl enable --now blocky
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
