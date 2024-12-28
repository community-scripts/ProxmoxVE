#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
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
upstreams:
  init:
    # Configure startup behavior.
    # accepted: blocking, failOnError, fast
    # default: blocking
    strategy: fast
  groups:
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
  # optional: Determines what strategy blocky uses to choose the upstream servers.
  # accepted: parallel_best, strict, random
  # default: parallel_best
  #strategy: parallel_best
  # optional: timeout to query the upstream resolver. Default: 2s
  #timeout: 2s
  # optional: HTTP User Agent when connecting to upstreams. Default: none
  #userAgent: "custom UA"

# optional: Determines how blocky will create outgoing connections. This impacts both upstreams, and lists.
# accepted: dual, v4, v6
# default: dual
#connectIPVersion: dual

# optional: custom IP address(es) for domain name (with all sub-domains). Multiple addresses must be separated by a comma
# example: query "printer.lan" or "my.printer.lan" will return 192.168.178.3
customDNS:
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
conditional:
  # optional: if false (default), return empty result if after rewrite, the mapped resolver returned an empty answer. If true, the original query will be sent to the upstream resolver
  # Example: The query "blog.example.com" will be rewritten to "blog.fritz.box" and also redirected to the resolver at 192.168.178.1. If not found and if 'fallbackUpstream' was set to 'true', the original query "blog.example.com" will be sent upstream.
  # Usage: One usecase when having split DNS for internal and external (internet facing) users, but not all subdomains are listed in the internal domain.
  #fallbackUpstream: false
  # optional: replace domain in the query with other domain before resolver lookup in the mapping
  #rewrite:
    #example.com: fritz.box
  #mapping:
    #fritz.box: 192.168.178.1
    #lan.net: 192.168.178.1,192.168.178.2

# optional: use allow/denylists to block queries (for example ads, trackers, adult pages etc.)
blocking:
  # definition of denylist groups. Can be external link (http/https) or local file
  denylists:
    ads:
      - https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
      - https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
      - http://sysctl.org/cameleon/hosts
      - https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt
      #- |
        # inline definition with YAML literal block scalar style
        #someadsdomain.com
        #*.example.com
    special:
      - https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts
  # definition of allowlist groups.
  # Note: if the same group has both allow/denylists, allowlists take precedence. Meaning if a domain is both blocked and allowed, it will be allowed.
  # If a group has only allowlist entries, only domains from this list are allowed, and all others be blocked.
  allowlists:
    #ads:
      #- allowlist.txt
      #- |
        # inline definition with YAML literal block scalar style
        # hosts format
        #allowlistdomain.com
        # this is a regex
        #/^banners?[_.-]/
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
  #blockType: zeroIp
  # optional: TTL for answers to blocked domains
  # default: 6h
  blockTTL: 1m
  # optional: Configure how lists, AKA sources, are loaded
  loading:
    # optional: list refresh period in duration format.
    # Set to a value <= 0 to disable.
    # default: 4h
    #refreshPeriod: 24h
    # optional: Applies only to lists that are downloaded (HTTP URLs).
    downloads:
      # optional: timeout for list download (each url). Use large values for big lists or slow internet connections
      # default: 5s
      timeout: 60s
      # optional: Maximum download attempts
      # default: 3
      attempts: 5
      # optional: Time between the download attempts
      # default: 500ms
      cooldown: 10s
    # optional: Maximum number of lists to process in parallel.
    # default: 4
    #concurrency: 16
    # Configure startup behavior.
    # accepted: blocking, failOnError, fast
    # default: blocking
    #strategy: failOnError
    # Number of errors allowed in a list before it is considered invalid.
    # A value of -1 disables the limit.
    # default: 5
    #maxErrorsPerSource: 5

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
  # Time how long negative results (NXDOMAIN response or empty result) are cached. A value of -1 will disable caching for negative results.
  # Default: 30m
  #cacheTimeNegative: 30m

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
  type:
  # directory (should be mounted as volume in docker) for csv, db connection string for mysql/postgresql
  #target: db_user:db_password@tcp(db_host_or_ip:3306)/db_name?charset=utf8mb4&parseTime=True&loc=Local
  #postgresql target: postgres://user:password@db_host_or_ip:5432/db_name
  # if > 0, deletes log files which are older than ... days
  #logRetentionDays: 7
  # optional: Max attempts to create specific query log writer, default: 3
  #creationAttempts: 1
  # optional: Time between the creation attempts, default: 2s
  #creationCooldown: 2s
  # optional: Which fields should be logged. You can choose one or more from: clientIP, clientName, responseReason, responseAnswer, question, duration. If not defined, it logs all fields
  #fields:
    #- clientIP
    #- duration
  # optional: Interval to write data in bulk to the external database, default: 30s
  #flushInterval: 30s

