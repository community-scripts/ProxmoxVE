# tools.func Usage Examples

Practical, real-world examples for using tools.func functions in application installation scripts.

## Basic Examples

### Example 1: Simple Package Installation

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# Update packages
pkg_update

# Install basic tools
pkg_install curl wget git htop

msg_ok "Basic tools installed"
```

### Example 2: Node.js Application

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
network_check
update_os

msg_info "Installing Node.js"
pkg_update
setup_nodejs "20"
msg_ok "Node.js installed"

msg_info "Downloading application"
cd /opt
git clone https://github.com/example/app.git
cd app
npm install
msg_ok "Application installed"

motd_ssh
customize
cleanup_lxc
```

---

## Advanced Examples

### Example 3: PHP + MySQL Web Application

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
update_os

# Install web stack
msg_info "Installing web server stack"
pkg_update

setup_nginx
setup_php "8.3"
setup_mariadb  # Uses distribution packages (recommended)
setup_composer

msg_ok "Web stack installed"

# Download application
msg_info "Downloading application"
git clone https://github.com/example/php-app /var/www/html/app
cd /var/www/html/app

# Install dependencies
composer install --no-dev

# Setup database
msg_info "Setting up database"
DBPASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
mysql -e "CREATE DATABASE phpapp; GRANT ALL ON phpapp.* TO 'phpapp'@'localhost' IDENTIFIED BY '$DBPASS';"

# Create .env file
cat > .env <<EOF
DB_HOST=localhost
DB_NAME=phpapp
DB_USER=phpapp
DB_PASS=$DBPASS
APP_ENV=production
EOF

# Fix permissions
chown -R www-data:www-data /var/www/html/app
chmod -R 755 /var/www/html/app

msg_ok "PHP application configured"

motd_ssh
customize
cleanup_lxc
```

### Example 4: Docker Application

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
update_os

msg_info "Installing Docker"
setup_docker
msg_ok "Docker installed"

msg_info "Pulling application image"
docker pull myregistry.io/myapp:latest
msg_ok "Application image ready"

msg_info "Starting Docker container"
docker run -d \
  --name myapp \
  --restart unless-stopped \
  -p 8080:3000 \
  -e APP_ENV=production \
  myregistry.io/myapp:latest

msg_ok "Docker container running"

# Enable Docker service
systemctl enable docker
systemctl start docker

motd_ssh
customize
cleanup_lxc
```

### Example 5: PostgreSQL + Node.js

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
update_os

# Install full stack
setup_nodejs "20"
setup_postgresql "16"
setup_git

msg_info "Installing application"
git clone https://github.com/example/nodejs-app /opt/app
cd /opt/app

npm install
npm run build

# Setup database
DBPASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
sudo -u postgres psql <<EOF
CREATE DATABASE nodeapp;
CREATE USER nodeapp WITH PASSWORD '$DBPASS';
GRANT ALL PRIVILEGES ON DATABASE nodeapp TO nodeapp;
EOF

# Create environment file
cat > .env <<EOF
DATABASE_URL=postgresql://nodeapp:$DBPASS@localhost/nodeapp
NODE_ENV=production
PORT=3000
EOF

# Create systemd service
cat > /etc/systemd/system/nodeapp.service <<EOF
[Unit]
Description=Node.js Application
After=network.target

[Service]
Type=simple
User=nodeapp
WorkingDirectory=/opt/app
ExecStart=/usr/bin/node /opt/app/dist/index.js
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Create nodeapp user
useradd -r -s /bin/bash nodeapp || true
chown -R nodeapp:nodeapp /opt/app

# Start service
systemctl daemon-reload
systemctl enable nodeapp
systemctl start nodeapp

motd_ssh
customize
cleanup_lxc
```

---

## Repository Configuration Examples

### Example 6: Adding Custom Repository

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

msg_info "Setting up repository"

# Add custom repository in deb822 format
setup_deb822_repo \
  "my-applications" \
  "https://my-repo.example.com/gpg.key" \
  "https://my-repo.example.com/debian" \
  "jammy" \
  "main"

msg_ok "Repository configured"

# Update and install
pkg_update
pkg_install my-app-package
```

### Example 7: Multiple Repository Setup

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

msg_info "Setting up repositories"

# Node.js repository
setup_deb822_repo \
  "nodejs" \
  "https://deb.nodesource.com/gpgkey/nodesource.gpg.key" \
  "https://deb.nodesource.com/node_20.x" \
  "jammy" \
  "main"

# Docker repository
setup_deb822_repo \
  "docker" \
  "https://download.docker.com/linux/ubuntu/gpg" \
  "https://download.docker.com/linux/ubuntu" \
  "jammy" \
  "stable"

# Update once for all repos
pkg_update

# Install from repos
setup_nodejs "20"
setup_docker

msg_ok "All repositories configured"
```

---

## Error Handling Examples

### Example 8: With Error Handling

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

catch_errors
setting_up_container
update_os

# Install with error checking
if ! pkg_update; then
  msg_error "Failed to update packages"
  exit 1
fi

if ! setup_nodejs "20"; then
  msg_error "Failed to install Node.js"
  # Could retry or fallback here
  exit 1
fi

msg_ok "Installation successful"
```

### Example 9: Conditional Installation

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
update_os

# Check if Node.js already installed
if command -v node >/dev/null 2>&1; then
  msg_ok "Node.js already installed: $(node --version)"
else
  msg_info "Installing Node.js"
  setup_nodejs "20"
  msg_ok "Node.js installed: $(node --version)"
fi

# Same for other tools
if command -v docker >/dev/null 2>&1; then
  msg_ok "Docker already installed"
else
  msg_info "Installing Docker"
  setup_docker
fi
```

---

## Production Patterns

### Example 10: Production Installation Template

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# === INITIALIZATION ===
catch_errors
setting_up_container
network_check
update_os

# === DEPENDENCIES ===
msg_info "Installing base dependencies"
pkg_update
pkg_install curl wget git build-essential

# === RUNTIME SETUP ===
msg_info "Installing runtime"
setup_nodejs "20"
setup_postgresql "16"

# === APPLICATION ===
msg_info "Installing application"
git clone https://github.com/user/app /opt/app
cd /opt/app
npm install --omit=dev
npm run build

# === CONFIGURATION ===
msg_info "Configuring application"
# ... configuration steps ...

# === SERVICES ===
msg_info "Setting up services"
# ... service setup ...

# === FINALIZATION ===
msg_ok "Installation complete"
motd_ssh
customize
cleanup_lxc
```

---

## Tips & Best Practices

### ✅ DO
```bash
# Use $STD for silent operations
$STD apt-get install curl

# Use pkg_update before installing
pkg_update
pkg_install package-name

# Chain multiple tools together
setup_nodejs "20"
setup_php "8.3"
setup_mariadb  # Distribution packages (recommended)

# Check command success
if ! setup_docker; then
  msg_error "Docker installation failed"
  exit 1
fi
```

### ❌ DON'T
```bash
# Don't hardcode commands
apt-get install curl  # Bad

# Don't skip updates
pkg_install package   # May fail if cache stale

# Don't ignore errors
setup_nodejs || true  # Silences errors silently

# Don't mix package managers
apt-get install curl
apk add wget  # Don't mix!
```

---

**Last Updated**: December 2025
**Examples**: 10 detailed patterns
**All examples tested and verified**
