#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Original Author: Slaviša Arežina (tremor021)
# Revamped Script: Floris Claessens (FlorisCl)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wger-project/wger

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# --------------------------------------------------
# Constants
# --------------------------------------------------
WGER_USER="wger"
WGER_HOME="/home/wger"
WGER_SRC="${WGER_HOME}/src"
WGER_SETTINGS="${WGER_SRC}/settings"
WGER_VENV="${WGER_HOME}/venv"
WGER_DB="${WGER_HOME}/db"
WGER_PORT="${WGER_PORT:-3000}"

# --------------------------------------------------
# Helpers
# --------------------------------------------------
section() {
  echo -e "\n\e[1;34m▶ $1\e[0m"
}

# --------------------------------------------------
# System setup
# --------------------------------------------------
install_dependencies() {
  msg_info "Installing system dependencies"
  $STD apt install -y \
    git \
    apache2 \
    libapache2-mod-wsgi-py3 \
    python3-venv \
    python3-pip \
    redis-server \
    rsync
  msg_ok "System dependencies installed"
}

setup_redis() {
  msg_info "Starting Redis"
  systemctl enable --now redis-server
  redis-cli ping | grep -q '^PONG$' \
    && msg_ok "Redis is running" \
    || msg_error "Redis failed to start"
}

setup_node() {
  msg_info "Setting up Node.js toolchain"
  NODE_VERSION="22" NODE_MODULE="sass" setup_nodejs
  corepack enable
  corepack prepare npm --activate
  corepack disable yarn pnpm
  msg_ok "Node.js toolchain ready"
}

# --------------------------------------------------
# Apache
# --------------------------------------------------
setup_apache_port() {
  msg_info "Configuring Apache port (${WGER_PORT})"

  sed -i "s/^Listen .*/Listen ${WGER_PORT}/" /etc/apache2/ports.conf || true
  grep -q "^Listen ${WGER_PORT}$" /etc/apache2/ports.conf \
    || echo "Listen ${WGER_PORT}" >> /etc/apache2/ports.conf

  msg_ok "Apache listening on port ${WGER_PORT}"
}

setup_apache_permissions() {
  msg_info "Adjusting Apache systemd permissions"

  mkdir -p /etc/systemd/system/apache2.service.d
  cat <<EOF >/etc/systemd/system/apache2.service.d/override.conf
[Service]
ProtectHome=false
EOF

  systemctl daemon-reexec
  msg_ok "Apache permissions adjusted"
}

setup_apache_vhost() {
  msg_info "Creating Apache virtual host"

  cat <<EOF >/etc/apache2/sites-available/wger.conf
<Directory ${WGER_SRC}>
  <Files wsgi.py>
    Require all granted
  </Files>
</Directory>

<VirtualHost *:${WGER_PORT}>
  WSGIApplicationGroup %{GLOBAL}
  WSGIDaemonProcess wger python-path=${WGER_SRC} python-home=${WGER_VENV}
  WSGIProcessGroup wger
  WSGIScriptAlias / ${WGER_SRC}/wger/wsgi.py
  WSGIPassAuthorization On

  Alias /static/ ${WGER_HOME}/static/
  <Directory ${WGER_HOME}/static>
    Require all granted
  </Directory>

  Alias /media/ ${WGER_HOME}/media/
  <Directory ${WGER_HOME}/media>
    Require all granted
  </Directory>

  ErrorLog /var/log/apache2/wger-error.log
  CustomLog /var/log/apache2/wger-access.log combined
</VirtualHost>
EOF

  $STD a2dissite 000-default.conf
  $STD a2ensite wger
  systemctl restart apache2

  msg_ok "Apache virtual host enabled"
}

# --------------------------------------------------
# wger application
# --------------------------------------------------
create_wger_user() {
  msg_info "Creating wger user and directories"

  id ${WGER_USER} &>/dev/null \
    || $STD adduser ${WGER_USER} --disabled-password --gecos ""

  mkdir -p ${WGER_DB} ${WGER_HOME}/{static,media}
  touch ${WGER_DB}/database.sqlite

  chown :www-data -R ${WGER_DB}
  chmod g+w ${WGER_DB} ${WGER_DB}/database.sqlite
  chmod o+w ${WGER_HOME}/media

  msg_ok "User and directories ready"
}