# optional: Blocky can synchronize its cache and blocking state between multiple instances through redis.
redis:
  # Server address and port or master name if sentinel is used
  #address: redismaster
  # Username if necessary
  #username: usrname
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
  # Sentinal username if necessary
  #sentinelUsername: usrname
  # Sentinal password if necessary
  #sentinelPassword: passwd
  # List with address and port of sentinel hosts(sentinel is activated if at least one sentinel address is configured)
  #sentinelAddresses:
    #- redis-sentinel1:26379
    #- redis-sentinel2:26379
    #- redis-sentinel3:26379

# optional: Mininal TLS version that the DoH and DoT server will use
#minTlsServeVersion: 1.3

# if https port > 0: path to cert and key file for SSL encryption. if not set, self-signed certificate will be generated
#certFile: server.crt
#keyFile: server.key

# optional: use these DNS servers to resolve denylist urls and upstream DNS servers. It is useful if no system DNS resolver is configured, and/or to encrypt the bootstrap queries.
bootstrapDns:
  #- tcp+udp:1.1.1.1
  #- https://1.1.1.1/dns-query
  #- upstream: https://dns.digitale-gesellschaft.ch/dns-query
    #ips:
      #- 185.95.218.42

# optional: drop all queries with following query types. Default: empty
filtering:
  #queryTypes:
    #- AAAA

# optional: return NXDOMAIN for queries that are not FQDNs.
fqdnOnly:
  # default: false
  #enable: true

# optional: if path defined, use this file for query resolution (A, AAAA and rDNS). Default: empty
hostsFile:
  # optional: Hosts files to parse
  #sources:
    #- /etc/hosts
    #- https://example.com/hosts
    #- |
      # inline hosts
      #127.0.0.1 example.com
  # optional: TTL, default: 1h
  #hostsTTL: 30m
  # optional: Whether loopback hosts addresses (127.0.0.0/8 and ::1) should be filtered or not
  # default: false
  #filterLoopback: true
  # optional: Configure how sources are loaded
  #loading:
    # optional: file refresh period in duration format.
    # Set to a value <= 0 to disable.
    # default: 4h
    #refreshPeriod: 24h
    # optional: Applies only to files that are downloaded (HTTP URLs).
    #downloads:
      # optional: timeout for file download (each url). Use large values for big files or slow internet connections
      # default: 5s
      #timeout: 60s
      # optional: Maximum download attempts
      # default: 3
      #attempts: 5
      # optional: Time between the download attempts
      # default: 500ms
      #cooldown: 10s
    # optional: Maximum number of files to process in parallel.
    # default: 4
    #concurrency: 16
    # Configure startup behavior.
    # accepted: blocking, failOnError, fast
    # default: blocking
    #strategy: failOnError
    # Number of errors allowed in a file before it is considered invalid.
    # A value of -1 disables the limit.
    # default: 5
    #maxErrorsPerSource: 5

# optional: ports configuration
ports:
  # optional: DNS listener port(s) and bind ip address(es), default 53 (UDP and TCP). Example: 53, :53, "127.0.0.1:5353,[::1]:5353"
  dns: 53
  # optional: Port(s) and bind ip address(es) for DoT (DNS-over-TLS) listener. Example: 853, 127.0.0.1:853
  tls: 853
  # optional: Port(s) and optional bind ip address(es) to serve HTTPS used for prometheus metrics, pprof, REST API, DoH... If you wish to specify a specific IP, you can do so such as 192.168.0.1:443. Example: 443, :443, 127.0.0.1:443,[::1]:443
  https: 443
  # optional: Port(s) and optional bind ip address(es) to serve HTTP used for prometheus metrics, pprof, REST API, DoH... If you wish to specify a specific IP, you can do so such as 192.168.0.1:4000. Example: 4000, :4000, 127.0.0.1:4000,[::1]:4000
  http: 4000

# optional: logging configuration
log:
  # optional: Log level (one from trace, debug, info, warn, error). Default: info
  level: info
  # optional: Log format (text or json). Default: text
  #format: text
  # optional: log timestamps. Default: true
  #timestamp: true
  # optional: obfuscate log output (replace all alphanumeric characters with *) for user sensitive data like request domains or responses to increase #privacy. Default: false
  #privacy: false

# optional: add EDE error codes to dns response
ede:
  # enabled if true, Default: false
  #enable: true

# optional: configure optional Special Use Domain Names (SUDN)
#specialUseDomains:
  # optional: block recomended private TLDs
  # default: true
  #rfc6762-appendixG: true

# optional: configure extended client subnet (ECS) support
ecs:
  # optional: if the request ecs option with a max sice mask the address will be used as client ip
  #useAsClient: true
  # optional: if the request contains a ecs option it will be forwarded to the upstream resolver
  #forward: true
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
