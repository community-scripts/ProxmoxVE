# Install Scripts - Quick Reference

> [!WARNING]
> **This is legacy documentation.** Refer to the **modern template** at [templates_install/AppName-install.sh](AppName-install.sh) for best practices.
>
> Current templates use:
>
> - `tools.func` helpers (setup_nodejs, setup_uv, setup_postgresql_db, etc.)
> - Automatic dependency installation via build.func
> - Standardized environment variable patterns

---

## Before Creating a Script

1. **Copy the Modern Template:**

   ```bash
   cp templates_install/AppName-install.sh install/MyApp-install.sh
   # Edit install/MyApp-install.sh
   ```

2. **Key Pattern:**
   - CT scripts source build.func and call the install script
   - Install scripts use sourced FUNCTIONS_FILE_PATH (via build.func)
   - Both scripts work together in the container

3. **Test via GitHub:**

   ```bash
   # Push your changes to your fork first
   git push origin feature/my-awesome-app

   # Test the CT script via curl (it will call the install script)
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/MyApp.sh)"
   # ⏱️ Wait 10-30 seconds after pushing - GitHub takes time to update
   ```

---

## Template Structure

### Header

```bash
#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/install.func)
# (setup-fork.sh modifies this URL to point to YOUR fork during development)
```

### Dependencies (App-Specific Only)

```bash
# Don't add: ca-certificates, curl, gnupg, wget, git, jq
# These are handled by build.func
msg_info "Installing dependencies"
$STD apt-get install -y app-specific-deps
msg_ok "Installed dependencies"
```

### Runtime Setup

Use tools.func helpers instead of manual installation:

```bash
# ✅ NEW (use tools.func):
NODE_VERSION="20"
setup_nodejs
# OR
PYTHON_VERSION="3.12"
setup_uv
# OR
PG_DB_NAME="myapp_db"
PG_DB_USER="myapp"
setup_postgresql_db
```

### Service Configuration

```bash
# Create .env file
msg_info "Configuring MyApp"
cat << EOF > /opt/myapp/.env
DEBUG=false
PORT=8080
DATABASE_URL=postgresql://...
EOF
msg_ok "Configuration complete"

# Create systemd service
msg_info "Creating systemd service"
cat << EOF > /etc/systemd/system/myapp.service
[Unit]
Description=MyApp
[Service]
ExecStart=/usr/bin/node /opt/myapp/app.js
[Install]
WantedBy=multi-user.target
EOF
msg_ok "Service created"
```

### Finalization

```bash
msg_info "Finalizing MyApp installation"
systemctl enable --now myapp
motd_ssh
customize
msg_ok "MyApp installation complete"
cleanup_lxc
```

---

## Key Patterns

### Avoid Manual Version Checking

❌ OLD (manual):

```bash
RELEASE=$(curl -fsSL https://api.github.com/repos/app/repo/releases/latest | grep tag_name)
wget https://github.com/app/repo/releases/download/$RELEASE/app.tar.gz
```

