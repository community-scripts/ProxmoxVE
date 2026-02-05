# Community Scripts Contribution Guide

## **Welcome to the communty-scripts Repository!**

📜 These documents outline the essential coding standards for all our scripts and JSON files. Adhering to these standards ensures that our codebase remains consistent, readable, and maintainable. By following these guidelines, we can improve collaboration, reduce errors, and enhance the overall quality of our project.

### Why Coding Standards Matter

Coding standards are crucial for several reasons:

1. **Consistency**: Consistent code is easier to read, understand, and maintain. It helps new team members quickly get up to speed and reduces the learning curve.
2. **Readability**: Clear and well-structured code is easier to debug and extend. It allows developers to quickly identify and fix issues.
3. **Maintainability**: Code that follows a standard structure is easier to refactor and update. It ensures that changes can be made with minimal risk of introducing new bugs.
4. **Collaboration**: When everyone follows the same standards, it becomes easier to collaborate on code. It reduces friction and misunderstandings during code reviews and merges.

### Scope of These Documents

These documents cover the coding standards for the following types of files in our project:

- **`install/$AppName-install.sh` Scripts**: These scripts are responsible for the installation of applications.
- **`ct/$AppName.sh` Scripts**: These scripts handle the creation and updating of containers.
- **`json/$AppName.json`**: These files store structured data and are used for the website.

Each section provides detailed guidelines on various aspects of coding, including shebang usage, comments, variable naming, function naming, indentation, error handling, command substitution, quoting, script structure, and logging. Additionally, examples are provided to illustrate the application of these standards.

By following the coding standards outlined in this document, we ensure that our scripts and JSON files are of high quality, making our project more robust and easier to manage. Please refer to this guide whenever you create or update scripts and JSON files to maintain a high standard of code quality across the project. 📚🔍

Let's work together to keep our codebase clean, efficient, and maintainable! 💪🚀

## Getting Started

Before contributing, please ensure that you have the following setup:

1. **Visual Studio Code** (recommended for script development)
2. **Recommended VS Code Extensions:**
   - [Shell Syntax](https://marketplace.visualstudio.com/items?itemName=bmalehorn.shell-syntax)
   - [ShellCheck](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck)
   - [Shell Format](https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format)

### Important Notes

- Use [AppName.sh](https://github.com/community-scripts/ProxmoxVE/blob/main/docs/contribution/templates_ct/AppName.sh) and [AppName-install.sh](https://github.com/community-scripts/ProxmoxVE/blob/main/docs/contribution/templates_install/AppName-install.sh) as templates when creating new scripts.

---

# 🚀 The Application Script (ct/AppName.sh)

- You can find all coding standards, as well as the structure for this file [here](https://github.com/community-scripts/ProxmoxVE/blob/main/docs/contribution/templates_ct/AppName.md).
- These scripts are responsible for container creation, setting the necessary variables and handling the update of the application once installed.

---

# 🛠 The Installation Script (install/AppName-install.sh)

- You can find all coding standards, as well as the structure for this file [here](https://github.com/community-scripts/ProxmoxVE/blob/main/docs/contribution/templates_install/AppName-install.md).
- These scripts are responsible for the installation of the application.

---

## 🚀 Building Your Own Scripts

Start with the [template script](https://github.com/community-scripts/ProxmoxVE/blob/main/docs/contribution/templates_install/AppName-install.sh)

---

## 🤝 Contribution Process

### 1. Fork the repository

Fork to your GitHub account

### 2. Clone your fork on your local environment

```bash
git clone https://github.com/yourUserName/ForkName
```

### 3. Create a new branch

```bash
git switch -c your-feature-branch
```

### 4. Run setup-fork.sh to auto-configure your fork

```bash
bash docs/contribution/setup-fork.sh --full
```

This script automatically:

- Detects your GitHub username
- Updates ALL curl URLs to point to your fork (for testing)
- Creates `.git-setup-info` with your config
- Backs up all modified files (\*.backup)

**IMPORTANT**: This modifies 600+ files! Use cherry-pick when submitting your PR (see below).

### 5. Commit ONLY your new application files

```bash
git commit -m "Your commit message"
```

### 5. Push to your fork

```bash
git push origin your-feature-branch
```

### 6. Cherry-Pick: Submit Only Your Files for PR

⚠️ **IMPORTANT**: setup-fork.sh modified 600+ files. You MUST only submit your 3 new files!

See [README.md - Cherry-Pick Guide](README.md#-cherry-pick-submitting-only-your-changes) for step-by-step instructions.

Quick version:

```bash
# Create clean branch from upstream
git fetch upstream
git checkout -b submit/myapp upstream/main

# Copy only your files
cp ../your-work-branch/ct/myapp.sh ct/myapp.sh
cp ../your-work-branch/install/myapp-install.sh install/myapp-install.sh
cp ../your-work-branch/frontend/public/json/myapp.json frontend/public/json/myapp.json

# Commit and verify
git add ct/myapp.sh install/myapp-install.sh frontend/public/json/myapp.json
git commit -m "feat: add MyApp"
git diff upstream/main --name-only  # Should show ONLY your 3 files

# Push and create PR
git push origin submit/myapp
```

### 7. Create a Pull Request

Open a Pull Request from `submit/myapp` → `community-scripts/ProxmoxVE/main`.

Verify the PR shows ONLY these 3 files:

- `ct/myapp.sh`
- `install/myapp-install.sh`
- `frontend/public/json/myapp.json`

---

# 🛠️ Developer Mode & Debugging

When building or testing scripts, you can use the `dev_mode` variable to enable powerful debugging features. These flags can be combined (comma-separated).

**Usage**:
```bash
# Example: Run with trace and keep the container even if it fails
dev_mode="trace,keep" bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/myapp.sh)"
```

### Available Flags:

| Flag | Description |
| :--- | :--- |
| `trace` | Enables `set -x` for maximum verbosity during execution. |
| `keep` | Prevents the container from being deleted if the build fails. |
| `pause` | Pauses execution at key points (e.g., before customization). |
| `breakpoint` | Allows hardcoded `breakpoint` calls in scripts to drop to a shell. |
| `logs` | Saves detailed build logs to `/var/log/community-scripts/`. |
| `dryrun` | Bypasses actual container creation (limited support). |
| `motd` | Forces an update of the Message of the Day (MOTD). |

---

## 📚 Pages

- [CT Template: AppName.sh](https://github.com/community-scripts/ProxmoxVE/blob/main/docs/contribution/templates_ct/AppName.sh)
- [Install Template: AppName-install.sh](https://github.com/community-scripts/ProxmoxVE/blob/main/docs/contribution/templates_install/AppName-install.sh)
- [JSON Template: AppName.json](https://github.com/community-scripts/ProxmoxVE/blob/main/docs/contribution/templates_json/AppName.json)
