# 🧪 Code Audit: LXC Script Flow

This guide explains the current execution flow and what to verify during reviews.

## Execution Flow (CT + Install)

1. `ct/appname.sh` runs on the Proxmox host and sources `misc/build.func`.
2. `build.func` orchestrates prompts, container creation, and invokes the install script.
3. Inside the container, `misc/install.func` exposes helper functions via `$FUNCTIONS_FILE_PATH`.
4. `install/appname-install.sh` performs the application install.
5. The CT script prints the completion message.

## Audit Checklist

### CT Script (ct/)

- Sources `misc/build.func` from `community-scripts/ProxmoxVE/main` (setup-fork.sh updates for forks).
- Uses `check_for_gh_release` + `fetch_and_deploy_gh_release` for updates.
- No Docker-based installs.

### Install Script (install/)

- Sources `$FUNCTIONS_FILE_PATH`.
- Uses `tools.func` helpers (setup\_\*).
- Ends with `motd_ssh`, `customize`, `cleanup_lxc`.

### JSON Metadata

- File in `frontend/public/json/<appname>.json` matches template schema.

### Testing

- Test via curl from your fork (CT script only).
- Wait 10-30 seconds after push.

## References

- `docs/contribution/templates_ct/AppName.sh`
- `docs/contribution/templates_install/AppName-install.sh`
- `docs/contribution/templates_json/AppName.json`
- `docs/contribution/GUIDE.md`