✅ NEW (use tools.func via CT script's fetch_and_deploy_gh_release):

```bash
# In CT script, not install script:
fetch_and_deploy_gh_release "myapp" "app/repo" "app.tar.gz" "latest" "/opt/myapp"
```

### Database Setup

```bash
# Use setup_postgresql_db, setup_mysql_db, etc.
PG_DB_NAME="myapp"
PG_DB_USER="myapp"
setup_postgresql_db
```

### Node.js Setup

```bash
NODE_VERSION="20"
setup_nodejs
npm install --no-save
```

---

## Best Practices

1. **Only add app-specific dependencies**
   - Don't add: ca-certificates, curl, gnupg, wget, git, jq
   - These are handled by build.func

2. **Use tools.func helpers**
   - setup_nodejs, setup_python, setup_uv, setup_postgresql_db, setup_mysql_db, etc.

3. **Don't do version checks in install script**
   - Version checking happens in CT script's update_script()
   - Install script just installs the latest

4. **Structure:**
   - Dependencies
   - Runtime setup (tools.func)
   - Deployment (fetch from CT script)
   - Configuration files
   - Systemd service
   - Finalization

---

## Reference Scripts

See working examples:

- [Trip](https://github.com/community-scripts/ProxmoxVE/blob/main/install/trip-install.sh)
- [Thingsboard](https://github.com/community-scripts/ProxmoxVE/blob/main/install/thingsboard-install.sh)
- [UniFi](https://github.com/community-scripts/ProxmoxVE/blob/main/install/unifi-install.sh)

---

## Need Help?

- **[Modern Template](AppName-install.sh)** - Start here
- **[CT Template](../templates_ct/AppName.sh)** - How CT scripts work
- **[README.md](../README.md)** - Full contribution workflow
- **[AI.md](../AI.md)** - AI-generated script guidelines

### 1.2 **Comments**

- Add clear comments for script metadata, including author, copyright, and license information.
- Use meaningful inline comments to explain complex commands or logic.

Example:

```bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: [YourUserName]
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: [SOURCE_URL]
```

> [!NOTE]:
>
> - Add your username
> - When updating/reworking scripts, add "| Co-Author [YourUserName]"

### 1.3 **Variables and function import**

- This sections adds the support for all needed functions and variables.

```bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os
```

---

## 2. **Variable naming and management**

### 2.1 **Naming conventions**

- Use uppercase names for constants and environment variables.
- Use lowercase names for local script variables.

Example:

```bash
DB_NAME=snipeit_db    # Environment-like variable (constant)
db_user="snipeit"     # Local variable
```

---

## 3. **Dependencies**

### 3.1 **Install all at once**

- Install all dependencies with a single command if possible

Example:

```bash
$STD apt-get install -y \
  curl \
  composer \
  git \
  sudo \
  mc \
  nginx
```

### 3.2 **Collapse dependencies**

Collapse dependencies to keep the code readable.

Example:
Use

```bash
php8.2-{bcmath,common,ctype}
```

instead of

```bash
php8.2-bcmath php8.2-common php8.2-ctype
```

---

## 4. **Paths to application files**

If possible install the app and all necessary files in `/opt/`

---

## 5. **Version management**

### 5.1 **Install the latest release**

- Always try and install the latest release
- Do not hardcode any version if not absolutely necessary

Example for a git release:

```bash
RELEASE=$(curl -fsSL https://api.github.com/repos/snipe/snipe-it/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/snipe/snipe-it/archive/refs/tags/v${RELEASE}.zip"
```

### 5.2 **Save the version for update checks**

- Write the installed version into a file.
- This is used for the update function in **AppName.sh** to check for if a Update is needed.

Example:

```bash
echo "${RELEASE}" >"/opt/AppName_version.txt"
```

---

## 6. **Input and output management**

### 6.1 **User feedback**

- Use standard functions like `msg_info`, `msg_ok` or `msg_error` to print status messages.
- Each `msg_info` must be followed with a `msg_ok` before any other output is made.
- Display meaningful progress messages at key stages.

Example:

```bash
msg_info "Installing Dependencies"
$STD apt-get install -y ...
msg_ok "Installed Dependencies"
```

### 6.2 **Verbosity**

- Use the appropiate flag (**-q** in the examples) for a command to suppres its output
  Example:

```bash
curl -fsSL
unzip -q
```

- If a command dose not come with such a functionality use `$STD` (a custom standard redirection variable) for managing output verbosity.

Example:

```bash
$STD apt-get install -y nginx
```

---

## 7. **String/File Manipulation**

### 7.1 **File Manipulation**

- Use `sed` to replace placeholder values in configuration files.

Example:

```bash
sed -i -e "s|^DB_DATABASE=.*|DB_DATABASE=$DB_NAME|" \
       -e "s|^DB_USERNAME=.*|DB_USERNAME=$DB_USER|" \
       -e "s|^DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|" .env
```

---

## 8. **Security practices**

### 8.1 **Password generation**

- Use `openssl` to generate random passwords.
- Use only alphanumeric values to not introduce unknown behaviour.

Example:

```bash
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
```

### 8.2 **File permissions**

Explicitly set secure ownership and permissions for sensitive files.

Example:

```bash
chown -R www-data: /opt/snipe-it
chmod -R 755 /opt/snipe-it
```

---

## 9. **Service Configuration**

### 9.1 **Configuration files**

Use `cat <<EOF` to write configuration files in a clean and readable way.

Example:

```bash
cat <<EOF >/etc/nginx/conf.d/snipeit.conf
server {
    listen 80;
    root /opt/snipe-it/public;
    index index.php;
}
EOF
```

### 9.2 **Credential management**

Store the generated credentials in a file.

Example:

```bash
USERNAME=username
PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
{
    echo "Application-Credentials"
    echo "Username: $USERNAME"
    echo "Password: $PASSWORD"
} >> ~/application.creds
```

### 9.3 **Enviroment files**

Use `cat <<EOF` to write enviromental files in a clean and readable way.

Example:

```bash
cat <<EOF >/path/to/.env
VARIABLE="value"
PORT=3000
DB_NAME="${DB_NAME}"
EOF
```

### 9.4 **Services**

Enable affected services after configuration changes and start them right away.

Example:

```bash
systemctl enable -q --now nginx
```

---

## 10. **Cleanup**

### 10.1 **Remove temporary files**

Remove temporary files and downloads after use.

Example:

```bash
rm -rf /opt/v${RELEASE}.zip
```

### 10.2 **Autoremove and autoclean**

Remove unused dependencies to reduce disk space usage.

Example:

```bash
apt-get -y autoremove
apt-get -y autoclean
```

---

## 11. **Best Practices Checklist**

- [ ] Shebang is correctly set (`#!/usr/bin/env bash`).
- [ ] Metadata (author, license) is included at the top.
- [ ] Variables follow naming conventions.
- [ ] Sensitive values are dynamically generated.
- [ ] Files and services have proper permissions.
- [ ] Script cleans up temporary files.

---

### Example: High-Level Script Flow

1. Dependencies installation
2. Database setup
3. Download and configure application
4. Service configuration
5. Final cleanup
