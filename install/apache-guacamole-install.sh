#!/usr/bin/env bash
#Copyright (c) 2021-2025 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner) | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://guacamole.apache.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  jq \
  libcairo2-dev \
  libturbojpeg0 \
  libpng-dev \
  libtool-bin \
  libossp-uuid-dev \
  libvncserver-dev \
  freerdp3-dev \
  libssh2-1-dev \
  libtelnet-dev \
  libwebsockets-dev \
  libpulse-dev \
  libvorbis-dev \
  libwebp-dev \
  libssl-dev \
  libpango1.0-dev \
  libswscale-dev \
  libavcodec-dev \
  libavutil-dev \
  libavformat-dev \
  default-jdk
msg_ok "Installed Dependencies"

setup_mariadb

msg_info "Setup Apache Tomcat"
RELEASE=$(curl -fsSL https://dlcdn.apache.org/tomcat/tomcat-9/ | grep -oP '(?<=href=")v[^"/]+(?=/")' | sed 's/^v//' | sort -V | tail -n1)
mkdir -p /opt/apache-guacamole/tomcat9
mkdir -p /opt/apache-guacamole/server
curl -fsSL "https://dlcdn.apache.org/tomcat/tomcat-9/v${RELEASE}/bin/apache-tomcat-${RELEASE}.tar.gz" | tar -xz -C /opt/apache-guacamole/tomcat9 --strip-components=1
useradd -r -d /opt/apache-guacamole/tomcat9 -s /bin/false tomcat
chown -R tomcat: /opt/apache-guacamole/tomcat9
chmod -R g+r /opt/apache-guacamole/tomcat9/conf
chmod g+x /opt/apache-guacamole/tomcat9/conf
msg_ok "Setup Apache Tomcat"

msg_info "Setup Apache Guacamole"
mkdir -p /etc/guacamole/{extensions,lib}
RELEASE_SERVER=$(curl -fsSL https://api.github.com/repos/apache/guacamole-server/tags | jq -r '.[].name' | grep -v -- '-RC' | head -n 1)
curl -fsSL "https://api.github.com/repos/apache/guacamole-server/tarball/refs/tags/${RELEASE_SERVER}" | tar -xz --strip-components=1 -C /opt/apache-guacamole/server
cd /opt/apache-guacamole/server
export CPPFLAGS="-Wno-error=deprecated-declarations"
$STD autoreconf -fi
$STD ./configure --with-init-dir=/etc/init.d --enable-allow-freerdp-snapshots --disable-guaclog
$STD make
$STD make install
$STD ldconfig
RELEASE_CLIENT=$(curl -fsSL https://api.github.com/repos/apache/guacamole-client/tags | jq -r '.[].name' | grep -v -- '-RC' | head -n 1)
curl -fsSL "https://downloads.apache.org/guacamole/${RELEASE_CLIENT}/binary/guacamole-${RELEASE_CLIENT}.war" -o "/opt/apache-guacamole/tomcat9/webapps/guacamole.war"
cd /root
curl -fsSL "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-9.3.0.tar.gz" -o "/root/mysql-connector-j-9.3.0.tar.gz"
$STD tar -xf ~/mysql-connector-j-9.3.0.tar.gz
mv ~/mysql-connector-j-9.3.0/mysql-connector-j-9.3.0.jar /etc/guacamole/lib/
curl -fsSL "https://downloads.apache.org/guacamole/${RELEASE_SERVER}/binary/guacamole-auth-jdbc-${RELEASE_SERVER}.tar.gz" -o "/root/guacamole-auth-jdbc-${RELEASE_SERVER}.tar.gz"
$STD tar -xf ~/guacamole-auth-jdbc-$RELEASE_SERVER.tar.gz
mv ~/guacamole-auth-jdbc-$RELEASE_SERVER/mysql/guacamole-auth-jdbc-mysql-$RELEASE_SERVER.jar /etc/guacamole/extensions/
msg_ok "Setup Apache Guacamole"

msg_info "Setup Database"
DB_NAME=guacamole_db
DB_USER=guacamole_user
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "CREATE DATABASE $DB_NAME;"
$STD mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
$STD mariadb -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "Guacamole-Credentials"
  echo "Database User: $DB_USER"
  echo "Database Password: $DB_PASS"
  echo "Database Name: $DB_NAME"
} >>~/guacamole.creds
cd guacamole-auth-jdbc-${RELEASE_SERVER}/mysql/schema
cat *.sql | mariadb -u root ${DB_NAME}
{
  echo "mysql-hostname: 127.0.0.1"
  echo "mysql-port: 3306"
  echo "mysql-database: $DB_NAME"
  echo "mysql-username: $DB_USER"
  echo "mysql-password: $DB_PASS"

} >>/etc/guacamole/guacamole.properties
msg_ok "Setup Database"

msg_info "Setup Service"
cat <<EOF >/etc/guacamole/guacd.conf
[server]
bind_host = 127.0.0.1
bind_port = 4822
EOF
JAVA_HOME=$(update-alternatives --query javadoc | grep Value: | head -n1 | sed 's/Value: //' | sed 's@bin/javadoc$@@')
cat <<EOF >/etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target
[Service]
Type=forking
Environment="JAVA_HOME=${JAVA_HOME}"
Environment="CATALINA_PID=/opt/apache-guacamole/tomcat9/temp/tomcat.pid"
Environment="CATALINA_HOME=/opt/apache-guacamole/tomcat9/"
Environment="CATALINA_BASE=/opt/apache-guacamole/tomcat9/"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"
ExecStart=/opt/apache-guacamole/tomcat9/bin/startup.sh
ExecStop=/opt/apache-guacamole/tomcat9/bin/shutdown.sh
User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always
[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/guacd.service
[Unit]
Description=Guacamole Proxy Daemon (guacd)
After=mysql.service tomcat.service
Requires=mysql.service tomcat.service
[Service]
Type=forking
ExecStart=/etc/init.d/guacd start
ExecStop=/etc/init.d/guacd stop
ExecReload=/etc/init.d/guacd restart
PIDFile=/var/run/guacd.pid
[Install]
WantedBy=multi-user.target
EOF
systemctl -q enable --now mysql tomcat guacd
msg_ok "Setup Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf ~/mysql-connector-j-9.3.0{,.tar.gz}
rm -rf ~/guacamole-auth-jdbc-$RELEASE_SERVER{,.tar.gz}
$STD apt -y autoremove
$STD apt -y autoclean
msg_ok "Cleaned"
