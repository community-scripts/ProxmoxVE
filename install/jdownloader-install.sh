#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://jdownloader.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

JAVA_VERSION="21" setup_java

msg_info "Installing GUI Dependencies (Xvfb, Openbox, x11vnc, noVNC, tint2)"
$STD apt install -y \
  xvfb \
  x11vnc \
  novnc \
  websockify \
  openbox \
  tint2 \
  autocutsel \
  x11-xserver-utils \
  x11-utils \
  wmctrl \
  fonts-dejavu-core \
  ffmpeg \
  rtmpdump
msg_ok "Installed GUI Dependencies"

msg_info "Downloading JDownloader"
mkdir -p /opt/jdownloader
$STD wget -O /opt/jdownloader/JDownloader.jar https://installer.jdownloader.org/JDownloader.jar
msg_ok "Downloaded JDownloader"

msg_info "Installing JDownloader (Patience)"
cd /opt/jdownloader
$STD java -Djava.awt.headless=true -jar /opt/jdownloader/JDownloader.jar -norestart
msg_ok "Installed JDownloader"

msg_info "Configuring JDownloader"
cat <<EOF >/opt/jdownloader/cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json
{
    "email" : null,
    "password" : null,
    "devicename" : "JDownloader@LXC",
    "autoconnectenabledv2" : false
}
EOF

cat <<EOF >/opt/jdownloader/cfg/org.jdownloader.api.RemoteAPIConfig.json
{"headlessmyjdownloadermandatory":false,"deprecatedapienabled":false,"jdanywhereapienabled":false}
EOF
msg_ok "Configured JDownloader"

msg_info "Configuring Openbox (Auto-Maximize JDownloader Window)"
mkdir -p /root/.config/openbox
cat <<'EOF' >/root/.config/openbox/rc.xml
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <applications>
    <application class="*">
      <maximized>true</maximized>
    </application>
  </applications>
</openbox_config>
EOF
msg_ok "Configured Openbox"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/xvfb.service
[Unit]
Description=Virtual Framebuffer X Server
After=network.target

[Service]
Type=simple
ExecStartPre=/bin/sh -c 'rm -f /tmp/.X1-lock'
ExecStart=/usr/bin/Xvfb :1 -screen 0 1280x800x24
ExecStartPost=/bin/sh -c 'sleep 1 && DISPLAY=:1 xset s off && DISPLAY=:1 xset s noblank && DISPLAY=:1 xset -dpms'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/openbox.service
[Unit]
Description=Openbox Window Manager
After=xvfb.service
Requires=xvfb.service

[Service]
Type=simple
Environment=DISPLAY=:1
ExecStart=/usr/bin/openbox
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/tint2.service
[Unit]
Description=tint2 Taskbar
After=openbox.service
Requires=openbox.service

[Service]
Type=simple
Environment=DISPLAY=:1
ExecStart=/usr/bin/tint2
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/autocutsel.service
[Unit]
Description=autocutsel Clipboard Sync
After=openbox.service
Requires=openbox.service

[Service]
Type=simple
Environment=DISPLAY=:1
ExecStart=/bin/sh -c 'autocutsel -selection PRIMARY -fork; exec autocutsel -selection CLIPBOARD'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/jdownloader.service
[Unit]
Description=JDownloader Download Manager
After=openbox.service
Requires=openbox.service

[Service]
Type=simple
User=root
Environment=DISPLAY=:1
WorkingDirectory=/opt/jdownloader
ExecStartPre=/bin/sleep 3
ExecStart=/usr/bin/java -Dsun.java2d.xrender=false -Dsun.java2d.pmoffscreen=false -Dsun.java2d.opengl=false -jar /opt/jdownloader/JDownloader.jar
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/x11vnc.service
[Unit]
Description=x11vnc Server
After=jdownloader.service
Requires=xvfb.service

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -display :1 -forever -shared -rfbport 5900 -nopw -noipv6 -xkb -noxdamage -nowf -nowcr -wait 50 -defer 50
RestartSec=5
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/novnc.service
[Unit]
Description=noVNC WebSocket Proxy
After=x11vnc.service
Requires=x11vnc.service

[Service]
Type=simple
ExecStart=/usr/bin/websockify --web=/usr/share/novnc 6080 localhost:5900
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
msg_ok "Created Services"

msg_info "Starting Services"
systemctl daemon-reload
systemctl enable -q --now xvfb
sleep 2
systemctl enable -q --now openbox
sleep 1
systemctl enable -q --now tint2
systemctl enable -q --now autocutsel
systemctl enable -q --now jdownloader
sleep 3
systemctl enable -q --now x11vnc
sleep 1
systemctl enable -q --now novnc
msg_ok "Started Services"

motd_ssh
customize
cleanup_lxc
