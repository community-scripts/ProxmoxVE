#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: | MIT https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://guacamole.apache.org/

APP="Apache-Guacamole"
var_tags="${var_tags:-webserver;remote}"
var_disk="${var_disk:-4}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-2048}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/apache-guacamole ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE_SERVER=$(curl -fsSL https://api.github.com/repos/apache/guacamole-server/tags | jq -r '.[].name' | grep -v -- '-RC' | head -n 1)
  RELEASE_CLIENT=$(curl -fsSL https://api.github.com/repos/apache/guacamole-client/tags | jq -r '.[].name' | grep -v -- '-RC' | head -n 1)

  if [[ -f /opt/apache-guacamole/.version ]]; then
    CURRENT_VERSION=$(cat /opt/apache-guacamole/.version)
  else
    CURRENT_VERSION="unknown"
  fi

  if [[ "$CURRENT_VERSION" == "$RELEASE_SERVER" ]]; then
    msg_ok "Already up to date (${RELEASE_SERVER})"
    exit
  fi

  JAVA_VERSION="11" setup_java

  msg_info "Stopping Services"
  systemctl stop guacd tomcat
  msg_ok "Stopped Services"

  msg_info "Updating Tomcat"
  TOMCAT_RELEASE=$(curl -fsSL https://dlcdn.apache.org/tomcat/tomcat-9/ | grep -oP '(?<=href=")v[^"/]+(?=/")' | sed 's/^v//' | sort -V | tail -n1)
  cp -a /opt/apache-guacamole/tomcat9/conf /tmp/tomcat-conf-backup
  curl -fsSL "https://dlcdn.apache.org/tomcat/tomcat-9/v${TOMCAT_RELEASE}/bin/apache-tomcat-${TOMCAT_RELEASE}.tar.gz" | tar -xz -C /opt/apache-guacamole/tomcat9 --strip-components=1 --exclude='conf/*'
  cp -a /tmp/tomcat-conf-backup/* /opt/apache-guacamole/tomcat9/conf/
  rm -rf /tmp/tomcat-conf-backup
  chown -R tomcat: /opt/apache-guacamole/tomcat9
  msg_ok "Updated Tomcat to ${TOMCAT_RELEASE}"

  msg_info "Updating Guacamole Server to ${RELEASE_SERVER}"
  rm -rf /opt/apache-guacamole/server/*
  curl -fsSL "https://api.github.com/repos/apache/guacamole-server/tarball/refs/tags/${RELEASE_SERVER}" | tar -xz --strip-components=1 -C /opt/apache-guacamole/server
  cd /opt/apache-guacamole/server
  export CPPFLAGS="-Wno-error=deprecated-declarations"
  $STD autoreconf -fi
  $STD ./configure --with-init-dir=/etc/init.d --enable-allow-freerdp-snapshots
  $STD make
  $STD make install
  $STD ldconfig
  msg_ok "Updated Guacamole Server"

  msg_info "Updating Guacamole Client to ${RELEASE_CLIENT}"
  curl -fsSL "https://downloads.apache.org/guacamole/${RELEASE_CLIENT}/binary/guacamole-${RELEASE_CLIENT}.war" -o "/opt/apache-guacamole/tomcat9/webapps/guacamole.war"
  msg_ok "Updated Guacamole Client"

  msg_info "Updating MySQL Connector"
  MYSQL_CONNECTOR_VERSION=$(curl -fsSL "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/maven-metadata.xml" | grep -oP '<latest>\K[^<]+')
  curl -fsSL "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/${MYSQL_CONNECTOR_VERSION}/mysql-connector-j-${MYSQL_CONNECTOR_VERSION}.jar" -o "/etc/guacamole/lib/mysql-connector-j.jar"
  msg_ok "Updated MySQL Connector to ${MYSQL_CONNECTOR_VERSION}"

  msg_info "Updating Guacamole Auth JDBC"
  rm -f /etc/guacamole/extensions/guacamole-auth-jdbc-mysql-*.jar
  curl -fsSL "https://downloads.apache.org/guacamole/${RELEASE_SERVER}/binary/guacamole-auth-jdbc-${RELEASE_SERVER}.tar.gz" -o "/tmp/guacamole-auth-jdbc.tar.gz"
  $STD tar -xf /tmp/guacamole-auth-jdbc.tar.gz -C /tmp
  mv /tmp/guacamole-auth-jdbc-"${RELEASE_SERVER}"/mysql/guacamole-auth-jdbc-mysql-"${RELEASE_SERVER}".jar /etc/guacamole/extensions/
  rm -rf /tmp/guacamole-auth-jdbc*
  msg_ok "Updated Guacamole Auth JDBC"

  echo "${RELEASE_SERVER}" >/opt/apache-guacamole/.version

  msg_info "Starting Services"
  systemctl start tomcat guacd
  msg_ok "Started Services"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080/guacamole${CL}"
