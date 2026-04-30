#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CanbiZ (MickLesk)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://neko.m1k1o.net/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  supervisor \
  pulseaudio \
  dbus-x11 \
  xserver-xorg-video-dummy \
  xdotool \
  xclip \
  libgtk-3-0 \
  gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-pulseaudio \
  openbox \
  firefox-esr \
  fonts-noto-color-emoji \
  fonts-wqy-zenhei
msg_ok "Installed Dependencies"
systemctl disable -q --now supervisor

msg_info "Installing Build Dependencies"
$STD apt install -y \
  build-essential \
  pkg-config \
  libx11-dev \
  libxrandr-dev \
  libxtst-dev \
  libgtk-3-dev \
  libxcvt-dev \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev
msg_ok "Installed Build Dependencies"

NODE_VERSION="22" setup_nodejs
setup_go

fetch_and_deploy_gh_release "neko" "m1k1o/neko" "tarball"

msg_info "Building Client"
cd /opt/neko/client
$STD npm install
$STD npm run build
mkdir -p /var/www
cp -r /opt/neko/client/dist/* /var/www/
msg_ok "Built Client"

msg_info "Building Server"
cd /opt/neko/server
$STD ./build
cp /opt/neko/server/bin/neko /usr/bin/neko
mkdir -p /etc/neko/plugins
cp -r /opt/neko/server/bin/plugins/* /etc/neko/plugins/ 2>/dev/null || true
msg_ok "Built Server"

msg_info "Setting up Runtime"
useradd -m -s /bin/bash neko
usermod -aG audio,video neko

mkdir -p /etc/neko/supervisord /var/www /var/log/neko /tmp/.X11-unix /tmp/runtime-neko /home/neko/.config/pulse /home/neko/.local/share/xorg
chmod 1777 /tmp/.X11-unix
chmod 1777 /var/log/neko
chmod 0700 /tmp/runtime-neko
chown neko /tmp/.X11-unix /var/log/neko /tmp/runtime-neko
chown -R neko:neko /home/neko

cp /opt/neko/runtime/xorg.conf /etc/neko/xorg.conf
# Remove the dummy_touchscreen InputDevice section (requires custom "neko" Xorg driver not available bare-metal)
sed -i '/Section "InputDevice"/{N;/dummy_touchscreen/{:l;N;/EndSection/!bl;d}}' /etc/neko/xorg.conf
sed -i '/dummy_touchscreen/d' /etc/neko/xorg.conf
sed -i 's/InputDevice  "dummy_mouse"/InputDevice  "dummy_mouse" "CorePointer"/' /etc/neko/xorg.conf
cp /opt/neko/runtime/default.pa /etc/pulse/default.pa

cat <<EOF >/etc/neko/supervisord.conf
[supervisord]
nodaemon=true
user=root
pidfile=/var/run/supervisord.pid
logfile=/dev/null
logfile_maxbytes=0
loglevel=debug

[include]
files=/etc/neko/supervisord/*.conf

[program:x-server]
environment=HOME="/home/neko",USER="neko"
command=/usr/bin/X :99.0 -config /etc/neko/xorg.conf -noreset -nolisten tcp
autorestart=true
priority=300
user=neko
stdout_logfile=/var/log/neko/xorg.log
stdout_logfile_maxbytes=100MB
stdout_logfile_backups=10
redirect_stderr=true

[program:pulseaudio]
environment=HOME="/home/neko",USER="neko",DISPLAY=":99.0"
command=/usr/bin/pulseaudio --log-level=error --disallow-module-loading --disallow-exit --exit-idle-time=-1
autorestart=true
priority=300
user=neko
stdout_logfile=/var/log/neko/pulseaudio.log
stdout_logfile_maxbytes=100MB
stdout_logfile_backups=10
redirect_stderr=true

[program:neko]
environment=HOME="/home/neko",USER="neko",DISPLAY=":99.0"
command=/usr/bin/neko serve --server.static "/var/www"
stopsignal=INT
stopwaitsecs=3
autorestart=true
priority=800
user=neko
stdout_logfile=/var/log/neko/neko.log
stdout_logfile_maxbytes=100MB
stdout_logfile_backups=10
redirect_stderr=true

[unix_http_server]
file=/var/run/supervisor.sock
chmod=0770
chown=root:neko

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface
EOF

cat <<EOF >/etc/neko/supervisord/firefox.conf
[program:firefox]
environment=HOME="/home/neko",USER="neko",DISPLAY=":99.0"
command=/usr/bin/firefox-esr --no-remote --display=:99.0 -width 1280 -height 720
stopsignal=INT
autorestart=true
priority=800
user=neko
stdout_logfile=/var/log/neko/firefox.log
stdout_logfile_maxbytes=100MB
stdout_logfile_backups=10
redirect_stderr=true

[program:openbox]
environment=HOME="/home/neko",USER="neko",DISPLAY=":99.0"
command=/usr/bin/openbox --config-file /etc/neko/openbox.xml
autorestart=true
priority=300
user=neko
stdout_logfile=/var/log/neko/openbox.log
stdout_logfile_maxbytes=100MB
stdout_logfile_backups=10
redirect_stderr=true
EOF

cat <<'EOF' >/etc/neko/openbox.xml
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc" xmlns:xi="http://www.w3.org/2001/XInclude">
<applications>
    <application class="firefox" name="Navigator" role="browser">
      <decor>no</decor>
      <maximized>true</maximized>
      <focus>yes</focus>
      <layer>normal</layer>
    </application>
</applications>
<focus>
  <focusNew>yes</focusNew>
  <followMouse>no</followMouse>
  <focusLast>yes</focusLast>
  <underMouse>no</underMouse>
  <focusDelay>200</focusDelay>
  <raiseOnFocus>no</raiseOnFocus>
</focus>
<placement>
  <policy>Smart</policy>
  <center>yes</center>
</placement>
<desktops>
  <number>1</number>
  <firstdesk>1</firstdesk>
  <popupTime>0</popupTime>
</desktops>
</openbox_config>
EOF

cat <<EOF >/etc/neko/neko.yaml
server:
  bind: "0.0.0.0:8080"
  static: "/var/www"
session:
  cookie:
    enabled: false
webrtc:
  icelite: true
  nat1to1:
    - "${LOCAL_IP}"
  epr: "59000-59100"
desktop:
  input:
    enabled: false
member:
  provider: "multiuser"
  multiuser:
    admin_password: "admin"
    user_password: "neko"
EOF
msg_ok "Set up Runtime"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/neko.service
[Unit]
Description=Neko Virtual Browser
After=network.target

[Service]
Type=simple
User=root
Environment=USER=neko
Environment=DISPLAY=:99.0
Environment=PULSE_SERVER=unix:/tmp/pulseaudio.socket
Environment=XDG_RUNTIME_DIR=/tmp/runtime-neko
Environment=NEKO_PLUGINS_ENABLED=true
Environment=NEKO_PLUGINS_DIR=/etc/neko/plugins/
Environment=NEKO_CONFIG=/etc/neko/neko.yaml
ExecStart=/usr/bin/supervisord -c /etc/neko/supervisord.conf -n
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now neko
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
