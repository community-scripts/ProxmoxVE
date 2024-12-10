
# Community Scripts Contribution Guide

## Overview
Welcome to the community-scripts repository! This guide provides detailed instructions on how to contribute to the project, including code structure, best practices, and setup instructions for contributing to our repository.

## Getting Started

Before contributing, please ensure that you have the following setup:

1. **Visual Studio Code** (recommended for script development)
2. **Necessary VS Code Extensions:**
   - [Shell Syntax](https://marketplace.visualstudio.com/items?itemName=bmalehorn.shell-syntax)
   - [ShellCheck](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck)
   - [Shell Format](https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format)

### Important Notes
- Use [AppName.sh](https://github.com/community-scripts/ProxmoxVE/blob/contributor_guide/.github/CONTRIBUTOR_GUIDE/ct/AppName.sh) and [AppName-install.sh](https://github.com/community-scripts/ProxmoxVE/blob/contributor_guide/.github/CONTRIBUTOR_GUIDE/install/AppName-install.sh) as templates when creating new scripts.
- The call to `community-scripts/ProxmoxVE` should be adjusted to reflect the correct fork URL.

---

# 🚀 Structure of Installation Scripts (ct/AppName.sh)

All installation scripts should follow this standard structure:

## 1. 📝 File Header

```bash
#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: [YourUserName]
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: [SOURCE_URL]
```

> **Note**: 
> - Add your username and source URL
> - For existing scripts, add "| Co-Author [YourUserName]" after the current author

## 2. 🔧 App Default Values

```bash
# App Default Values
APP="[APP_NAME]"
TAGS="[TAGS]"
var_cpu="[CPU]"
var_ram="[RAM]"
var_disk="[DISKSIZE]"
var_os="[OS]"
var_version="[VERSION]"
var_unprivileged="[UNPRIVILEGED]"
```

### Value Declarations 📊

| Variable | Description | Notes |
|----------|-------------|-------|
| `APP` | Application name | Must match ct\AppName.sh |
| `TAGS` | Proxmox display tags | Limit the number |
| `var_cpu` | CPU cores | Number of cores |
| `var_ram` | RAM | In MB |
| `var_disk` | Disk capacity | In GB |
| `var_os` | Operating system | alpine, debian, ubuntu |
| `var_version` | OS version | e.g., 3.20, 11, 12, 20.04 |
| `var_unprivileged` | Container type | 1 = Unprivileged, 0 = Privileged |

### Default Values 🔨

- `TAGS="community-script"` (default)
- `var_cpu="1"`
- `var_ram="1024"`
- `var_disk="4"`
- `var_unprivileged="1"`
- `var_verbose="no"`

#### Example 🌟

```bash
# App Default Values
APP="Google"
TAGS="searching;website"
var_cpu="2"
var_ram="4096"
var_disk="10"
var_os="debian"
var_version="12"
var_unprivileged="0"
```

> Creates a privileged LXC named "google" with 2 CPU cores, 4096 MB RAM, 10 GB disk, on Debian 12

## 3. 📋 App Output & Base Settings

```bash
# App Output & Base Settings
header_info "$APP"
base_settings
```

- `header_info`: Generates ASCII header for APP
- `base_settings`: Allows overwriting variable values

## 4. 🛠 Core Functions

```bash
# Core
variables
color
catch_errors
```

- `variables`: Processes input and prepares variables
- `color`: Sets icons, colors, and formatting
- `catch_errors`: Enables error handling

## 5. 🔄 Update-Script Part

```bash
function update_script() {
    header_info
    check_container_storage
    check_container_resources

    # Update-Code
}
```

- `header_info`: Regenerates ASCII AppName
- `check_container_storage`: Checks available storage
- `check_container_resources`: Validates CPU/RAM resources

```bash
# Check if installation is present | -f for file, -d for folder
    if [[ ! -f [INSTALLATION_CHECK_PATH] ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
```

> **Note**: 
> - First you need to check if the APP is installed in the LXC
> - Replace ```INSTALLATION_CHECK_PATH``` with the path to the APP ```i.e. (/opt/app)```

```bash
    # Crawling the new version and checking whether an update is required
    RELEASE=$(curl -fsSL [RELEASE_URL] | [PARSE_RELEASE_COMMAND])
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then

    # Code to update the APP

    else
        msg_ok "No update required. ${APP} is already at v${RELEASE}"
    fi
    exit
```

> **Note**: 
> - Crawl for the newest version. Example for Github Releases:
> - ```RELEASE=$(curl -s https://api.github.com/repos/USER/REPO/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')```
> - Then check if updating is required.

```bash
     # Stopping Services
        msg_info "Stopping $APP"
        systemctl stop [SERVICE_NAME]
        msg_ok "Stopped $APP"

        # Creating Backup
        msg_info "Creating Backup"
        tar -czf "/opt/${APP}_backup_$(date +%F).tar.gz" [IMPORTANT_PATHS]
        msg_ok "Backup Created"

        # Execute Update
        msg_info "Updating $APP to v${RELEASE}"
        [UPDATE_COMMANDS]
        msg_ok "Updated $APP to v${RELEASE}"

        # Starting Services
        msg_info "Starting $APP"
        systemctl start [SERVICE_NAME]
        sleep 2
        msg_ok "Started $APP"

        # Cleaning up
        msg_info "Cleaning Up"
        rm -rf [TEMP_FILES]
        msg_ok "Cleanup Completed"

        # Last Action
        echo "${RELEASE}" >/opt/${APP}_version.txt
        msg_ok "Update Successful"
```

> **Note**: 
> - In the IF-Block you then write the code to update the APP, Start and Stop the Services and clean up any temporary files

## 6. 🏁 Script-End

```bash
start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:[PORT]${CL}"
```

- `start`: Launches Whiptail dialogue
- `build_container`: Collects and integrates user settings
- `description`: Sets LXC container description

---

# 🛠 Structure of Installation Scripts (install/AppName-install.sh)

## 1. 📄 File Header

```bash
#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: [YourUserName]
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
```

> **Notes**: 
> - Add your username
> - For existing scripts, add "| Co-Author [YourUserName]"

## 2. 🔌 Import Functions and Setup

```bash
source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os
```

## 3. 📦 Standard Dependencies

```bash
msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc 
msg_ok "Installed Dependencies"
```

## 4. 📝 File Writing Conventions

### Writing Config Files 🔧

```bash
cat <<EOF >/etc/systemd/system/${APPLICATION}.service
[Unit]
Description=${APPLICATION} Service Description
After=network.target

[Service]
Type=simple
ExecStart=/path/to/executable
Restart=always

[Install]
WantedBy=multi-user.target
EOF
```

### Writing Environment Files 🌍

```bash
cat <<EOF >/path/to/.env
VARIABLE="value"
PORT=3000
DB_NAME="${DB_NAME}"
EOF
```

## 5. 🚦 Service Management

```bash
systemctl enable -q --now service.service
```

## 6. 🧹 Cleanup Section

```bash
msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
```

## 7. 📢 Progress Messages

```bash
msg_info "Setup ${APPLICATION}"
$STD some_command
msg_ok "Setup ${APPLICATION}"
```

## 8. 🏷️ Version Tracking

```bash
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
```

## 9. 🔐 Credentials Management

```bash
USERNAME=username
PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
{
    echo "Application-Credentials"
    echo "Username: $USERNAME"
    echo "Password: $PASSWORD"
} >> ~/application.creds
```
- Use random generated Passwords if possible

## 10. 📂 Directory Structure

- Application files: `/opt/application_name/`
- Configuration files: `/etc/application_name/`
- Data files: `/var/lib/application_name/`

## 11. 🚨 Error Handling

```bash
catch_errors
```

## 12. 🏁 Final Setup

```bash
motd_ssh
customize
```

---

## 📋 Best Practices

1. Use `$STD` for suppressed command output
2. Use uppercase for global variables
3. Quote variables with potential spaces
4. Use `-q` for quiet operations
5. Use 2-space indentation
6. Include cleanup sections
7. Use descriptive message strings

---

## 🚀 Building Your Own Scripts

Start with the [template script](https://github.com/community-scripts/ProxmoxVE/blob/main/docs/templates/example-install.sh)

---

## 🤝 Contribution Process

### 1. Fork the Repository
Fork to your GitHub account

### 2. Clone Your Fork on your Pc 
```bash
git clone https://github.com/yourUserName/ForkName
```

### 3. Create a New Branch
```bash
git switch -c your-feature-branch
```

### 4. Change Paths in build.func and install.func
you need to switch "community-scripts/ProxmoxVE" to "yourUserName/ForkName" 

### 4. Commit Changes (without build.func and install.func!)
```bash
git commit -m "Your commit message"
```

### 5. Push to Your Fork
```bash
git push origin your-feature-branch
```

### 6. Create a Pull Request
Open a PR from your feature branch to the main repository branch

---

## 📚 Pages

- [Function-Overview](https://github.com/community-scripts/ProxmoxVE/wiki/Function_Overview)
- [CT Template: AppName.sh](https://github.com/community-scripts/ProxmoxVE/blob/contributor_guide/.github/CONTRIBUTOR_GUIDE/ct/AppName.sh)
- [Install Template: AppName-install.sh](https://github.com/community-scripts/ProxmoxVE/blob/contributor_guide/.github/CONTRIBUTOR_GUIDE/install/AppName-install.sh)
