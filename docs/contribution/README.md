# 🤝 Contributing to ProxmoxVE

Complete guide to contributing to the ProxmoxVE project - from your first fork to submitting your pull request.

---

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Setting Up Your Fork](#setting-up-your-fork)
- [Coding Standards](#coding-standards)
- [Code Audit](#code-audit)
- [Guides & Resources](#guides--resources)
- [FAQ](#faq)

---

## 🚀 Quick Start

### 60 Seconds to Contributing (Development)

When developing and testing **in your fork**:

```bash
# 1. Fork on GitHub
# Visit: https://github.com/community-scripts/ProxmoxVE → Fork (top right)

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/ProxmoxVE.git
cd ProxmoxVE

# 3. Auto-configure your fork (IMPORTANT - updates all links!)
bash docs/contribution/setup-fork.sh

# 4. Create a feature branch
git checkout -b feature/my-awesome-app

# 5. Read the guides
cat docs/README.md              # Documentation overview
cat docs/ct/DETAILED_GUIDE.md   # For container scripts
cat docs/install/DETAILED_GUIDE.md  # For install scripts

# 6. Create your contribution
cp docs/contribution/templates_ct/AppName.sh ct/myapp.sh
cp docs/contribution/templates_install/AppName-install.sh install/myapp-install.sh
# ... edit files ...

# 7. Test locally (in your fork before PR)
bash ct/myapp.sh
# ⚠️ Important: Always use `bash ct/myapp.sh`, NOT `./ct/myapp.sh`

# 8. Create your JSON metadata file
cp docs/contribution/templates_json/AppName.json frontend/public/json/myapp.json
# Edit metadata: name, slug, categories, description, resources, etc.

# 9. Test locally (in your fork before PR)
bash ct/myapp.sh
# ⚠️ Important: Always use `bash ct/myapp.sh`, NOT `./ct/myapp.sh`

# 10. Commit ONLY your new files (see Cherry-Pick section below!)
git add ct/myapp.sh install/myapp-install.sh frontend/public/json/myapp.json
git commit -m "feat: add MyApp container and install scripts"
git push origin feature/my-awesome-app

# 11. Create Pull Request on GitHub
```

⚠️ **IMPORTANT: After setup-fork.sh, many files are modified!**

See the **Cherry-Pick: Submitting Only Your Changes** section below to learn how to push ONLY your 3-4 files instead of 600+ modified files!

### How Users Run Scripts (After Merged)

Once your script is merged to the main repository, users download and run it from GitHub like this:

```bash
# ✅ Users run from GitHub (normal usage after PR merged)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/myapp.sh)"

# For installation on existing Proxmox hosts
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/install/myapp-install.sh)"
```

### Development vs. Production Execution

**During Development (you, in your fork):**
```bash
bash ct/myapp.sh

# The script's curl commands are updated by setup-fork.sh to pull from YOUR fork
# This ensures you're testing your actual changes
```

**After Merge (users, from GitHub):**
```bash
# Users download the script from upstream via curl
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/myapp.sh)"

# The script's curl commands now point back to upstream (community-scripts)
# This is the stable, tested version
```

**Summary:**
- **Development**: `bash ct/myapp.sh` (local clone) → setup-fork.sh changes curl URLs to your fork
- **Production**: `curl | bash` from upstream → curl URLs point to community-scripts repo

---

## 🍴 Setting Up Your Fork

### Automatic Setup (Recommended)

When you clone your fork, run the setup script to automatically configure everything:

```bash
bash docs/contribution/setup-fork.sh
```

**What it does:**

- Auto-detects your GitHub username from git config
- Auto-detects your fork repository name
- Updates **ALL** hardcoded links to point to your fork instead of the main repo
- Creates `.git-setup-info` with your configuration
- Allows you to develop and test independently in your fork

**Why this matters:**

Without running this script, all links in your fork will still point to the upstream repository (community-scripts). This is a problem when testing because:

- Installation links will pull from upstream, not your fork
- Updates will target the wrong repository
- Your contributions won't be properly tested

**After running setup-fork.sh:**

Your fork is fully configured and ready to develop. You can:

- Test changes locally with `bash ct/myapp.sh`
- All links will reference your fork for development
- Commit and push with confidence
- Create a PR to merge into upstream

**See**: [FORK_SETUP.md](FORK_SETUP.md) for detailed instructions

### Manual Setup

If the script doesn't work, manually configure:

```bash
# Set git user
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Add upstream remote for syncing with main repo
git remote add upstream https://github.com/community-scripts/ProxmoxVE.git

# Verify remotes
git remote -v
# Should show: origin (your fork) and upstream (main repo)
```

---

## 📖 Coding Standards

All scripts and configurations must follow our coding standards to ensure consistency and quality.

### Available Guides

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Essential coding standards and best practices
- **[CODE_AUDIT.md](CODE_AUDIT.md)** - Code review checklist and audit procedures
- **[GUIDE.md](GUIDE.md)** - Comprehensive contribution guide
- **[HELPER_FUNCTIONS.md](HELPER_FUNCTIONS.md)** - Reference for all tools.func helper functions
- **Container Scripts** - `/ct/` templates and guidelines
- **Install Scripts** - `/install/` templates and guidelines
- **JSON Configurations** - `/json/` structure and format

### Quick Checklist

- ✅ Use `/ct/example.sh` as template for container scripts
- ✅ Use `/install/example-install.sh` as template for install scripts
- ✅ Follow naming conventions: `appname.sh` and `appname-install.sh`
- ✅ Include proper shebang: `#!/usr/bin/env bash`
- ✅ Add copyright header with author
- ✅ Handle errors properly with `msg_error`, `msg_ok`, etc.
- ✅ Test before submitting PR
- ✅ Update documentation if needed

---

## 🔍 Code Audit

Before submitting a pull request, ensure your code passes our audit:

**See**: [CODE_AUDIT.md](CODE_AUDIT.md) for complete audit checklist

Key points:

- Code consistency with existing scripts
- Proper error handling
- Correct variable naming
- Adequate comments and documentation
- Security best practices

---

## 🍒 Cherry-Pick: Submitting Only Your Changes

**Problem**: `setup-fork.sh` modifies 600+ files to update links. You don't want to submit all of those changes - only your new 3-4 files!

**Solution**: Use git cherry-pick to select only YOUR files.

### Step-by-Step Cherry-Pick Guide

#### 1. Check what changed

```bash
# See all modified files
git status

# Verify your files are there
git status | grep -E "ct/myapp|install/myapp|json/myapp"
```

#### 2. Create a clean feature branch for submission

```bash
# Go back to upstream main (clean slate)
git fetch upstream
git checkout -b submit/myapp upstream/main

# Don't use your modified main branch!
```

#### 3. Cherry-pick ONLY your files

Cherry-picking extracts specific changes from commits:

```bash
# Option A: Cherry-pick commits that added your files
# (if you committed your files separately)
git cherry-pick <commit-hash-of-your-files>

# Option B: Manually copy and commit only your files
# From your work branch, get the file contents
git show feature/my-awesome-app:ct/myapp.sh > /tmp/myapp.sh
git show feature/my-awesome-app:install/myapp-install.sh > /tmp/myapp-install.sh
git show feature/my-awesome-app:frontend/public/json/myapp.json > /tmp/myapp.json

# Add them to the clean branch
cp /tmp/myapp.sh ct/myapp.sh
cp /tmp/myapp-install.sh install/myapp-install.sh
cp /tmp/myapp.json frontend/public/json/myapp.json

# Commit
git add ct/myapp.sh install/myapp-install.sh frontend/public/json/myapp.json
git commit -m "feat: add MyApp"
```

#### 4. Verify only your files are in the PR

```bash
# Check git diff against upstream
git diff upstream/main --name-only
# Should show ONLY:
#   ct/myapp.sh
#   install/myapp-install.sh
#   frontend/public/json/myapp.json
```

#### 5. Push and create PR

```bash
# Push your clean submission branch
git push origin submit/myapp

# Create PR on GitHub from: submit/myapp → main
```

### Why This Matters

- ✅ Clean PR with only your changes
- ✅ Easier for maintainers to review
- ✅ Faster merge without conflicts
- ❌ Without cherry-pick: PR has 600+ file changes (won't merge!)

### If You Made a Mistake

```bash
# Delete the messy branch
git branch -D submit/myapp

# Go back to clean branch
git checkout -b submit/myapp upstream/main

# Try cherry-picking again
```

---

If you're using **Visual Studio Code** with an AI assistant, you can leverage our detailed guidelines to generate high-quality contributions automatically.

### How to Use AI Assistance

1. **Open the AI Guidelines**

   ```
   docs/contribution/AI.md
   ```

   This file contains all requirements, patterns, and examples for writing proper scripts.

2. **Prepare Your Information**

   Before asking the AI to generate code, gather:
   - **Repository URL**: e.g., `https://github.com/owner/myapp`
   - **Dockerfile/Script**: Paste the app's installation instructions (if available)
   - **Dependencies**: What packages does it need? (Node, Python, Java, PostgreSQL, etc.)
   - **Ports**: What port does it listen on? (e.g., 3000, 8080, 5000)
   - **Configuration**: Any environment variables or config files?

3. **Tell the AI Assistant**

   Share with the AI:
   - The repository URL
   - The Dockerfile or install instructions
   - Link to [docs/contribution/AI.md](AI.md) with instructions to follow

   **Example prompt:**

   ```
   I want to contribute a container script for MyApp to ProxmoxVE.
   Repository: https://github.com/owner/myapp

   Here's the Dockerfile:
   [paste Dockerfile content]

   Please follow the guidelines in docs/contribution/AI.md to create:
   1. ct/myapp.sh (container script)
   2. install/myapp-install.sh (installation script)
   3. frontend/public/json/myapp.json (metadata)
   ```

4. **AI Will Generate**

   The AI will produce scripts that:
   - Follow all ProxmoxVE patterns and conventions
   - Use helper functions from `tools.func` correctly
   - Include proper error handling and messages
   - Have correct update mechanisms
   - Are ready to submit as a PR

### Key Points for AI Assistants

- **Templates Location**: `docs/contribution/templates_ct/AppName.sh`, `templates_install/`, `templates_json/`
- **Guidelines**: Must follow `docs/contribution/AI.md` exactly
- **Helper Functions**: Use only functions from `misc/tools.func` - never write custom ones
- **Testing**: Always include `bash ct/myapp.sh` testing before submission
- **No Docker**: Container scripts must be bare-metal, not Docker-based

### Benefits

- **Speed**: AI generates boilerplate in seconds
- **Consistency**: Follows same patterns as 200+ existing scripts
- **Quality**: Less bugs and more maintainable code
- **Learning**: See how your app should be structured

---

### Documentation

- **[docs/README.md](../README.md)** - Main documentation hub
- **[docs/ct/README.md](../ct/README.md)** - Container scripts overview
- **[docs/install/README.md](../install/README.md)** - Installation scripts overview
- **[docs/ct/DETAILED_GUIDE.md](../ct/DETAILED_GUIDE.md)** - Complete ct/ script reference
- **[docs/install/DETAILED_GUIDE.md](../install/DETAILED_GUIDE.md)** - Complete install/ script reference
- **[docs/TECHNICAL_REFERENCE.md](../TECHNICAL_REFERENCE.md)** - Architecture deep-dive
- **[docs/EXIT_CODES.md](../EXIT_CODES.md)** - Exit codes reference
- **[docs/DEV_MODE.md](../DEV_MODE.md)** - Debugging guide

### Community Guides

See [USER_SUBMITTED_GUIDES.md](USER_SUBMITTED_GUIDES.md) for excellent community-written guides:

- Home Assistant installation and configuration
- Frigate setup on Proxmox
- Docker and Portainer installation
- Database setup and optimization
- And many more!

### Templates

Use these templates when creating new scripts:

```bash
# Container script template
cp docs/contribution/templates_ct/AppName.sh ct/my-app.sh

# Installation script template
cp docs/contribution/templates_install/AppName-install.sh install/my-app-install.sh

# JSON configuration template
cp docs/contribution/templates_json/AppName.json frontend/public/json/my-app.json
```

**Template Features:**

- Updated to match current codebase patterns
- Includes all available helper functions from `tools.func`
- Examples for Node.js, Python, PHP, Go applications
- Database setup examples (MariaDB, PostgreSQL)
- Proper service creation and cleanup

---

## 🔄 Git Workflow

### Keep Your Fork Updated

```bash
# Fetch latest from upstream
git fetch upstream

# Rebase your work on latest main
git rebase upstream/main

# Push to your fork
git push -f origin main
```

### Create Feature Branch

```bash
# Create and switch to new branch
git checkout -b feature/my-feature

# Make changes...
git add .
git commit -m "feat: description of changes"

# Push to your fork
git push origin feature/my-feature

# Create Pull Request on GitHub
```

### Before Submitting PR

1. **Sync with upstream**

   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Test your changes**

   ```bash
   bash ct/my-app.sh
   # Follow prompts and test the container
   ```

3. **Check code standards**
   - [ ] Follows template structure
   - [ ] Proper error handling
   - [ ] Documentation updated (if needed)
   - [ ] No hardcoded values
   - [ ] Version tracking implemented

4. **Push final changes**
   ```bash
   git push origin feature/my-feature
   ```

---

## 📋 Pull Request Checklist

Before opening a PR:

- [ ] Code follows coding standards (see CONTRIBUTING.md)
- [ ] All templates used correctly
- [ ] Tested on Proxmox VE
- [ ] Error handling implemented
- [ ] Documentation updated (if applicable)
- [ ] No merge conflicts
- [ ] Synced with upstream/main
- [ ] Clear PR title and description

---

## ❓ FAQ

### ⚠️ Why must I use `bash ct/myapp.sh` (during development)?

During **local development and testing** in your fork, use bash explicitly:

```bash
# ✅ CORRECT (during development in your fork)
bash ct/myapp.sh

# ❌ WRONG - Will fail
./ct/myapp.sh
sh ct/myapp.sh
/path/to/ct/myapp.sh
```

**Why?**

- Scripts use bash-specific features (arrays, process substitution, etc.)
- Permissions might not be executable on Windows/WSL
- Source files need proper `<(curl ...)` process substitution
- Error handling requires specific bash settings

**⚠️ But remember:** Once merged, users will run it via `curl | bash` from GitHub, not locally!

### How do I test my changes locally?

```bash
# You're on Proxmox VE host with your fork cloned
# Test your script before PR:

bash ct/my-app.sh

# The setup-fork.sh script ensures curl pulls from YOUR fork, not upstream
# So this tests your actual changes!

# For advanced debugging with verbose output
VERBOSE=yes bash ct/my-app.sh
DEV_MODE_LOGS=true bash ct/my-app.sh
```

### What if my PR has conflicts?

```bash
# Sync with upstream main repository
git fetch upstream
git rebase upstream/main

# Resolve conflicts in your editor
git add .
git rebase --continue
git push -f origin your-branch
```

### How do I keep my fork updated?

Two ways:

**Option 1: Run setup script again**

```bash
bash docs/contribution/setup-fork.sh
```

**Option 2: Manual sync**

```bash
git fetch upstream
git rebase upstream/main
git push -f origin main
```

### Where do I ask questions?

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For general questions and ideas
- **Discord**: Community-scripts server for real-time chat

---

## 🎓 Learning Resources

### For First-Time Contributors

1. Read: [docs/README.md](../README.md) - Documentation overview
2. Read: [CONTRIBUTING.md](CONTRIBUTING.md) - Essential coding standards
3. Choose your path:
   - Containers → [docs/ct/DETAILED_GUIDE.md](../ct/DETAILED_GUIDE.md)
   - Installation → [docs/install/DETAILED_GUIDE.md](../install/DETAILED_GUIDE.md)
4. Study existing scripts in same category
5. Create your contribution

### For Experienced Developers

1. Review [CONTRIBUTING.md](CONTRIBUTING.md) - Coding standards
2. Review [CODE_AUDIT.md](CODE_AUDIT.md) - Audit checklist
3. Check templates in `/docs/contribution/templates_*/`
4. Use AI assistants with [AI.md](AI.md) for code generation
5. Submit PR with confidence

### For Using AI Assistants

See "Using AI Assistants" section above for:

- How to structure prompts
- What information to provide
- How to validate AI output

---

## 🚀 Ready to Contribute?

1. **Fork** the repository
2. **Clone** your fork and **setup** with `bash docs/contribution/setup-fork.sh`
3. **Choose** your contribution type (container, installation, tools, etc.)
4. **Read** the appropriate detailed guide
5. **Create** your feature branch
6. **Develop** and **test** your changes
7. **Commit** with clear messages
8. **Push** to your fork
9. **Create** Pull Request

---

## 📞 Contact & Support

- **GitHub**: [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE)
- **Issues**: [GitHub Issues](https://github.com/community-scripts/ProxmoxVE/issues)
- **Discussions**: [GitHub Discussions](https://github.com/community-scripts/ProxmoxVE/discussions)
- **Discord**: [Join Server](https://discord.gg/UHrpNWGwkH)

---

**Thank you for contributing to ProxmoxVE!** 🙏

Your efforts help make Proxmox VE automation accessible to everyone. Happy coding! 🚀
