# Contributing to Proxmox VE Helper-Scripts

Welcome! We're glad you want to contribute. This guide covers everything you need to add new scripts, improve existing ones, or help in other ways.

For detailed coding standards and full documentation, visit **[community-scripts.org/docs](https://community-scripts.org/docs)**.

---

## How Can I Help?

| I want to… | Go here |
| :--- | :--- |
| Add a new script or improve an existing one | Read this guide, then open a PR |
| Report a bug or broken script | [Open an Issue](https://github.com/community-scripts/ProxmoxVE/issues) |
| Request a new script or feature | [Start a Discussion](https://github.com/community-scripts/ProxmoxVE/discussions) |
| Chat with contributors | [Discord](https://discord.gg/3AnUqsXnmK) |

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

| File | Purpose |
| :--- | :--- |
| `ct/AppName.sh` | Container creation, variable setup, and update handling |
| `install/AppName-install.sh` | Application installation logic |

Use existing scripts in [`ct/`](ct/) and [`install/`](install/) as reference. Full coding standards and annotated templates are at **[community-scripts.org/docs/contribution](https://community-scripts.org/docs/contribution)**.

---

## Contribution Process

### 1. Fork and clone

Fork the repository to your GitHub account, then clone it:

```bash
git clone https://github.com/YOUR_USERNAME/ProxmoxVE
cd ProxmoxVE
```

### 2. Create a branch

```bash
git switch -c feat/myapp
```

### 3. Write your scripts

Create the two required files for your service:

- `ct/myapp.sh`
- `install/myapp-install.sh`

Follow the coding standards at [community-scripts.org/docs/contribution](https://community-scripts.org/docs/contribution).

### 4. Test in ProxmoxVED

**Do not open a PR against the main repo without testing first.**

Submit your scripts to [ProxmoxVED](https://github.com/community-scripts/ProxmoxVED) — the dedicated testing repository. PRs to the main repo without prior testing in ProxmoxVED will not be merged quickly.

### 5. Open a Pull Request

Once testing is complete, open a PR from your fork to `community-scripts/ProxmoxVE/main`.

Your PR should only contain the files you created or modified. Do not include unrelated changes.

---

## Code Standards

Key rules at a glance:

- One script per service — keep them focused
- Naming convention: lowercase, hyphen-separated (`my-app.sh`)
- Shebang: `#!/usr/bin/env bash`
- Quote all variables: `"$VAR"` not `$VAR`
- Use lowercase variable names
- Do not hardcode credentials or sensitive values

Full standards and examples: **[community-scripts.org/docs/contribution](https://community-scripts.org/docs/contribution)**

---

## Developer Mode & Debugging

Set the `dev_mode` variable to enable debugging features when testing. Flags can be combined (comma-separated):

```bash
dev_mode="trace,keep" bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/myapp.sh)"
```

| Flag | Description |
| :--- | :--- |
| `trace` | Enables `set -x` for maximum verbosity during execution |
| `keep` | Prevents the container from being deleted if the build fails |
| `pause` | Pauses execution at key points before customization |
| `breakpoint` | Drops to a shell at hardcoded `breakpoint` calls in scripts |
| `logs` | Saves detailed build logs to `/var/log/community-scripts/` |
| `dryrun` | Bypasses actual container creation (limited support) |
| `motd` | Forces an update of the Message of the Day |

---

## Notes

- **Website metadata** (name, description, logo, tags) is managed via the website — use the "Report Issue" link on any script page to request changes. Do not submit metadata changes via repo files.
- **JSON files** in `json/` define script properties used by the website. See existing files for structure reference.
- Keep PRs small and focused. One script addition or fix per PR is ideal.
- PRs that fail CI checks or that haven't been tested in ProxmoxVED will not be merged.

