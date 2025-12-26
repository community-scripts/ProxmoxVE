# 🍴 Fork Setup Guide

**Just forked ProxmoxVE? Run this first!**

## Quick Start

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/ProxmoxVE.git
cd ProxmoxVE

# Run setup script (auto-detects your username from git)
bash setup-fork.sh
```

That's it! ✅

---

## What Does It Do?

The `setup-fork.sh` script automatically:

1. **Detects** your GitHub username from git config
2. **Updates** 22 hardcoded links in documentation to point to your fork
3. **Creates** `.git-setup-info` with recommended git workflows
4. **Backs up** all modified files (*.backup)

---

## Usage

### Auto-Detect (Recommended)
```bash
bash setup-fork.sh
```
Automatically reads your GitHub username from `git remote origin url`

### Specify Username
```bash
bash setup-fork.sh john
```
Updates links to `github.com/john/ProxmoxVE`

### Custom Repository Name
```bash
bash setup-fork.sh john my-fork
```
Updates links to `github.com/john/my-fork`

---

## What Gets Updated?

The script updates these documentation files:
- `docs/CONTRIBUTION_GUIDE.md` (4 links)
- `docs/README.md` (1 link)
- `docs/INDEX.md` (3 links)
- `docs/EXIT_CODES.md` (2 links)
- `docs/DEFAULTS_SYSTEM_GUIDE.md` (2 links)
- `docs/api/README.md` (1 link)
- `docs/APP-ct.md` (1 link)
- `docs/APP-install.md` (1 link)
- `docs/alpine-install.func.md` (2 links)
- `docs/install.func.md` (1 link)
- And code examples in documentation

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
   cat docs/CONTRIBUTION_GUIDE.md
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
bash setup-fork.sh
```

### "Could not auto-detect GitHub username"
```bash
# Your git origin URL isn't set up correctly
git remote -v
# Should show your fork URL, not community-scripts

# Fix it:
git remote set-url origin https://github.com/YOUR_USERNAME/ProxmoxVE.git
bash setup-fork.sh
```

### "Permission denied"
```bash
# Make script executable
chmod +x setup-fork.sh
bash setup-fork.sh
```

### Reverted Changes by Accident?
```bash
# Backups are created automatically
git checkout docs/*.backup
# Or just re-run setup-fork.sh
```

---

## Next Steps

1. ✅ Run `bash setup-fork.sh`
2. 📖 Read [docs/CONTRIBUTION_GUIDE.md](docs/CONTRIBUTION_GUIDE.md)
3. 🍴 Choose your contribution path:
   - **Containers** → [docs/ct/README.md](docs/ct/README.md)
   - **Installation** → [docs/install/README.md](docs/install/README.md)
   - **VMs** → [docs/vm/README.md](docs/vm/README.md)
   - **Tools** → [docs/tools/README.md](docs/tools/README.md)
4. 💻 Create your feature branch and contribute!

---

## Questions?

- **Fork Setup Issues?** → See [Troubleshooting](#troubleshooting) above
- **How to Contribute?** → [docs/CONTRIBUTION_GUIDE.md](docs/CONTRIBUTION_GUIDE.md)
- **Git Workflows?** → `cat .git-setup-info`
- **Project Structure?** → [docs/README.md](docs/README.md)

---

**Happy Contributing! 🚀**
