# **AppName<span></span>.sh Scripts**
 `AppName.sh` scripts found in the `/ct` directory. These scripts are responsible for the installation of the desired Application. For this guide we take `/ct/snipeit.sh` as example.


## 1. **File Header**

### 1.1 **Shebang**
- Use `#!/usr/bin/env bash` as the shebang.

```bash
#!/usr/bin/env bash
```
### 1.2 **Import Functions**
- Import the build.func File.
- When developing your own Script, change the link to your own repository.

> [!CAUTION]
> Before opening a Pull Request, change the link to point to the community-scripts repo.

Example for development:
```bash
source <(curl -s https://raw.githubusercontent.com/[USER]/[REPO]/refs/heads/[BRANCH]/misc/build.func)
```

Example for final Script: 
```bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
```

### 1.3 **Metadata**
- Add clear comments for script metadata, including author, copyright, and license information.

Example:
```bash
# Copyright (c) 2021-2024 community-scripts ORG
# Author: [YourUserName]
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: [SOURCE_URL]
```

> [!NOTE]: 
> - Add your username and source URL
> - For existing scripts, add "| Co-Author [YourUserName]" after the current author

---

## 2 **Variables and Function import**
> [!NOTE]
> You need to have all this set in your Script, otherwise it will not work!

### 2.1 **Default Values**
- This sections sets the Default Values for the Container.
- `APP` needs to be set to the Application name and must represent the filenames of your scripts.
- `var_tags`: You can set Tags for the CT wich show up in the Proxmox UI. Don´t overdo it! 

>[!NOTE]
>Description for all Default Values
>| Variable | Description | Notes |
>|----------|-------------|-------|
>| `APP` | Application name | Must match ct\AppName.sh |
>| `TAGS` | Proxmox display tags without Spaces, only ; | Limit the number |  
>| `var_cpu` | CPU cores | Number of cores |
>| `var_ram` | RAM | In MB |
>| `var_disk` | Disk capacity | In GB |
>| `var_os` | Operating system | alpine, debian, ubuntu |
>| `var_version` | OS version | e.g., 3.20, 11, 12, 20.04 |
>| `var_unprivileged` | Container type | 1 = Unprivileged, 0 = Privileged |

Example:
```bash
APP="SnipeIT"
var_tags="asset-management;foss"
var_cpu="2"
var_ram="2048"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"
```

## 2.2 **📋 App Output & Base Settings**

```bash
# App Output & Base Settings
header_info "$APP"
base_settings
```

- `header_info`: Generates ASCII header for APP
- `base_settings`: Allows overwriting variable values

## 2.3 **🛠 Core Functions**

```bash
# Core
variables
color
catch_errors
```

- `variables`: Processes input and prepares variables
- `color`: Sets icons, colors, and formatting
- `catch_errors`: Enables error handling

---

## 3 **Update Function**

### 3.1 **Function Header**
- If applicable write a function wich updates the Application and the OS in the container.
- Each update function starts with a standardised Header:
```bash
function update_script() {
  header_info
  check_container_storage
  check_container_resources
```

### 3.2 **Check APP**
- Befor doing anything updatewise, check if the App is installed in the Container.

Example:
```bash
if [[ ! -d /opt/snipe-it ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
```
### 3.3 **Check Version**
- Befor updating, check if a new Version exists. 
- For this we use the `${APPLICATION}_version.txt` file created in `/opt` during the install.

Example with a Github Release:
```bash
 RELEASE=$(curl -fsSL https://api.github.com/repos/snipe/snipe-it/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Updating ${APP} to v${RELEASE}"
    #DO UPDATE
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}."
  fi
  exit
}
```
### 3.4 **Verbosity**
- Use the appropiate flag (**-q** in the examples) for a command to suppres its output.
Example:
```bash
wget -q
unzip -q
```
- If a command dose not come with such a functionality use `&>/dev/null` to suppress its output.

Example:
```bash
php artisan migrate --force &>/dev/null
php artisan config:clear &>/dev/null
```

### 3.5 **Backups**
- Backup userdata if nessesary.
- Move all userdata back in the Directory when the update is finnished.
>[!NOTE]
>This is not meant to be a permantent backup

Example backup:
```bash
  mv /opt/snipe-it /opt/snipe-it-backup
```
Example config restore:
```bash
  cp /opt/snipe-it-backup/.env /opt/snipe-it/.env
  cp -r /opt/snipe-it-backup/public/uploads/ /opt/snipe-it/public/uploads/
  cp -r /opt/snipe-it-backup/storage/private_uploads /opt/snipe-it/storage/private_uploads
```

### 3.6 **Cleanup**
- Do not forget to remove any temporary files/folders such as zip-files or temporary backups.
Example:
```bash
  rm -rf /opt/v${RELEASE}.zip
  rm -rf /opt/snipe-it-backup
```

### 3.7 **No update function**
- In case you can not provide a update function use the following code to provide user feedback.
```bash
function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/snipeit ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_error "Ther is currently no automatic update function for ${APP}."
    exit
}
```

---

## 4 **End of the Script**
- `start`: Launches Whiptail dialogue
- `build_container`: Collects and integrates user settings
- `description`: Sets LXC container description
- With `echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"` you can point the user to the IP:PORT/folder needed to access the App.

```bash
start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
```
---

## 5. **Best Practices Checklist**

- [ ] Shebang is correctly set (`#!/usr/bin/env bash`).
- [ ] Correct link to *build.func*
- [ ] Metadata (author, license) is included at the top.
- [ ] Variables follow naming conventions.
- [ ] Update function exists.
- [ ] Update functions checks if App is installed an for new Version.
- [ ] Update function up temporary files.
- [ ] Script ends with a helpfull message for the User to reach the App.