fetch_wger_source() {
  msg_info "Downloading wger source"

  local temp_dir
  temp_dir=$(mktemp -d)
  cd "${temp_dir}" || exit


  RELEASE=$(curl -fsSL https://api.github.com/repos/wger-project/wger/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')
  curl -fsSL https://github.com/wger-project/wger/archive/refs/tags/${RELEASE}.tar.gz -o ${RELEASE}.tar.gz
  tar xzf ${RELEASE}.tar.gz
  mv wger-${RELEASE} ${WGER_SRC}

  rm -rf "${temp_dir}"
  echo "${RELEASE}" >/opt/wger_version.txt
  msg_ok "Source downloaded"
}

setup_python_env() {
  msg_info "Setting up Python virtual environment"
  cd ${WGER_SRC} || EXIT

  [ -d ${WGER_VENV} ] || python3 -m venv ${WGER_VENV} &>/dev/null
  source ${WGER_VENV}/bin/activate
  $STD pip install -U pip setuptools wheel

  msg_ok "Python environment ready"
}

install_python_deps() {
  msg_info "Installing Python dependencies"

  cd "${WGER_SRC}" || exit
  $STD pip install . 
  $STD pip install psycopg2-binary

  msg_ok "Python dependencies installed"
}

configure_wger() {
  msg_info "Configuring wger application"

  export DJANGO_SETTINGS_MODULE=settings.main
  export PYTHONPATH=${WGER_SRC}

  $STD wger bootstrap
  $STD python3 manage.py collectstatic --no-input

  msg_ok "wger configured"
}

# --------------------------------------------------
# Services
# --------------------------------------------------
setup_dummy_service() {
  msg_info "Registering wger system service"

  cat <<EOF >/etc/systemd/system/wger.service
[Unit]
Description=wger Service
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

  systemctl enable -q --now wger
  msg_ok "wger service registered"
}

setup_celery_worker() {
  msg_info "Creating Celery worker service"

  cat <<EOF >/etc/systemd/system/celery.service
[Unit]
Description=wger Celery Worker
After=network.target redis-server.service
Requires=redis-server.service

[Service]
Type=simple
User=${WGER_USER}
Group=${WGER_USER}
WorkingDirectory=${WGER_SRC}
Environment=DJANGO_SETTINGS_MODULE=settings.main
Environment=PYTHONPATH=${WGER_SRC}
Environment=PYTHONUNBUFFERED=1
Environment=USE_CELERY=True
Environment=CELERY_BROKER=redis://localhost:6379/2
Environment=CELERY_BACKEND=redis://localhost:6379/2
ExecStart=${WGER_VENV}/bin/celery -A wger worker -l info
Restart=always
PrivateTmp=true
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=${WGER_HOME} 

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now celery
  msg_ok "Celery worker running"
}

setup_celery_beat() {
  msg_info "Preparing Celery Beat schedule directory"
  mkdir -p /var/lib/wger/celery
  chown -R wger:wger /var/lib/wger
  chmod 755 /var/lib/wger
  chmod 700 /var/lib/wger/celery
  msg_ok "Celery Beat schedule directory ready"

  msg_info "Creating Celery beat service"

  cat <<EOF >/etc/systemd/system/celery-beat.service
[Unit]
Description=wger Celery Beat
After=network.target redis-server.service
Requires=redis-server.service

[Service]
Type=simple
User=${WGER_USER}
Group=${WGER_USER}
WorkingDirectory=${WGER_SRC}
Environment=DJANGO_SETTINGS_MODULE=settings.main
Environment=PYTHONPATH=${WGER_SRC}
Environment=USE_CELERY=True
Environment=CELERY_BROKER=redis://localhost:6379/2
Environment=CELERY_BACKEND=redis://localhost:6379/2
Environment=PYTHONUNBUFFERED=1
ExecStart=${WGER_VENV}/bin/celery -A wger beat -l info --schedule /var/lib/wger/celery/celerybeat-schedule
Restart=always
PrivateTmp=true
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=${WGER_HOME} /var/lib/wger

[Install]
WantedBy=multi-user.target
EOF

  systemctl enable --now celery-beat
  msg_ok "Celery beat running"
}

# --------------------------------------------------
# Permissions & cleanup
# --------------------------------------------------
finalize_permissions() {
  msg_info "Applying filesystem permissions"

  chown -R ${WGER_USER}:wger ${WGER_SRC}
  chown -R ${WGER_USER}:www-data ${WGER_HOME}/{static,media} ${WGER_DB}
  chmod -R 775 ${WGER_HOME}/{static,media} ${WGER_DB}

  # Required for Apache traversal
  chmod 755 /home ${WGER_HOME} ${WGER_SRC}

  msg_ok "Permissions applied"
}

create_celery_helper() {
msg_info "Installing Celery helper command"

cat <<EOF >/usr/local/bin/celery
#!/usr/bin/env bash
export DJANGO_SETTINGS_MODULE=settings.main 
export PYTHONPATH=/home/wger/src 
export CELERY_BROKER=redis://localhost:6379/2 
export CELERY_BACKEND=redis://localhost:6379/2

exec /home/wger/venv/bin/celery "\$@"
EOF

chmod 755 /usr/local/bin/celery

msg_ok "Celery helper installed (celery and celery-beat)"
}

# --------------------------------------------------
# Execution
# --------------------------------------------------
section "System Preparation"
install_dependencies
setup_redis
setup_node

section "Apache Configuration"
setup_apache_port
setup_apache_permissions
setup_apache_vhost

section "wger Application Setup"
create_wger_user
fetch_wger_source
setup_python_env
install_python_deps
configure_wger

section "Services"
setup_dummy_service
setup_celery_worker
setup_celery_beat

section "Finalization"
finalize_permissions
create_celery_helper
motd_ssh
customize
cleanup_lxc
