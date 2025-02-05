update_os() {
  msg_info "Updating Container OS"
  if [[ "$CACHER" == "yes" ]]; then
    echo "Acquire::http::Proxy-Auto-Detect \"/usr/local/bin/apt-proxy-detect.sh\";" >/etc/apt/apt.conf.d/00aptproxy
    cat <<EOF >/usr/local/bin/apt-proxy-detect.sh
#!/bin/bash
if nc -w1 -z "${CACHER_IP}" 3142; then
  echo -n "http://${CACHER_IP}:3142"
else
  echo -n "DIRECT"
fi
EOF
  chmod +x /usr/local/bin/apt-proxy-detect.sh
  fi
  $STD apt-get update
  $STD apt-get -o Dpkg::Options::="--force-confold" -y dist-upgrade
  rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
  $STD apt-get install -y wget logrotate
  if [[ "$INSTALL_SSH" == "yes" ]]; then
    $STD apt-get install -y openssh-server
  fi
  msg_ok "Updated Container OS"
}
