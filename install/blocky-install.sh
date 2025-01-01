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
upstream:
  # these external DNS resolvers will be used. Blocky picks 2 random resolvers from the list for each query
  # format for resolver: [net:]host:[port][/path]. net could be empty (default, shortcut for tcp+udp), tcp+udp, tcp, udp, tcp-tls or https (DoH). If port is empty, default port will be used (53 for udp and tcp, 853 for tcp-tls, 443 for https (Doh))
  # this configuration is mandatory, please define at least one external DNS resolver
  default:
    # example for tcp+udp IPv4 server (https://digitalcourage.de/)
    #- 5.9.164.112
    # Cloudflare
    - 1.1.1.1
    # example for DNS-over-TLS server (DoT)
    #- tcp-tls:fdns1.dismail.de:853
    # example for DNS-over-HTTPS (DoH)
    #- https://dns.digitale-gesellschaft.ch/dns-query
  # optional: use client name (with wildcard support: * - sequence of any characters, [0-9] - range)
  # or single ip address / client subnet as CIDR notation
  #laptop*:
    #- 123.123.123.123

# optional: timeout to query the upstream resolver. Default: 2s
#upstreamTimeout: 2s

# optional: If true, blocky will fail to start unless at least one upstream server per group is reachable. Default: false
#startVerifyUpstream: true

# optional: Determines how blocky will create outgoing connections. This impacts both upstreams, and lists.
# accepted: dual, v4, v6
# default: dual
#connectIPVersion: dual

# optional: custom IP address(es) for domain name (with all sub-domains). Multiple addresses must be separated by a comma
# example: query "printer.lan" or "my.printer.lan" will return 192.168.178.3
#customDNS:
  #customTTL: 1h
  # optional: if true (default), return empty result for unmapped query types (for example TXT, MX or AAAA if only IPv4 address is defined).
  # if false, queries with unmapped types will be forwarded to the upstream resolver
  #filterUnmappedTypes: true
  # optional: replace domain in the query with other domain before resolver lookup in the mapping
  #rewrite:
    #example.com: printer.lan
  #mapping:
    #printer.lan: 192.168.178.3,2001:0db8:85a3:08d3:1319:8a2e:0370:7344

# optional: definition, which DNS resolver(s) should be used for queries to the domain (with all sub-domains). Multiple resolvers must be separated by a comma
# Example: Query client.fritz.box will ask DNS server 192.168.178.1. This is necessary for local network, to resolve clients by host name
#conditional:
  # optional: if false (default), return empty result if after rewrite, the mapped resolver returned an empty answer. If true, the original query will be sent to the upstream resolver
  # Example: The query "blog.example.com" will be rewritten to "blog.fritz.box" and also redirected to the resolver at 192.168.178.1. If not found and if  was set to , the original query "blog.example.com" will be sent upstream.
  # Usage: One usecase when having split DNS for internal and external (internet facing) users, but not all subdomains are listed in the internal domain.
  #fallbackUpstream: false
  # optional: replace domain in the query with other domain before resolver lookup in the mapping
  #rewrite:
    #example.com: fritz.box
  #mapping:
    #fritz.box: 192.168.178.1
    #lan.net: 192.168.178.1,192.168.178.2

# optional: use black and white lists to block queries (for example ads, trackers, adult pages etc.)
blocking:
  # definition of blacklist groups. Can be external link (http/https) or local file
  blackLists:
    ads:
      - https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
      - https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
      - http://sysctl.org/cameleon/hosts
      - https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt
      - |
        # inline definition with YAML literal block scalar style
        # hosts format
        someadsdomain.com
    special:
      - https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts
  # definition of whitelist groups. Attention: if the same group has black and whitelists, whitelists will be used to disable particular blacklist entries. If a group has only whitelist entries -> this means only domains from this list are allowed, all other domains will be blocked
  whiteLists:
    ads:
      - whitelist.txt
      - |
        # inline definition with YAML literal block scalar style
        # hosts format
        whitelistdomain.com
        # this is a regex
        /^banners?[_.-]/
  # definition: which groups should be applied for which client
  clientGroupsBlock:
    # default will be used, if no special definition for a client name exists
    default:
      - ads
      - special
    # use client name (with wildcard support: * - sequence of any characters, [0-9] - range)
    # or single ip address / client subnet as CIDR notation
    #laptop*:
      #- ads
    #192.168.178.1/24:
      #- special
  # which response will be sent, if query is blocked:
  # zeroIp: 0.0.0.0 will be returned (default)
  # nxDomain: return NXDOMAIN as return code
  # comma separated list of destination IP addresses (for example: 192.100.100.15, 2001:0db8:85a3:08d3:1319:8a2e:0370:7344). Should contain ipv4 and ipv6 to cover all query types. Useful with running web server on this address to display the "blocked" page.
  blockType: zeroIp
  # optional: TTL for answers to blocked domains
  # default: 6h
  blockTTL: 1m
  # optional: automatically list refresh period (in duration format). Default: 4h.
  # Negative value -> deactivate automatically refresh.
  # 0 value -> use default
  refreshPeriod: 4h
  # optional: timeout for list download (each url). Default: 60s. Use large values for big lists or slow internet connections
  downloadTimeout: 4m
  # optional: Download attempt timeout. Default: 60s
  downloadAttempts: 5
  # optional: Time between the download attempts. Default: 1s
  downloadCooldown: 10s
  # optional: if failOnError, application startup will fail if at least one list can't be downloaded / opened. Default: blocking
  #startStrategy: failOnError

