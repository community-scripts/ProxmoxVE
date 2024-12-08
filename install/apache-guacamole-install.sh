#!/usr/bin/env bash
#Copyright (c) 2021-2024 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
   build-essential \
   curl \
   jq \
   libcairo2-dev \
   libturbojpeg0 \
   libpng-dev \
   libtool-bin \
   libossp-uuid-dev \
   libvncserver-dev \
   freerdp2-dev \
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
   mariadb-server \
   default-jdk
msg_ok "Installed Dependencies"

msg_info "Setup Apache Tomcat"
mkdir /opt/apache-guacamole
mkdir /opt/apache-guacamole/tomcat9
wget -q https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.97/bin/apache-tomcat-9.0.97.tar.gz
$STD tar xzf apache-tomcat-9.0.97.tar.gz -C /opt/apache-guacamole/tomcat9 --strip-components=1
useradd -r -d /opt/tomcat9 -s /bin/false tomcat
chown -R tomcat: /opt/apache-guacamole/tomcat9/{logs,temp,webapps,work}
chown -R :tomcat /opt/apache-guacamole/tomcat9/
chmod -R g+r /opt/apache-guacamole/tomcat9/conf
chmod g+x /opt/apache-guacamole/tomcat9/conf
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
msg_ok "Setup Apache Tomcat"

msg_info "Setup Apache Guacamole"
mkdir -p /etc/guacamole/{extensions,lib}
RELEASE_SERVER=$(curl -sL https://api.github.com/repos/apache/guacamole-server/tags | jq -r '.[0].name')
mkdir /opt/apache-guacamole/apache-guacamole-server-${RELEASE_SERVER}
wget -q -O apache-guacamole-server-${RELEASE_SERVER} https://api.github.com/repos/apache/guacamole-server/tarball/refs/tags/${RELEASE_SERVER}
$STD tar -xvf apache-guacamole-server-${RELEASE_SERVER} -C /opt/apache-guacamole/apache-guacamole-server-${RELEASE_SERVER} --strip-components=1
cd /opt/apache-guacamole/apache-guacamole-server-${RELEASE_SERVER}
$STD autoreconf -fi
$STD ./configure --with-init-dir=/etc/init.d --enable-allow-freerdp-snapshots
$STD make
$STD make install
$STD ldconfig
RELEASE_CLIENT=$(curl -sL https://api.github.com/repos/apache/guacamole-client/tags | jq -r '.[0].name')
wget -q -O /opt/apache-guacamole/tomcat9/webapps/guacamole.war https://downloads.apache.org/guacamole/${RELEASE_CLIENT}/binary/guacamole-${RELEASE_CLIENT}.war
msg_ok "Setup Apache Guacamole"

msg_info "Setup Databas"
cd /root
wget -q https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.26.tar.gz
$STD tar -xf mysql-connector-java-8.0.26.tar.gz
mv mysql-connector-java-8.0.26/mysql-connector-java-8.0.26.jar /etc/guacamole/lib/
wget -q https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-auth-jdbc-1.5.5.tar.gz
$STD tar -xf guacamole-auth-jdbc-1.5.5.tar.gz
mv guacamole-auth-jdbc-1.5.5/mysql/guacamole-auth-jdbc-mysql-1.5.5.jar /etc/guacamole/extensions/
msg_ok "Setup Databse"

msg_info "Setup Service"
DB_NAME=guacamole_db
DB_USER=guacamole_user
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
mysql -u root -e "CREATE DATABASE $DB_NAME;"
mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password AS PASSWORD('$DB_PASS');"
mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
    echo "SnipeIT-Credentials"
    echo "SnipeIT Database User: $DB_USER"
    echo "SnipeIT Database Password: $DB_PASS"
    echo "SnipeIT Database Name: $DB_NAME"
} >> ~/guacamole.creds
cd guacamole-auth-jdbc-1.5.5/mysql/schema
cat *.sql | mysql -u root ${DB_NAME}
{
    echo "mysql-hostname: 127.0.0.1"
    echo "mysql-port: 3306"
    echo "mysql-database: $DB_NAME"
    echo "mysql-username: $DB_USER"
    echo "mysql-password: $DB_PASS"

} >> /etc/guacamole/guacamole.properties
systemctl -q enable --now tomcat guacd mysql
msg_ok "Setup Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD rm mysql-connector-java-8.0.26.tar.gz
$STD rm -rf mysql-connector-java-8.0.26
$STD rm guacamole-auth-jdbc-1.5.5.tar.gz
$STD rm -rf guacamole-auth-jdbc-1.5.5
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
