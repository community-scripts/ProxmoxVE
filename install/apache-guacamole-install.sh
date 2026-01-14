#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
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
  libcairo2-dev \
  libjpeg62-turbo-dev \
  libpng-dev \
  libtool-bin \
  uuid-dev \
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
  libavformat-dev
msg_ok "Installed Dependencies"

JAVA_VERSION="11" setup_java
setup_mariadb
MARIADB_DB_NAME="guacamole_db" MARIADB_DB_USER="guacamole_user" setup_mariadb_db

msg_info "Setup Apache Tomcat"
TOMCAT_VERSION=$(curl -fsSL https://dlcdn.apache.org/tomcat/tomcat-9/ | grep -oP '(?<=href=")v[^"/]+(?=/")' | sed 's/^v//' | sort -V | tail -n1)
mkdir -p /opt/apache-guacamole/{tomcat9,server}
curl -fsSL "https://dlcdn.apache.org/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" | tar -xz -C /opt/apache-guacamole/tomcat9 --strip-components=1
useradd -r -d /opt/apache-guacamole/tomcat9 -s /bin/false tomcat
chown -R tomcat: /opt/apache-guacamole/tomcat9
chmod -R g+r /opt/apache-guacamole/tomcat9/conf
chmod g+x /opt/apache-guacamole/tomcat9/conf
echo "${TOMCAT_VERSION}" >~/.guacamole_tomcat
msg_ok "Setup Apache Tomcat ${TOMCAT_VERSION}"

msg_info "Setup Apache Guacamole"
mkdir -p /etc/guacamole/{extensions,lib}
GUAC_SERVER_VERSION=$(curl -fsSL https://api.github.com/repos/apache/guacamole-server/tags | jq -r '.[].name' | grep -v -- '-RC' | head -n 1)
GUAC_CLIENT_VERSION=$(curl -fsSL https://api.github.com/repos/apache/guacamole-client/tags | jq -r '.[].name' | grep -v -- '-RC' | head -n 1)
MYSQL_CONNECTOR_VERSION=$(curl -fsSL "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/maven-metadata.xml" | grep -oP '<latest>\K[^<]+')
curl -fsSL "https://api.github.com/repos/apache/guacamole-server/tarball/refs/tags/${GUAC_SERVER_VERSION}" | tar -xz --strip-components=1 -C /opt/apache-guacamole/server
cd /opt/apache-guacamole/server
export CPPFLAGS="-Wno-error=deprecated-declarations"
$STD autoreconf -fi
$STD ./configure --with-init-dir=/etc/init.d --enable-allow-freerdp-snapshots
$STD make
$STD make install
$STD ldconfig
echo "${GUAC_SERVER_VERSION}" >~/.guacamole_server
curl -fsSL "https://downloads.apache.org/guacamole/${GUAC_CLIENT_VERSION}/binary/guacamole-${GUAC_CLIENT_VERSION}.war" -o "/opt/apache-guacamole/tomcat9/webapps/guacamole.war"
echo "${GUAC_CLIENT_VERSION}" >~/.guacamole_client
curl -fsSL "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/${MYSQL_CONNECTOR_VERSION}/mysql-connector-j-${MYSQL_CONNECTOR_VERSION}.jar" -o "/etc/guacamole/lib/mysql-connector-j.jar"
echo "${MYSQL_CONNECTOR_VERSION}" >~/.guacamole_mysql_connector
cd /root
curl -fsSL "https://downloads.apache.org/guacamole/${GUAC_SERVER_VERSION}/binary/guacamole-auth-jdbc-${GUAC_SERVER_VERSION}.tar.gz" -o "/root/guacamole-auth-jdbc-${GUAC_SERVER_VERSION}.tar.gz"
$STD tar -xf ~/guacamole-auth-jdbc-"$GUAC_SERVER_VERSION".tar.gz
mv ~/guacamole-auth-jdbc-"$GUAC_SERVER_VERSION"/mysql/guacamole-auth-jdbc-mysql-"$GUAC_SERVER_VERSION".jar /etc/guacamole/extensions/
echo "${GUAC_SERVER_VERSION}" >~/.guacamole_auth_jdbc
msg_ok "Setup Apache Guacamole"

msg_info "Importing Database Schema"
cd ~/guacamole-auth-jdbc-"${GUAC_SERVER_VERSION}"/mysql/schema
cat *.sql | mariadb -u root ${MARIADB_DB_NAME}
{
  echo "mysql-hostname: 127.0.0.1"
  echo "mysql-port: 3306"
  echo "mysql-database: $MARIADB_DB_NAME"
  echo "mysql-username: $MARIADB_DB_USER"
  echo "mysql-password: $MARIADB_DB_PASS"
} >>/etc/guacamole/guacamole.properties
rm -rf ~/guacamole-auth-jdbc-"$GUAC_SERVER_VERSION"{,.tar.gz}
msg_ok "Imported Database Schema"

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
systemctl enable -q --now mysql tomcat guacd
msg_ok "Setup Service"

motd_ssh
customize
cleanup_lxc
