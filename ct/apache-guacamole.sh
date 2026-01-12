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

  # Fetch latest versions
  LATEST_TOMCAT=$(curl -fsSL https://dlcdn.apache.org/tomcat/tomcat-9/ | grep -oP '(?<=href=")v[^"/]+(?=/")' | sed 's/^v//' | sort -V | tail -n1)
  LATEST_SERVER=$(curl -fsSL https://api.github.com/repos/apache/guacamole-server/tags | jq -r '.[].name' | grep -v -- '-RC' | head -n 1)
  LATEST_CLIENT=$(curl -fsSL https://api.github.com/repos/apache/guacamole-client/tags | jq -r '.[].name' | grep -v -- '-RC' | head -n 1)
  LATEST_MYSQL_CONNECTOR=$(curl -fsSL "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/maven-metadata.xml" | grep -oP '<latest>\K[^<]+')

  # Read current versions from ~/.guacamole_*
  CURRENT_TOMCAT=$(cat ~/.guacamole_tomcat 2>/dev/null || echo "unknown")
  CURRENT_SERVER=$(cat ~/.guacamole_server 2>/dev/null || echo "unknown")
  CURRENT_CLIENT=$(cat ~/.guacamole_client 2>/dev/null || echo "unknown")
  CURRENT_MYSQL_CONNECTOR=$(cat ~/.guacamole_mysql_connector 2>/dev/null || echo "unknown")

  UPDATE_NEEDED=false
  [[ "$CURRENT_TOMCAT" != "$LATEST_TOMCAT" ]] && UPDATE_NEEDED=true
  [[ "$CURRENT_SERVER" != "$LATEST_SERVER" ]] && UPDATE_NEEDED=true
  [[ "$CURRENT_CLIENT" != "$LATEST_CLIENT" ]] && UPDATE_NEEDED=true
  [[ "$CURRENT_MYSQL_CONNECTOR" != "$LATEST_MYSQL_CONNECTOR" ]] && UPDATE_NEEDED=true

  if [[ "$UPDATE_NEEDED" == "false" ]]; then
    msg_ok "All components are up to date"
    exit
  fi

  JAVA_VERSION="11" setup_java

  msg_info "Stopping Services"
  systemctl stop guacd tomcat
  msg_ok "Stopped Services"

  # Update Tomcat
  if [[ "$CURRENT_TOMCAT" != "$LATEST_TOMCAT" ]]; then
    msg_info "Updating Tomcat (${CURRENT_TOMCAT} → ${LATEST_TOMCAT})"
    cp -a /opt/apache-guacamole/tomcat9/conf /tmp/tomcat-conf-backup
    curl -fsSL "https://dlcdn.apache.org/tomcat/tomcat-9/v${LATEST_TOMCAT}/bin/apache-tomcat-${LATEST_TOMCAT}.tar.gz" | tar -xz -C /opt/apache-guacamole/tomcat9 --strip-components=1 --exclude='conf/*'
    cp -a /tmp/tomcat-conf-backup/* /opt/apache-guacamole/tomcat9/conf/
    rm -rf /tmp/tomcat-conf-backup
    chown -R tomcat: /opt/apache-guacamole/tomcat9
    echo "${LATEST_TOMCAT}" >~/.guacamole_tomcat
    msg_ok "Updated Tomcat"
  else
    msg_ok "Tomcat already up to date (${CURRENT_TOMCAT})"
  fi

  # Update Guacamole Server
  if [[ "$CURRENT_SERVER" != "$LATEST_SERVER" ]]; then
    msg_info "Updating Guacamole Server (${CURRENT_SERVER} → ${LATEST_SERVER})"
    rm -rf /opt/apache-guacamole/server/*
    curl -fsSL "https://api.github.com/repos/apache/guacamole-server/tarball/refs/tags/${LATEST_SERVER}" | tar -xz --strip-components=1 -C /opt/apache-guacamole/server
    cd /opt/apache-guacamole/server
    export CPPFLAGS="-Wno-error=deprecated-declarations"
    $STD autoreconf -fi
    $STD ./configure --with-init-dir=/etc/init.d --enable-allow-freerdp-snapshots
    $STD make
    $STD make install
    $STD ldconfig
    echo "${LATEST_SERVER}" >~/.guacamole_server
    msg_ok "Updated Guacamole Server"

    # Auth JDBC follows server version
    msg_info "Updating Guacamole Auth JDBC"
    rm -f /etc/guacamole/extensions/guacamole-auth-jdbc-mysql-*.jar
    curl -fsSL "https://downloads.apache.org/guacamole/${LATEST_SERVER}/binary/guacamole-auth-jdbc-${LATEST_SERVER}.tar.gz" -o "/tmp/guacamole-auth-jdbc.tar.gz"
    $STD tar -xf /tmp/guacamole-auth-jdbc.tar.gz -C /tmp
    mv /tmp/guacamole-auth-jdbc-"${LATEST_SERVER}"/mysql/guacamole-auth-jdbc-mysql-"${LATEST_SERVER}".jar /etc/guacamole/extensions/
    rm -rf /tmp/guacamole-auth-jdbc*
    echo "${LATEST_SERVER}" >~/.guacamole_auth_jdbc
    msg_ok "Updated Guacamole Auth JDBC"
  else
    msg_ok "Guacamole Server already up to date (${CURRENT_SERVER})"
  fi

  # Update Guacamole Client
  if [[ "$CURRENT_CLIENT" != "$LATEST_CLIENT" ]]; then
    msg_info "Updating Guacamole Client (${CURRENT_CLIENT} → ${LATEST_CLIENT})"
    curl -fsSL "https://downloads.apache.org/guacamole/${LATEST_CLIENT}/binary/guacamole-${LATEST_CLIENT}.war" -o "/opt/apache-guacamole/tomcat9/webapps/guacamole.war"
    echo "${LATEST_CLIENT}" >~/.guacamole_client
    msg_ok "Updated Guacamole Client"
  else
    msg_ok "Guacamole Client already up to date (${CURRENT_CLIENT})"
  fi

  # Update MySQL Connector
  if [[ "$CURRENT_MYSQL_CONNECTOR" != "$LATEST_MYSQL_CONNECTOR" ]]; then
    msg_info "Updating MySQL Connector (${CURRENT_MYSQL_CONNECTOR} → ${LATEST_MYSQL_CONNECTOR})"
    curl -fsSL "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/${LATEST_MYSQL_CONNECTOR}/mysql-connector-j-${LATEST_MYSQL_CONNECTOR}.jar" -o "/etc/guacamole/lib/mysql-connector-j.jar"
    echo "${LATEST_MYSQL_CONNECTOR}" >~/.guacamole_mysql_connector
    msg_ok "Updated MySQL Connector"
  else
    msg_ok "MySQL Connector already up to date (${CURRENT_MYSQL_CONNECTOR})"
  fi

  # Apply SQL Schema Upgrades (CRITICAL!)
  if [[ "$CURRENT_SERVER" != "$LATEST_SERVER" ]]; then
    msg_info "Applying MySQL Schema Upgrades"
    cd /tmp/guacamole-auth-jdbc-"${LATEST_SERVER}"/mysql/schema/upgrade/
    UPGRADE_FILES=($(ls -1 upgrade-pre-*.sql 2>/dev/null | sort -V))

    if [[ ${#UPGRADE_FILES[@]} -gt 0 ]]; then
      for SQL_FILE in "${UPGRADE_FILES[@]}"; do
        FILE_VERSION=$(echo ${SQL_FILE} | grep -oP 'upgrade-pre-\K[0-9\.]+(?=\.)')
        # Apply upgrade if file version is newer than current but older/equal to target
        if [[ $(echo -e "${FILE_VERSION}\n${CURRENT_SERVER}" | sort -V | head -n1) == "${CURRENT_SERVER}" && "${FILE_VERSION}" != "${CURRENT_SERVER}" ]]; then
          msg_info "Applying schema patch: ${SQL_FILE}"
          mysql -u root guacamole_db <"${SQL_FILE}" 2>/dev/null
          if [[ $? -eq 0 ]]; then
            msg_ok "Applied ${SQL_FILE}"
          else
            msg_warn "Failed to apply ${SQL_FILE} (may already be applied)"
          fi
        fi
      done
    fi
    msg_ok "MySQL Schema updated"
  fi

  # Check and upgrade optional extensions
  # TOTP Extension
  if [[ -f /etc/guacamole/extensions/guacamole-auth-totp-*.jar ]]; then
    msg_info "Updating TOTP Extension"
    rm -f /etc/guacamole/extensions/guacamole-auth-totp-*.jar
    curl -fsSL "https://downloads.apache.org/guacamole/${LATEST_SERVER}/binary/guacamole-auth-totp-${LATEST_SERVER}.tar.gz" -o "/tmp/guacamole-auth-totp.tar.gz"
    $STD tar -xf /tmp/guacamole-auth-totp.tar.gz -C /tmp
    mv /tmp/guacamole-auth-totp-"${LATEST_SERVER}"/guacamole-auth-totp-"${LATEST_SERVER}".jar /etc/guacamole/extensions/
    chmod 664 /etc/guacamole/extensions/guacamole-auth-totp-"${LATEST_SERVER}".jar
    rm -rf /tmp/guacamole-auth-totp*
    msg_ok "Updated TOTP Extension"
  fi

  # DUO Extension
  if [[ -f /etc/guacamole/extensions/guacamole-auth-duo-*.jar ]]; then
    msg_info "Updating DUO Extension"
    rm -f /etc/guacamole/extensions/guacamole-auth-duo-*.jar
    curl -fsSL "https://downloads.apache.org/guacamole/${LATEST_SERVER}/binary/guacamole-auth-duo-${LATEST_SERVER}.tar.gz" -o "/tmp/guacamole-auth-duo.tar.gz"
    $STD tar -xf /tmp/guacamole-auth-duo.tar.gz -C /tmp
    mv /tmp/guacamole-auth-duo-"${LATEST_SERVER}"/guacamole-auth-duo-"${LATEST_SERVER}".jar /etc/guacamole/extensions/
    chmod 664 /etc/guacamole/extensions/guacamole-auth-duo-"${LATEST_SERVER}".jar
    rm -rf /tmp/guacamole-auth-duo*
    msg_ok "Updated DUO Extension"
  fi

  # LDAP Extension
  if [[ -f /etc/guacamole/extensions/guacamole-auth-ldap-*.jar ]]; then
    msg_info "Updating LDAP Extension"
    rm -f /etc/guacamole/extensions/guacamole-auth-ldap-*.jar
    curl -fsSL "https://downloads.apache.org/guacamole/${LATEST_SERVER}/binary/guacamole-auth-ldap-${LATEST_SERVER}.tar.gz" -o "/tmp/guacamole-auth-ldap.tar.gz"
    $STD tar -xf /tmp/guacamole-auth-ldap.tar.gz -C /tmp
    mv /tmp/guacamole-auth-ldap-"${LATEST_SERVER}"/guacamole-auth-ldap-"${LATEST_SERVER}".jar /etc/guacamole/extensions/
    chmod 664 /etc/guacamole/extensions/guacamole-auth-ldap-"${LATEST_SERVER}".jar
    rm -rf /tmp/guacamole-auth-ldap*
    msg_ok "Updated LDAP Extension"
  fi

  # Quick Connect Extension
  if [[ -f /etc/guacamole/extensions/guacamole-auth-quickconnect-*.jar ]]; then
    msg_info "Updating Quick Connect Extension"
    rm -f /etc/guacamole/extensions/guacamole-auth-quickconnect-*.jar
    curl -fsSL "https://downloads.apache.org/guacamole/${LATEST_SERVER}/binary/guacamole-auth-quickconnect-${LATEST_SERVER}.tar.gz" -o "/tmp/guacamole-auth-quickconnect.tar.gz"
    $STD tar -xf /tmp/guacamole-auth-quickconnect.tar.gz -C /tmp
    mv /tmp/guacamole-auth-quickconnect-"${LATEST_SERVER}"/guacamole-auth-quickconnect-"${LATEST_SERVER}".jar /etc/guacamole/extensions/
    chmod 664 /etc/guacamole/extensions/guacamole-auth-quickconnect-"${LATEST_SERVER}".jar
    rm -rf /tmp/guacamole-auth-quickconnect*
    msg_ok "Updated Quick Connect Extension"
  fi

  # History Recording Storage Extension
  if [[ -f /etc/guacamole/extensions/guacamole-history-recording-storage-*.jar ]]; then
    msg_info "Updating History Recording Storage Extension"
    rm -f /etc/guacamole/extensions/guacamole-history-recording-storage-*.jar
    curl -fsSL "https://downloads.apache.org/guacamole/${LATEST_SERVER}/binary/guacamole-history-recording-storage-${LATEST_SERVER}.tar.gz" -o "/tmp/guacamole-history-recording-storage.tar.gz"
    $STD tar -xf /tmp/guacamole-history-recording-storage.tar.gz -C /tmp
    mv /tmp/guacamole-history-recording-storage-"${LATEST_SERVER}"/guacamole-history-recording-storage-"${LATEST_SERVER}".jar /etc/guacamole/extensions/
    chmod 664 /etc/guacamole/extensions/guacamole-history-recording-storage-"${LATEST_SERVER}".jar
    rm -rf /tmp/guacamole-history-recording-storage*
    msg_ok "Updated History Recording Storage Extension"
  fi

  # Reset permissions and prepare for service start
  msg_info "Resetting permissions"
  mkdir -p /var/guacamole
  chown daemon:daemon /var/guacamole
  mkdir -p /home/daemon/.config/freerdp
  chown daemon:daemon /home/daemon/.config/freerdp
  msg_ok "Permissions reset"

  msg_info "Starting Services"
  systemctl daemon-reload
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
