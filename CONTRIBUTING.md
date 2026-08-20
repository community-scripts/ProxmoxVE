# Contributing to Proxmox VE Helper-Scripts

Welcome! We're glad you want to contribute. This guide covers everything you need to add new scripts, improve existing ones, or help in other ways.

For detailed coding standards and full documentation, visit **[community-scripts.org/docs](https://community-scripts.org/docs)**.

---

## How Can I Help?

> [!IMPORTANT]
> **New scripts** must always be submitted to [ProxmoxVED](https://github.com/community-scripts/ProxmoxVED) first — not to this repository.
> PRs with new scripts opened directly against ProxmoxVE **will be closed without review**.
> **Bug fixes, improvements, and features for existing scripts** go here (ProxmoxVE).

| I want to…                                  | Where to go                                                                                  |
| :------------------------------------------ | :------------------------------------------------------------------------------------------- |
| **Add a brand-new script**                  | [ProxmoxVED](https://github.com/community-scripts/ProxmoxVED) — testing repo for new scripts |
| **Fix a bug or improve an existing script** | This repo (ProxmoxVE) — open a PR here                                                       |
| **Add a feature to an existing script**     | This repo (ProxmoxVE) — open a PR here                                                       |
| Report a bug or broken script               | [Open an Issue](https://github.com/community-scripts/ProxmoxVE/issues)                       |
| Request a new script or feature             | [Start a Discussion](https://github.com/community-scripts/ProxmoxVE/discussions)             |
| Report a security vulnerability             | [Security Policy](SECURITY.md)                                                               |
| Chat with contributors                      | [Discord](https://discord.gg/3AnUqsXnmK)                                                     |

---

## Prerequisites

Before writing scripts, we recommend setting up:

- **Visual Studio Code** with these extensions:
  - [Shell Syntax](https://marketplace.visualstudio.com/items?itemName=bmalehorn.shell-syntax)
  - [ShellCheck](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck)
  - [Shell Format](https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format)

---

## Script Structure

Every script consists of two files:

| File                         | Purpose                                                 |
| :--------------------------- | :------------------------------------------------------ |
| `ct/AppName.sh`              | Container creation, variable setup, and update handling |
| `install/AppName-install.sh` | Application installation logic                          |

Use existing scripts in [`ct/`](ct/) and [`install/`](install/) as reference. Full coding standards and annotated templates are at **[community-scripts.org/docs/contribution](https://community-scripts.org/docs/contribution)**.

---

## Contribution Process

### Adding a new script

New scripts are **not accepted directly in this repository**. The workflow is:

1. Fork [ProxmoxVED](https://github.com/community-scripts/ProxmoxVED) and clone it
2. Create a branch: `git switch -c feat/myapp`
3. Write your two script files:
   - `ct/myapp.sh`
   - `install/myapp-install.sh`
4. Test thoroughly in ProxmoxVED — run the script against a real Proxmox instance
5. Open a PR in **ProxmoxVED** for review and testing
6. Once accepted and verified there, the script will be promoted to ProxmoxVE by maintainers

Follow the coding standards at [community-scripts.org/docs/contribution](https://community-scripts.org/docs/contribution).

---

### Fixing a bug or improving an existing script

Changes to scripts that already exist in ProxmoxVE go directly here:

1. Fork **this repository** (ProxmoxVE) and clone it:

   ```bash
   git clone https://github.com/YOUR_USERNAME/ProxmoxVE
   cd ProxmoxVE
   ```

2. Create a branch:

   ```bash
   git switch -c fix/myapp-description
   ```

3. Make your changes to the relevant files in `ct/` and/or `install/`

4. Open a PR from your fork to `community-scripts/ProxmoxVE/main`

Your PR should only contain the files you changed. Do not include unrelated modifications.

---

## Code Standards

Key rules at a glance:

- One script per service — keep them focused
- Naming convention: lowercase, hyphen-separated (`my-app.sh`)
- Shebang: `#!/usr/bin/env bash`
- Quote all variables: `"$VAR"` not `$VAR`
- Use lowercase variable names
- Do not hardcode credentials or sensitive values
- Never prompt without an escape hatch — see below

### Answering a prompt up front

An install script that only asks cannot be deployed unattended. Read the
variable first and prompt only when it is unset:

```bash
if [[ -z "${var_admin_user:-}" ]]; then
  read -r -p "${TAB3}Admin username: " var_admin_user
fi
var_admin_user="${var_admin_user:-admin}"
```

Name them `var_<something>`, the same namespace the container variables use.
`install/forgejo-runner-install.sh`, `install/pangolin-install.sh`, and `install/docker-install.sh` all
follow this.

The variable also has to be exported from `ct/<app>.sh`, or it never reaches
the container — `lxc-attach` carries the caller's environment, but only for
what was actually exported:

```bash
export var_admin_user="${var_admin_user:-}"
```

Declare them on the script's PocketBase record in `app_vars` so the website's
generator can offer them as fields:

```json
"app_vars": [
  {
    "name": "var_admin_user",
    "label": "Admin Username",
    "type": "text",
    "default": "admin"
  },
  {
    "name": "var_admin_pass",
    "label": "Admin Password",
    "type": "password",
    "secret": true
  }
]
```

`type` is one of `text`, `password`, `number`, `boolean` (`yes`/`no`) or
`select` (with `options`). Mark anything credential-like `secret` — the
generator keeps those out of shareable links and out of the on-screen summary.

Full standards and examples: **[community-scripts.org/docs/contribution](https://community-scripts.org/docs/contribution)**

---

## Developer Mode & Debugging

Set the `dev_mode` variable to enable debugging features when testing. Flags can be combined (comma-separated):

```bash
dev_mode="trace,keep" bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/myapp.sh)"
```

| Flag         | Description                                                  |
| :----------- | :----------------------------------------------------------- |
| `trace`      | Enables `set -x` for maximum verbosity during execution      |
| `keep`       | Prevents the container from being deleted if the build fails |
| `pause`      | Pauses execution at key points before customization          |
| `breakpoint` | Drops to a shell at hardcoded `breakpoint` calls in scripts  |
| `logs`       | Saves detailed build logs to `/var/log/community-scripts/`   |
| `motd`       | Forces an update of the Message of the Day                   |
| `net`        | Logs every engine fetch: HTTP status, duration and URL       |
| `timing`     | Times each step and lists the slowest ones at the end        |

Any flag also prints the resolved context first — where the engine came from,
both roots and URLs, the app, platform and versions — and repaints the greens
red, so a dev run is never mistaken for a normal install.

Setting `dev_mode` without naming a flag (`dev_mode=`, `=1`, `=ask`) opens a
picker before the install menu.

`dryrun` was removed: it only intercepted the `silent()` wrapper, so `pct
create` still ran and the container was still built.

---

## Notes

- **Website metadata** (name, description, logo, tags) is managed via the website — use the "Report Issue" link on any script page to request changes. Do not submit metadata changes via repo files.
- **JSON files** in `json/` define script properties used by the website. See existing files for structure reference.
- Keep PRs small and focused. One fix or feature per PR is ideal.
- PRs with **new scripts** opened against ProxmoxVE will be closed — submit them to [ProxmoxVED](https://github.com/community-scripts/ProxmoxVED) instead.
- PRs that fail CI checks will not be merged.
