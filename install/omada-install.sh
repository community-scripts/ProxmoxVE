#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.tp-link.com/us/support/download/omada-software-controller/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y jsvc
msg_ok "Installed Dependencies"

JAVA_VERSION="21" setup_java

if [[ "$(arch_resolve)" == "arm64" ]] || lscpu | grep -q 'avx'; then
  MONGO_VERSION="8.0" setup_mongodb
else
  msg_error "No AVX detected (CPU-Flag)! We have discontinued support for this. You are welcome to try it manually with a Debian LXC, but due to the many issues with Omada, we currently only support AVX CPUs."
  exit 10
fi

if ! dpkg -l | grep -q 'libssl1.1'; then
  msg_info "Installing libssl (if needed)"
  # libssl1.1 is bullseye's last build, and the pinned filename rotted twice over:
  # the point release moves on its own schedule, and bullseye left
  # security.debian.org when its LTS ended. Take the newest build from whichever
  # pool still carries one instead of hardcoding a name.
  LIBSSL_ARCH=$(arch_resolve)
  LIBSSL_URL=""
  LIBSSL_DEB=""
  for POOL in \
    "https://security.debian.org/debian-security/pool/updates/main/o/openssl" \
    "https://archive.debian.org/debian-security/pool/updates/main/o/openssl" \
    "https://archive.debian.org/debian/pool/main/o/openssl"; do
    FOUND=$(curl -fsSL "$POOL/" | grep -oE "libssl1\.1_[^\"<>]+_${LIBSSL_ARCH}\.deb" | sort -V | tail -n1 || true)
    [[ -z "$FOUND" ]] && continue
    # Newest across every pool, not the first hit: the security archive still
    # only carries buster, whose 1.1.1n is older than bullseye's 1.1.1w.
    if [[ -z "$LIBSSL_DEB" || "$(printf '%s\n%s\n' "$LIBSSL_DEB" "$FOUND" | sort -V | tail -n1)" == "$FOUND" ]]; then
      LIBSSL_DEB="$FOUND"
      LIBSSL_URL="$POOL/$FOUND"
    fi
  done
  if [[ -z "$LIBSSL_URL" ]]; then
    msg_error "No libssl1.1 package for ${LIBSSL_ARCH} found in any Debian pool"
    exit 1
  fi
  curl_download "/tmp/libssl.deb" "$LIBSSL_URL"
  $STD dpkg -i /tmp/libssl.deb
  rm -f /tmp/libssl.deb
  msg_ok "Installed libssl1.1"
fi

msg_info "Installing Omada Controller"
OMADA_URL=$(curl -fsSL -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.5 Safari/605.1.15" "https://support.omadanetworks.com/en/download/software/omada-controller/" |
  grep -o 'https://static\.tp-link\.com/upload/software/[^"]*linux_x64[^"]*\.deb' |
  head -n1)
OMADA_PKG=$(basename "${OMADA_URL}")
curl_download "${OMADA_PKG}" "${OMADA_URL}"
$STD dpkg -i "${OMADA_PKG}"
rm -rf "${OMADA_PKG}"
VERSION=$(sed -n 's/.*_v\([0-9.]*\)_linux.*/\1/p' <<<"${OMADA_PKG}")
echo "${VERSION}" >$HOME/.omada
msg_ok "Installed Omada Controller"

motd_ssh
customize
cleanup_lxc
