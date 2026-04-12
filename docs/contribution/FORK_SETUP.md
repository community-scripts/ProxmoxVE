# 🍴 Fork Setup Guide

**Just forked ProxmoxVE? Run this first!**

## Quick Start

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/ProxmoxVE.git
cd ProxmoxVE

# Run setup script (auto-detects your username from git)
bash docs/contribution/setup-fork.sh --full
```

That's it! ✅

---

## What Does It Do?

The `setup-fork.sh` script automatically:

1. **Detects** your GitHub username from git config
2. **Updates ALL hardcoded links** to point to your fork:
   - Documentation links pointing to `community-scripts/ProxmoxVE`
   - **Curl download URLs** in scripts (e.g., `curl ... github.com/community-scripts/ProxmoxVE/main/...`)
3. **Creates** `.git-setup-info` with your configuration details
4. **Backs up** all modified files (\*.backup for safety)

### Why Updating Curl Links Matters

Your scripts contain `curl` commands that download dependencies from GitHub (build.func, tools.func, etc.):

```bash
# First line of ct/myapp.sh
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
```

**WITHOUT setup-fork.sh:**

- Script URLs still point to `community-scripts/ProxmoxVE/main`
- If you test locally with `bash ct/myapp.sh`, you're testing local files, but the script's curl commands would download from **upstream** repo
- Your modifications aren't actually being tested via the curl commands! ❌

**AFTER setup-fork.sh:**

- Script URLs are updated to `YourUsername/ProxmoxVE/main`
- When you test via curl from GitHub: `bash -c "$(curl ... YOUR_USERNAME/ProxmoxVE/main/ct/myapp.sh)"`, it downloads from **your fork**
- The script's curl commands also point to your fork, so you're actually testing your changes! ✅
- ⏱️ **Important:** GitHub takes 10-30 seconds to recognize pushed files - wait before testing!

```bash
# Example: What setup-fork.sh changes

# BEFORE (points to upstream):
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# AFTER (points to your fork):
source <(curl -fsSL https://raw.githubusercontent.com/john/ProxmoxVE/main/misc/build.func)
```

---

## Usage

### Auto-Detect (Recommended)

```bash
bash docs/contribution/setup-fork.sh --full
```

Automatically reads your GitHub username from `git remote origin url`

### Specify Username

```bash
bash docs/contribution/setup-fork.sh --full john
```

Updates links to `github.com/john/ProxmoxVE`

### Custom Repository Name

```bash
bash docs/contribution/setup-fork.sh --full john my-fork
```

Updates links to `github.com/john/my-fork`

---

## What Gets Updated?

The script updates hardcoded links in these areas when using `--full`:

- `ct/`, `install/`, `vm/` scripts
- `misc/` function libraries
- `docs/` (including `docs/contribution/`)
- Code examples in documentation

---

## After Setup

1. **Review changes**

   ```bash
   git diff docs/
   ```

2. **Read git workflow tips**

   ```bash
   cat .git-setup-info
   ```

3. **Start contributing**

   ```bash
   git checkout -b feature/my-app
   # Make your changes...
   git commit -m "feat: add my awesome app"
   ```

4. **Follow the guide**
   ```bash
   cat docs/contribution/GUIDE.md
   ```

---

## Common Workflows

### Keep Your Fork Updated

```bash
# Add upstream if you haven't already
git remote add upstream https://github.com/community-scripts/ProxmoxVE.git

# Get latest from upstream
git fetch upstream
git rebase upstream/main
git push origin main
```

### Create a Feature Branch

```bash
git checkout -b feature/docker-improvements
# Make changes...
git push origin feature/docker-improvements
# Then create PR on GitHub
```

### Sync Before Contributing

```bash
git fetch upstream
git rebase upstream/main
git push -f origin main  # Update your fork's main
git checkout -b feature/my-feature
```

---

## Troubleshooting

### "Git is not installed" or "not a git repository"

```bash
# Make sure you cloned the repo first
git clone https://github.com/YOUR_USERNAME/ProxmoxVE.git
cd ProxmoxVE
bash docs/contribution/setup-fork.sh --full
```

### "Could not auto-detect GitHub username"

```bash
# Your git origin URL isn't set up correctly
git remote -v
# Should show your fork URL, not community-scripts

# Fix it:
git remote set-url origin https://github.com/YOUR_USERNAME/ProxmoxVE.git
bash docs/contribution/setup-fork.sh --full
```

### "Permission denied"

```bash
# Make script executable
chmod +x docs/contribution/setup-fork.sh
bash docs/contribution/setup-fork.sh --full
```

### Reverted Changes by Accident?

```bash
# Backups are created automatically
git checkout docs/*.backup
# Or just re-run setup-fork.sh
bash docs/contribution/setup-fork.sh --full
```

---

## Next Steps

1. ✅ Run `bash docs/contribution/setup-fork.sh --full`
2. 📖 Read [docs/contribution/GUIDE.md](GUIDE.md)
3. 🍴 Choose your contribution path:
   - **Containers** → [docs/ct/README.md](docs/ct/README.md)
   - **Installation** → [docs/install/README.md](docs/install/README.md)
   - **VMs** → [docs/vm/README.md](docs/vm/README.md)
   - **Tools** → [docs/tools/README.md](docs/tools/README.md)
4. 💻 Create your feature branch and contribute!

---

## Questions?

- **Fork Setup Issues?** → See [Troubleshooting](#troubleshooting) above
- **How to Contribute?** → [docs/contribution/GUIDE.md](GUIDE.md)
- **Git Workflows?** → `cat .git-setup-info`
- **Project Structure?** → [docs/README.md](docs/README.md)

---

## Happy Contributing! 🚀