# optional: configuration for caching of DNS responses
caching:
  # duration how long a response must be cached (min value).
  # If <=0, use response's TTL, if >0 use this value, if TTL is smaller
  # Default: 0
  minTime: 5m
  # duration how long a response must be cached (max value).
  # If <0, do not cache responses
  # If 0, use TTL
  # If > 0, use this value, if TTL is greater
  # Default: 0
  maxTime: 30m
  # Max number of cache entries (responses) to be kept in cache (soft limit). Useful on systems with limited amount of RAM.
  # Default (0): unlimited
  maxItemsCount: 0
  # if true, will preload DNS results for often used queries (default: names queried more than 5 times in a 2-hour time window)
  # this improves the response time for often used queries, but significantly increases external traffic
  # default: false
  prefetching: true
  # prefetch track time window (in duration format)
  # default: 120
  prefetchExpires: 2h
  # name queries threshold for prefetch
  # default: 5
  prefetchThreshold: 5
  # Max number of domains to be kept in cache for prefetching (soft limit). Useful on systems with limited amount of RAM.
  # Default (0): unlimited
  #prefetchMaxItemsCount: 0

# optional: configuration of client name resolution
clientLookup:
  # optional: this DNS resolver will be used to perform reverse DNS lookup (typically local router)
  #upstream: 192.168.178.1
  # optional: some routers return multiple names for client (host name and user defined name). Define which single name should be used.
  # Example: take second name if present, if not take first name
  #singleNameOrder:
    #- 2
    #- 1
  # optional: custom mapping of client name to IP addresses. Useful if reverse DNS does not work properly or just to have custom client names.
  #clients:
    #laptop:
      #- 192.168.178.29
# optional: configuration for prometheus metrics endpoint
prometheus:
  # enabled if true
  #enable: true
  # url path, optional (default '/metrics')
  #path: /metrics

# optional: write query information (question, answer, client, duration etc.) to daily csv file
queryLog:
  # optional one of: mysql, postgresql, csv, csv-client. If empty, log to console
  #type: mysql
  # directory (should be mounted as volume in docker) for csv, db connection string for mysql/postgresql
  #target: db_user:db_password@tcp(db_host_or_ip:3306)/db_name?charset=utf8mb4&parseTime=True&loc=Local
  #postgresql target: postgres://user:password@db_host_or_ip:5432/db_name
  # if > 0, deletes log files which are older than ... days
  #logRetentionDays: 7
  # optional: Max attempts to create specific query log writer, default: 3
  #creationAttempts: 1
  # optional: Time between the creation attempts, default: 2s
  #creationCooldown: 2s

# optional: Blocky can synchronize its cache and blocking state between multiple instances through redis.
redis:
  # Server address and port
  #address: redis:6379
  # Password if necessary
  #password: passwd
  # Database, default: 0
  #database: 2
  # Connection is required for blocky to start. Default: false
  #required: true
  # Max connection attempts, default: 3
  #connectionAttempts: 10
  # Time between the connection attempts, default: 1s
  #connectionCooldown: 3s

# optional: DNS listener port(s) and bind ip address(es), default 53 (UDP and TCP). Example: 53, :53, "127.0.0.1:5353,[::1]:5353"
port: 553
# optional: Port(s) and bind ip address(es) for DoT (DNS-over-TLS) listener. Example: 853, 127.0.0.1:853
#tlsPort: 853
# optional: HTTPS listener port(s) and bind ip address(es), default empty = no http listener. If > 0, will be used for prometheus metrics, pprof, REST API, DoH... Example: 443, :443, 127.0.0.1:443
#httpPort: 4000
#httpsPort: 443
# optional: Mininal TLS version that the DoH and DoT server will use
#minTlsServeVersion: 1.3
# if https port > 0: path to cert and key file for SSL encryption. if not set, self-signed certificate will be generated
#certFile: server.crt
#keyFile: server.key
# optional: use this DNS server to resolve blacklist urls and upstream DNS servers. Useful if no DNS resolver is configured and blocky needs to resolve a host name. Format net:IP:port, net must be udp or tcp
#bootstrapDns: tcp+udp:1.1.1.1

filtering:
# optional: drop all queries with following query types. Default: empty
  #queryTypes:
    #- AAAA

# optional: if path defined, use this file for query resolution (A, AAAA and rDNS). Default: empty
hostsFile:
  # optional: Path to hosts file (e.g. /etc/hosts on Linux)
  #filePath: /etc/hosts
  # optional: TTL, default: 1h
  #hostsTTL: 60m
  # optional: Time between hosts file refresh, default: 1h
  #refreshPeriod: 30m
  # optional: Whether loopback hosts addresses (127.0.0.0/8 and ::1) should be filtered or not, default: false
  #filterLoopback: true
# optional: Log level (one from debug, info, warn, error). Default: info
#logLevel: info
# optional: Log format (text or json). Default: text
#logFormat: text
# optional: log timestamps. Default: true
#logTimestamp: true
# optional: obfuscate log output (replace all alphanumeric characters with *) for user sensitive data like request domains or responses to increase privacy. Default: false
#logPrivacy: false

# optional: add EDE error codes to dns response
#ede: 
  # enabled if true, Default: false
  #enable: true
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
