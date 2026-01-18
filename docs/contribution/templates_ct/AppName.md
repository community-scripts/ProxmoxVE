# CT Container Scripts - Quick Reference

> [!WARNING]
> **This is legacy documentation.** Refer to the **modern template** at [templates_ct/AppName.sh](AppName.sh) for best practices.
>
> Current templates use:
>
> - `tools.func` helpers instead of manual patterns
> - `check_for_gh_release` and `fetch_and_deploy_gh_release` from build.func
> - Automatic setup-fork.sh configuration

---

## Before Creating a Script

1. **Fork & Clone:**

   ```bash
   git clone https://github.com/YOUR_USERNAME/ProxmoxVE.git
   cd ProxmoxVE
   ```

2. **Run setup-fork.sh** (updates all curl URLs to your fork):

   ```bash
   bash docs/contribution/setup-fork.sh
   ```

3. **Copy the Modern Template:**

   ```bash
   cp templates_ct/AppName.sh ct/MyApp.sh
   # Edit ct/MyApp.sh with your app details
   ```

4. **Test Your Script (via GitHub):**

   ⚠️ **Important:** You must push to GitHub and test via curl, not `bash ct/MyApp.sh`!

   ```bash
   # Push your changes to your fork first
   git push origin feature/my-awesome-app

   # Then test via curl (this loads from YOUR fork, not local files)
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/MyApp.sh)"
   ```

   > 💡 **Why?** The script's curl commands are modified by setup-fork.sh, but local execution uses local files, not the updated GitHub URLs. Testing via curl ensures your script actually works.
   >
   > ⏱️ **Note:** GitHub sometimes takes 10-30 seconds to update files. If you don't see your changes, wait and try again.

5. **Cherry-Pick for PR** (submit ONLY your 3-4 files):
   - See [Cherry-Pick Guide](../README.md) for step-by-step git commands

---

## Template Structure

The modern template includes:

### Header

```bash
#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# (Note: setup-fork.sh changes this URL to point to YOUR fork during development)
```

### Metadata

```bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: YourUsername
# License: MIT
APP="MyApp"
var_tags="app-category;foss"
var_cpu="2"
var_ram="2048"
var_disk="4"
var_os="alpine"
var_version="3.20"
var_unprivileged="1"
```

### Core Setup

```bash
header_info "$APP"
variables
color
catch_errors
```

### Update Function

The modern template provides a standard update pattern:

```bash
function update_script() {
  header_info
  check_container_storage
  check_container_resources

  # Use tools.func helpers:
  check_for_gh_release "myapp" "owner/repo"
  fetch_and_deploy_gh_release "myapp" "owner/repo" "tarball" "latest" "/opt/myapp"
}
```

---

## Key Patterns

### Check for Updates (App Repository)

Use `check_for_gh_release` with the **app repo**:

```bash
check_for_gh_release "myapp" "owner/repo"
```

### Deploy External App

Use `fetch_and_deploy_gh_release` with the **app repo**:

```bash
fetch_and_deploy_gh_release "myapp" "owner/repo"
```

### Avoid Manual Version Checking

❌ OLD (manual):

```bash
RELEASE=$(curl -fsSL https://api.github.com/repos/myapp/myapp/releases/latest | grep tag_name)
```

✅ NEW (use tools.func):

```bash
fetch_and_deploy_gh_release "myapp" "owner/repo"
```

---

## Best Practices

1. **Use tools.func helpers** - Don't manually curl for versions
2. **Only add app-specific dependencies** - Don't add ca-certificates, curl, gnupg (handled by build.func)
3. **Test via curl from your fork** - Push first, then: `bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/MyApp.sh)"`
4. **Wait for GitHub to update** - Takes 10-30 seconds after git push
5. **Cherry-pick only YOUR files** - Submit only ct/MyApp.sh, install/MyApp-install.sh, frontend/public/json/myapp.json (3 files)
6. **Verify before PR** - Run `git diff upstream/main --name-only` to confirm only your files changed

---

## Common Update Patterns

See the [modern template](AppName.sh) and [AI.md](../AI.md) for complete working examples.

Recent reference scripts with good update functions:

- [Trip](https://github.com/community-scripts/ProxmoxVE/blob/main/ct/trip.sh)
- [Thingsboard](https://github.com/community-scripts/ProxmoxVE/blob/main/ct/thingsboard.sh)
- [UniFi](https://github.com/community-scripts/ProxmoxVE/blob/main/ct/unifi.sh)

---

## Need Help?

- **[README.md](../README.md)** - Full contribution workflow
- **[AI.md](../AI.md)** - AI-generated script guidelines
- **[FORK_SETUP.md](../FORK_SETUP.md)** - Why setup-fork.sh is important
- **[Slack Community](https://discord.gg/your-link)** - Ask questions

````

### 3.4 **Verbosity**

- Use the appropriate flag (**-q** in the examples) for a command to suppress its output.
  Example:

```bash
curl -fsSL
unzip -q
````

- If a command does not come with this functionality use `$STD` to suppress it's output.

Example:

```bash
$STD php artisan migrate --force
$STD php artisan config:clear
```

### 3.5 **Backups**

- Backup user data if necessary.
- Move all user data back in the directory when the update is finished.

> [!NOTE]
> This is not meant to be a permanent backup

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

- In case you can not provide an update function use the following code to provide user feedback.

```bash
function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/snipeit ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_error "Currently we don't provide an update function for this ${APP}."
    exit
}
```

---

## 4 **End of the script**

- `start`: Launches Whiptail dialogue
- `build_container`: Collects and integrates user settings
- `description`: Sets LXC container description
- With `echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"` you can point the user to the IP:PORT/folder needed to access the app.

```bash
start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
```

---

## 5. **Contribution checklist**

- [ ] Shebang is correctly set (`#!/usr/bin/env bash`).
- [ ] Correct link to _build.func_
- [ ] Metadata (author, license) is included at the top.
- [ ] Variables follow naming conventions.
- [ ] Update function exists.
- [ ] Update functions checks if app is installed and for new version.
- [ ] Update function cleans up temporary files.
- [ ] Script ends with a helpful message for the user to reach the application.
