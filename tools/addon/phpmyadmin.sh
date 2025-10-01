#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    ____  __          __  ___      ___       __          _
   / __ \/ /_  ____  /  |/  /_  __/   | ____/ /___ ___  (_)___
  / /_/ / __ \/ __ \/ /|_/ / / / / /| |/ __  / __ `__ \/ / __ \
 / ____/ / / / /_/ / /  / / /_/ / ___ / /_/ / / / / / / / / / /
/_/   /_/ /_/ .___/_/  /_/\__, /_/  |_\__,_/_/ /_/ /_/_/_/ /_/
           /_/           /____/
EOF
}

YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
RD=$(echo "\033[01;31m")
BL=$(echo "\033[36m")
CL=$(echo "\033[m")
CM="${GN}✔️${CL}"
CROSS="${RD}✖️${CL}"
INFO="${BL}ℹ️${CL}"

APP="phpMyAdmin"
INSTALL_DIR_DEBIAN="/var/www/html/phpMyAdmin"
INSTALL_DIR_ALPINE="/usr/share/phpmyadmin"

IFACE=$(ip -4 route | awk '/default/ {print $5; exit}')
IP=$(ip -4 addr show "$IFACE" | awk '/inet / {print $2}' | cut -d/ -f1 | head -n 1)
[[ -z "$IP" ]] && IP=$(hostname -I | awk '{print $1}')
[[ -z "$IP" ]] && IP="127.0.0.1"

# Detect OS
if [[ -f "/etc/alpine-release" ]]; then
  OS="Alpine"
  PKG_MANAGER_INSTALL="apk add --no-cache"
  PKG_QUERY="apk info -e"
  INSTALL_DIR="$INSTALL_DIR_ALPINE"
elif [[ -f "/etc/debian_version" ]]; then
  OS="Debian"
  PKG_MANAGER_INSTALL="apt-get install -y"
  PKG_QUERY="dpkg -l"
  INSTALL_DIR="$INSTALL_DIR_DEBIAN"
else
  echo -e "${CROSS} Unsupported OS detected. Exiting."
  exit 1
fi

header_info

function msg_info() { echo -e "${INFO} ${YW}${1}...${CL}"; }
function msg_ok() { echo -e "${CM} ${GN}${1}${CL}"; }
function msg_error() { echo -e "${CROSS} ${RD}${1}${CL}"; }

function check_internet() {
  msg_info "Checking Internet connectivity to GitHub"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://github.com)
  if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 400 ]]; then
    msg_ok "Internet connectivity OK"
  else
    msg_error "Internet connectivity or GitHub unreachable (Status $HTTP_CODE). Exiting."
    exit 1
  fi
}

function is_phpmyadmin_installed() {
  if [[ "$OS" == "Debian" ]]; then
    [[ -f "$INSTALL_DIR/config.inc.php" ]]
  else
    [[ -d "$INSTALL_DIR_ALPINE" ]] && rc-service lighttpd status &>/dev/null
  fi
}

function install_php_and_modules() {
  msg_info "Checking existing PHP installation"
  if command -v php >/dev/null 2>&1; then
    PHP_VERSION=$(php -r 'echo PHP_VERSION;')
    msg_ok "Found PHP version $PHP_VERSION"
  else
    msg_info "PHP not found, will install PHP core"
  fi

  if [[ "$OS" == "Debian" ]]; then
    PHP_MODULES=("php" "php-mysqli" "php-mbstring" "php-zip" "php-gd" "php-json" "php-curl")
    MISSING_PACKAGES=()
    for pkg in "${PHP_MODULES[@]}"; do
      if ! dpkg -l | grep -qw "$pkg"; then
        MISSING_PACKAGES+=("$pkg")
      fi
    done
    if [[ ${#MISSING_PACKAGES[@]} -gt 0 ]]; then
      msg_info "Installing missing PHP packages: ${MISSING_PACKAGES[*]}"
      if ! apt-get update &>/dev/null || ! apt-get install -y "${MISSING_PACKAGES[@]}" &>/dev/null; then
        msg_error "Failed to install required PHP modules. Exiting."
        exit 1
      fi
      msg_ok "Installed missing PHP packages"
    else
      msg_ok "All required PHP modules are already installed"
    fi
  else
    msg_info "Installing Lighttpd and PHP for Alpine"
    $PKG_MANAGER_INSTALL lighttpd php php-fpm php-session php-json php-mysqli curl tar openssl &>/dev/null
    msg_ok "Installed Lighttpd and PHP"
  fi
}

function install_phpmyadmin() {
  msg_info "Fetching latest phpMyAdmin release from GitHub"
  LATEST_VERSION_RAW=$(curl -s https://api.github.com/repos/phpmyadmin/phpmyadmin/releases/latest | grep tag_name | cut -d '"' -f4)
  LATEST_VERSION=$(echo "$LATEST_VERSION_RAW" | sed -e 's/^RELEASE_//' -e 's/_/./g')
  if [[ -z "$LATEST_VERSION" ]]; then
    msg_error "Could not determine latest phpMyAdmin version from GitHub – falling back to 5.2.2"
    LATEST_VERSION="RELEASE_5_2_2"
  fi
  msg_ok "Latest version: $LATEST_VERSION"

  TARBALL_URL="https://files.phpmyadmin.net/phpMyAdmin/${LATEST_VERSION}/phpMyAdmin-${LATEST_VERSION}-all-languages.tar.gz"
  msg_info "Downloading ${TARBALL_URL}"
  if ! curl -fsSL "$TARBALL_URL" -o /tmp/phpmyadmin.tar.gz; then
    msg_error "Download failed: $TARBALL_URL"
    exit 1
  fi

  mkdir -p "$INSTALL_DIR"
  tar xf /tmp/phpmyadmin.tar.gz --strip-components=1 -C "$INSTALL_DIR"
}

function configure_phpmyadmin() {
  if [[ "$OS" == "Debian" ]]; then
    cp "$INSTALL_DIR/config.sample.inc.php" "$INSTALL_DIR/config.inc.php"
    SECRET=$(openssl rand -base64 24)
    sed -i "s#\$cfg\['blowfish_secret'\] = '';#\$cfg['blowfish_secret'] = '${SECRET}';#" "$INSTALL_DIR/config.inc.php"
    chmod 660 "$INSTALL_DIR/config.inc.php"
    chown -R www-data:www-data "$INSTALL_DIR"
    systemctl restart apache2
    msg_ok "Configured phpMyAdmin with Apache"
  else
    msg_info "Configuring Lighttpd for phpMyAdmin (Alpine detected)"

    mkdir -p /etc/lighttpd
    cat <<EOF >/etc/lighttpd/lighttpd.conf
server.modules = (
    "mod_access",
    "mod_alias",
    "mod_accesslog",
    "mod_fastcgi"
)

server.document-root = "${INSTALL_DIR}"
server.port = 80

index-file.names = ( "index.php", "index.html" )

fastcgi.server = ( ".php" =>
  ((
    "host" => "127.0.0.1",
    "port" => 9000,
    "check-local" => "disable"
  ))
)

alias.url = ( "/phpMyAdmin/" => "${INSTALL_DIR}/" )

accesslog.filename = "/var/log/lighttpd/access.log"
server.errorlog = "/var/log/lighttpd/error.log"
EOF

    msg_info "Starting PHP-FPM and Lighttpd"

    PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION . PHP_MINOR_VERSION;')
    PHP_FPM_SERVICE="php-fpm${PHP_VERSION}"

    if $STD rc-service "$PHP_FPM_SERVICE" start && $STD rc-update add "$PHP_FPM_SERVICE" default; then
      msg_ok "Started PHP-FPM service: $PHP_FPM_SERVICE"
    else
      msg_error "Failed to start PHP-FPM service: $PHP_FPM_SERVICE"
      exit 1
    fi

    $STD rc-service lighttpd start
    $STD rc-update add lighttpd default
    msg_ok "Configured and started Lighttpd successfully"

  fi
}

function uninstall_phpmyadmin() {
  msg_info "Stopping Webserver"
  if [[ "$OS" == "Debian" ]]; then
    systemctl stop apache2
  else
    $STD rc-service lighttpd stop
    $STD rc-service php-fpm stop
  fi

  msg_info "Removing phpMyAdmin directory"
  rm -rf "$INSTALL_DIR"

  if [[ "$OS" == "Alpine" ]]; then
    msg_info "Removing Lighttpd config"
    rm -f /etc/lighttpd/lighttpd.conf
    $STD rc-service php-fpm restart
    $STD rc-service lighttpd restart
  else
    $STD systemctl restart apache2
  fi
  msg_ok "Uninstalled phpMyAdmin"
}

function update_phpmyadmin() {
  msg_info "Fetching latest phpMyAdmin release from GitHub"
  LATEST_VERSION_RAW=$(curl -s https://api.github.com/repos/phpmyadmin/phpmyadmin/releases/latest | grep tag_name | cut -d '"' -f4)
  LATEST_VERSION=$(echo "$LATEST_VERSION_RAW" | sed -e 's/^RELEASE_//' -e 's/_/./g')

  if [[ -z "$LATEST_VERSION" ]]; then
    msg_error "Could not determine latest phpMyAdmin version from GitHub – falling back to 5.2.2"
    LATEST_VERSION="5.2.2"
  fi
  msg_ok "Latest version: $LATEST_VERSION"

  TARBALL_URL="https://files.phpmyadmin.net/phpMyAdmin/${LATEST_VERSION}/phpMyAdmin-${LATEST_VERSION}-all-languages.tar.gz"
  msg_info "Downloading ${TARBALL_URL}"

  if ! curl -fsSL "$TARBALL_URL" -o /tmp/phpmyadmin.tar.gz; then
    msg_error "Download failed: $TARBALL_URL"
    exit 1
  fi

  BACKUP_DIR="/tmp/phpmyadmin-backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BACKUP_DIR"
  BACKUP_ITEMS=("config.inc.php" "upload" "save" "tmp" "themes")

  msg_info "Backing up existing phpMyAdmin data"
  for item in "${BACKUP_ITEMS[@]}"; do
    [[ -e "$INSTALL_DIR/$item" ]] && cp -a "$INSTALL_DIR/$item" "$BACKUP_DIR/" && echo "  ↪︎ $item"
  done
  msg_ok "Backup completed: $BACKUP_DIR"

  tar xf /tmp/phpmyadmin.tar.gz --strip-components=1 -C "$INSTALL_DIR"
  msg_ok "Extracted phpMyAdmin $LATEST_VERSION"

  msg_info "Restoring preserved files"
  for item in "${BACKUP_ITEMS[@]}"; do
    [[ -e "$BACKUP_DIR/$item" ]] && cp -a "$BACKUP_DIR/$item" "$INSTALL_DIR/" && echo "  ↪︎ $item restored"
  done
  msg_ok "Restoration completed"

  configure_phpmyadmin
}

if is_phpmyadmin_installed; then
  echo -e "${YW}⚠️ ${APP} is already installed at ${INSTALL_DIR}.${CL}"
  read -r -p "Would you like to Update (1), Uninstall (2) or Cancel (3)? [1/2/3]: " action
  action="${action//[[:space:]]/}"
  case "$action" in
  1)
    check_internet
    update_phpmyadmin
    ;;
  2)
    uninstall_phpmyadmin
    ;;
  3)
    echo -e "${YW}⚠️ Action cancelled. Exiting.${CL}"
    exit 0
    ;;
  *)
    echo -e "${YW}⚠️ Invalid input. Exiting.${CL}"
    exit 1
    ;;
  esac
else
  read -r -p "Would you like to install ${APP}? (y/n): " install_prompt
  install_prompt="${install_prompt//[[:space:]]/}"
  if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
    check_internet
    install_php_and_modules
    install_phpmyadmin
    configure_phpmyadmin
    if [[ "$OS" == "Debian" ]]; then
      echo -e "${CM} ${GN}${APP} is reachable at: ${BL}http://${IP}/phpMyAdmin${CL}"
    else
      echo -e "${CM} ${GN}${APP} is reachable at: ${BL}http://${IP}/${CL}"
    fi
  else
    echo -e "${YW}⚠️ Installation skipped. Exiting.${CL}"
    exit 0
  fi
fi
