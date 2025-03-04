#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tomcat.apache.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    gnupg2 \
    curl \
    sudo \
    mc \
    lsb-release \
    gpg \
    apt-transport-https
msg_ok "Installed Dependencies"

msg_info "Setting up Adoptium Repository"
mkdir -p /etc/apt/keyrings
wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor >/etc/apt/trusted.gpg.d/adoptium.gpg
echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" >/etc/apt/sources.list.d/adoptium.list
$STD apt-get update
msg_ok "Set up Adoptium Repository"

read -r -p "Which Tomcat version would you like to install? (9, 10.1, 11): " version
case $version in
9)
    TOMCAT_VERSION="9"
    echo "Which LTS Java version would you like to use? (8, 11, 17, 21): "
    read -r jdk_version
    case $jdk_version in
    8)
        msg_info "Installing Temurin JDK 8 (LTS) for Tomcat $TOMCAT_VERSION"
        $STD apt-get install -y temurin-8-jdk
        msg_ok "Setup Temurin JDK 8 (LTS)"
        ;;
    11)
        msg_info "Installing Temurin JDK 11 (LTS) for Tomcat $TOMCAT_VERSION"
        $STD apt-get install -y temurin-11-jdk
        msg_ok "Setup Temurin JDK 11 (LTS)"
        ;;
    17)
        msg_info "Installing Temurin JDK 17 (LTS) for Tomcat $TOMCAT_VERSION"
        $STD apt-get install -qqy temurin-17-jdk
        msg_ok "Setup Temurin JDK 17 (LTS)"
        ;;
    21)
        msg_info "Installing Temurin JDK 21 (LTS) for Tomcat $TOMCAT_VERSION"
        $STD apt-get install -y temurin-21-jdk
        msg_ok "Setup Temurin JDK 21 (LTS)"
        ;;
    *)
        msg_error "Invalid JDK version selected. Please enter 8, 11, 17 or 21."
        exit 1
        ;;
    esac
    ;;
10 | 10.1)
    TOMCAT_VERSION="10"
    echo "Which LTS Java version would you like to use? (11, 17): "
    read -r jdk_version
    case $jdk_version in
    11)
        msg_info "Installing Temurin JDK 11 (LTS) for Tomcat $TOMCAT_VERSION"
        $STD apt-get install -y temurin-11-jdk
        msg_ok "Setup Temurin JDK 11"
        ;;
    17)
        msg_info "Installing Temurin JDK 17 (LTS) for Tomcat $TOMCAT_VERSION"
        $STD apt-get install -y temurin-17-jdk
        msg_ok "Setup Temurin JDK 17"
        ;;
    21)
        msg_info "Installing Temurin JDK 21 (LTS) for Tomcat $TOMCAT_VERSION"
        $STD apt-get install -y temurin-21-jdk
        msg_ok "Setup Temurin JDK 21 (LTS)"
        ;;
    *)
        msg_error "Invalid JDK version selected. Please enter 11 or 17."
        exit 1
        ;;
    esac
    ;;
11)
    TOMCAT_VERSION="11"
    echo "Which LTS Java version would you like to use? (17, 21): "
    read -r jdk_version
    case $jdk_version in
    17)
        msg_info "Installing Temurin JDK 17 (LTS) for Tomcat $TOMCAT_VERSION"
        $STD apt-get install -qqy temurin-17-jdk
        msg_ok "Setup Temurin JDK 17"
        ;;
    21)
        msg_info "Installing Temurin JDK 21 (LTS) for Tomcat $TOMCAT_VERSION"
        $STD apt-get install -y temurin-21-jdk
        msg_ok "Setup Temurin JDK 21 (LTS)"
        ;;
    *)
        msg_error "Invalid JDK version selected. Please enter 17 or 21."
        exit 1
        ;;
    esac
    ;;
*)
    msg_error "Invalid Tomcat version selected. Please enter 9, 10.1 or 11."
    exit 1
    ;;
esac

msg_info "Installing Tomcat $TOMCAT_VERSION"
LATEST_VERSION=$(curl -s "https://dlcdn.apache.org/tomcat/tomcat-$TOMCAT_VERSION/" | grep -oP 'v[0-9]+\.[0-9]+\.[0-9]+(-M[0-9]+)?/' | sort -V | tail -n 1 | sed 's/\/$//; s/v//')
TOMCAT_URL="https://dlcdn.apache.org/tomcat/tomcat-$TOMCAT_VERSION/v$LATEST_VERSION/bin/apache-tomcat-$LATEST_VERSION.tar.gz"
wget -qO /tmp/tomcat.tar.gz "$TOMCAT_URL"
mkdir -p /opt/tomcat-$TOMCAT_VERSION
tar --strip-components=1 -xzf /tmp/tomcat.tar.gz -C /opt/tomcat-$TOMCAT_VERSION
chown -R root:root /opt/tomcat-$TOMCAT_VERSION

cat <<EOF >/etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
User=$(whoami)
Group=$(whoami)
Environment=JAVA_HOME=/usr/lib/jvm/temurin-${jdk_version}-jdk-amd64
Environment=CATALINA_HOME=/opt/tomcat-$TOMCAT_VERSION
Environment=CATALINA_BASE=/opt/tomcat-$TOMCAT_VERSION
Environment=CATALINA_PID=/opt/tomcat-$TOMCAT_VERSION/temp/tomcat.pid
ExecStart=/opt/tomcat-$TOMCAT_VERSION/bin/catalina.sh start
ExecStop=/opt/tomcat-$TOMCAT_VERSION/bin/catalina.sh stop
PIDFile=/opt/tomcat-$TOMCAT_VERSION/temp/tomcat.pid
SuccessExitStatus=143
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now tomcat
msg_ok "Tomcat $LATEST_VERSION installed and started"

motd_ssh
customize

msg_info "Cleaning up"
rm -f /tmp/tomcat.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
