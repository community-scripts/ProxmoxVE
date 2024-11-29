# Installation Script Conventions

## File Structure
All installation scripts should follow this standard structure:

### 1. File Header
```bash
#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
```

### 2. Initial Setup
Every script should source the functions file and run these initial checks:

```bash
source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os
```

### 3. Standard Dependencies
Common base dependencies should be installed first:

```bash
msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"
```

### 4. File Writing Conventions

#### Writing Config Files
Use heredoc (`cat <<EOF`) for writing configuration files:

```bash
cat <<EOF >/etc/systemd/system/service.service
[Unit]
Description=Service Description
After=network.target

[Service]
Type=simple
ExecStart=/path/to/executable
Restart=always

[Install]
WantedBy=multi-user.target
EOF
```

#### Writing Environment Files
Use heredoc for environment files, with proper quoting:

```bash
cat <<EOF >/path/to/.env
VARIABLE="value"
PORT=3000
DB_NAME="${DB_NAME}"
EOF
```
### 5. Service Management
Standard way to enable and start services:

```bash
systemctl enable -q --now service.service
``` 

### 6. Cleanup Section
Every script should end with cleanup:

```bash
msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
```

### 7. Progress Messages
Use standard message functions for consistent output:

```bash
msg_info "Starting task"
$STD some_command
msg_ok "Task completed"
```

### 8. Version Tracking
When installing specific versions, store the version number:

```bash
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
```

### 9. Credentials Management
Store credentials in a consistent location:

```bash
{
    echo "Application-Credentials"
    echo "Username: $USERNAME"
    echo "Password: $PASSWORD"
} >> ~/application.creds
```

### 10. Directory Structure
Use consistent paths for applications:
- Application files: `/opt/application_name/`
- Configuration files: `/etc/application_name/`
- Data files: `/var/lib/application_name/`

### 11. Error Handling
Use the standard error handling function:

```bash
catch_errors
```

### 12. Final Setup
Every script should end with:

```bash
motd_ssh
customize
```

## Best Practices
1. Use `$STD` for commands that should have their output suppressed
2. Use consistent variable naming (uppercase for global variables)
3. Always quote variables that might contain spaces
4. Use `-q` flag for quiet operation where available
5. Use consistent indentation (2 spaces)
6. Include cleanup sections to remove temporary files and packages
7. Use descriptive message strings in msg_info/msg_ok functions


## Building your own scripts
the best way to build your own scripts is to start with [our template script](https://github.com/community-scripts/ProxmoxVE/blob/main/docs/templates/example-install.sh) and then modify it to your needs.