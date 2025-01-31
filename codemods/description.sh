description() {
  IP=$(incus exec "$HN" ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)
  if [[ -f /etc/systemd/system/ping-instances.service ]]; then
    systemctl start ping-instances.service
  fi

}
