
# **AppName<span></span>-install.sh Scripts**
 `AppName-install.sh` scripts found in the `/install` directory. These scripts are responsible for the installation of the application. For this guide we take `/install/snipeit-install.sh` as example.

## 1. **File header**

### 1.1 **Shebang**
- Use `#!/usr/bin/env bash` as the shebang.

```bash
#!/usr/bin/env bash
```

### 1.2 **Comments**
- Add clear comments for script metadata, including author, copyright, and license information.
- Use meaningful inline comments to explain complex commands or logic.

Example:
```bash
# Copyright (c) 2021-2024 community-scripts ORG
# Author: [YourUserName]
# License: MIT
# Source: [SOURCE_URL]
```
> [!NOTE]: 
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

Example: <br>
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
wget -q "https://github.com/snipe/snipe-it/archive/refs/tags/v${RELEASE}.zip"
```

### 5.2 **Save the version for update checks**
- Write the installed version into a file.
- This is used for the update function in AppName.sh to check for updates

Example:
```bash
echo "${RELEASE}" >"/opt/AppName_version.txt"
```
---

## 6. **Input and output management**

### 6.1 **User feedback**
- Use standard functions like `msg_info` and `msg_ok` to print status messages.
- Display meaningful progress messages at key stages.

Example:
```bash
msg_info "Installing Dependencies"
$STD apt-get install ...
msg_ok "Installed Dependencies"
```
### 6.2 **Verbosity**
- Use the appropiate flag (**-q** in the examples) for a command to suppres its output
Example:
```bash
wget -q
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
