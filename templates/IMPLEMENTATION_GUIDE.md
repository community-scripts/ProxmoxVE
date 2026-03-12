# Implementation Guide: Standalone Repository Setup

This guide walks you through setting up the standalone `Heretek-Proxmox-Scripts` repository.

## Prerequisites

- GitHub account with access to `Heretek-AI` organization
- Admin access to `Heretek-AI/ProxmoxVE` (fork)
- Git installed locally

---

## Step 1: Create the Standalone Repository

### 1.1 Create on GitHub

1. Go to https://github.com/new
2. Fill in the details:
   - **Owner:** `Heretek-AI`
   - **Repository name:** `Heretek-Proxmox-Scripts`
   - **Description:** `Custom LXC container scripts for Proxmox VE - AI assistants, automation tools, and more`
   - **Visibility:** Public
   - **Initialize:** Add a README file
   - **License:** MIT
3. Click **Create repository**

### 1.2 Add Repository Topics

After creation, add these topics for discoverability:

1. Go to the repository main page
2. Click the ⚙️ gear icon next to "About"
3. Add topics:
   - `proxmox`
   - `proxmox-ve`
   - `lxc`
   - `container`
   - `scripts`
   - `ai`
   - `automation`
   - `self-hosted`
   - `homelab`
4. Click **Save changes**

---

## Step 2: Create Personal Access Token

### 2.1 Generate Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens
   - Direct link: https://github.com/settings/personal-access-tokens/new
2. Fill in:
   - **Token name:** `Standalone Repo Sync`
   - **Expiration:** 90 days (or custom)
   - **Repository access:** Only select repositories → Select `Heretek-Proxmox-Scripts`
3. Set permissions:
   - **Contents:** Read and Write
   - **Metadata:** Read
4. Click **Generate token**
5. **Copy the token immediately** - you won't see it again!

### 2.2 Add Token to Fork Repository

1. Go to https://github.com/Heretek-AI/ProxmoxVE/settings/secrets/actions
2. Click **New repository secret**
3. Fill in:
   - **Name:** `PAT_STANDALONE`
   - **Secret:** Paste your token
4. Click **Add secret**

---

## Step 3: Push the Workflow to Fork

The workflow file has been created at `.github/workflows/sync-to-standalone.yml`.

### 3.1 Commit and Push

```bash
# From your local ProxmoxVE directory
git add .github/workflows/sync-to-standalone.yml
git commit -m "feat: add workflow to sync custom scripts to standalone repository"
git push origin main
```

---

## Step 4: Initialize Standalone Repository

### 4.1 Clone and Setup

```bash
# Clone the standalone repository
git clone https://github.com/Heretek-AI/Heretek-Proxmox-Scripts.git
cd Heretek-Proxmox-Scripts

# Create directory structure
mkdir -p ct/headers
mkdir -p install
mkdir -p frontend/public/json
mkdir -p docs
```

### 4.2 Copy Files from Fork

```bash
# From your ProxmoxVE fork, copy custom scripts
# Replace PATH_TO_FORK with your fork path

# Container scripts
cp PATH_TO_FORK/ct/agregarr.sh ct/
cp PATH_TO_FORK/ct/drop.sh ct/
cp PATH_TO_FORK/ct/hermes.sh ct/
cp PATH_TO_FORK/ct/lemonade.sh ct/
cp PATH_TO_FORK/ct/llamacpp.sh ct/
cp PATH_TO_FORK/ct/maintainerr.sh ct/
cp PATH_TO_FORK/ct/mcphub.sh ct/
cp PATH_TO_FORK/ct/openclaw.sh ct/
cp PATH_TO_FORK/ct/pegaprox.sh ct/
cp PATH_TO_FORK/ct/swarmui.sh ct/
cp PATH_TO_FORK/ct/wakapi.sh ct/

# Install scripts
cp PATH_TO_FORK/install/agregarr-install.sh install/
cp PATH_TO_FORK/install/drop-install.sh install/
cp PATH_TO_FORK/install/hermes-install.sh install/
cp PATH_TO_FORK/install/lemonade-install.sh install/
cp PATH_TO_FORK/install/llamacpp-install.sh install/
cp PATH_TO_FORK/install/maintainerr-install.sh install/
cp PATH_TO_FORK/install/mcphub-install.sh install/
cp PATH_TO_FORK/install/openclaw-install.sh install/
cp PATH_TO_FORK/install/pegaprox-install.sh install/
cp PATH_TO_FORK/install/swarmui-install.sh install/
cp PATH_TO_FORK/install/wakapi-install.sh install/

# Header files
cp PATH_TO_FORK/ct/headers/agregarr ct/headers/
cp PATH_TO_FORK/ct/headers/drop ct/headers/
cp PATH_TO_FORK/ct/headers/hermes ct/headers/
cp PATH_TO_FORK/ct/headers/lemonade ct/headers/
cp PATH_TO_FORK/ct/headers/llamacpp ct/headers/
cp PATH_TO_FORK/ct/headers/maintainerr ct/headers/
cp PATH_TO_FORK/ct/headers/mcphub ct/headers/
cp PATH_TO_FORK/ct/headers/openclaw ct/headers/
cp PATH_TO_FORK/ct/headers/pegaprox ct/headers/
cp PATH_TO_FORK/ct/headers/swarmui ct/headers/
cp PATH_TO_FORK/ct/headers/wakapi ct/headers/

# JSON metadata (if exists)
cp PATH_TO_FORK/frontend/public/json/*.json frontend/public/json/ 2>/dev/null || true
```

### 4.3 Copy README Template

```bash
# Copy the README template created in this project
cp PATH_TO_FORK/templates/standalone-readme.md README.md
```

### 4.4 Commit and Push

```bash
git add -A
git commit -m "Initial commit: Add custom scripts from Heretek-AI/ProxmoxVE"
git push origin main
```

---

## Step 5: Verify Setup

### 5.1 Test the Sync Workflow

1. Make a small change to one of your custom scripts in the fork
2. Push to main branch
3. Check the Actions tab in your fork repository
4. Verify the `Sync to Standalone Repository` workflow runs successfully
5. Check the standalone repository to confirm the change synced

### 5.2 Verify GitHub Search

After setup, it may take 24-48 hours for GitHub to index your repository.

Test by searching for:
- `Heretek-Proxmox-Scripts`
- `proxmox scripts heretek`
- Your specific script names

---

## Workflow Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                    Development Workflow                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Develop in Fork (Heretek-AI/ProxmoxVE)                      │
│     └─► Edit custom scripts in ct/, install/                    │
│                                                                 │
│  2. Push to Main Branch                                         │
│     └─► git push origin main                                    │
│                                                                 │
│  3. Auto-Sync Triggers                                          │
│     └─► sync-to-standalone.yml workflow runs                    │
│                                                                 │
│  4. Standalone Repository Updated                               │
│     └─► Heretek-AI/Heretek-Proxmox-Scripts                     │
│                                                                 │
│  5. GitHub Search Indexes Standalone                            │
│     └─► Users can discover your scripts!                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Troubleshooting

### Workflow Fails with Permission Error

- Verify `PAT_STANDALONE` secret is set correctly
- Verify token has `Contents: Read and Write` permission
- Verify token has access to `Heretek-Proxmox-Scripts` repository

### Scripts Not Syncing

- Check workflow file paths match your actual file paths
- Verify workflow is triggered on push to `main` branch
- Check Actions tab for workflow run logs

### GitHub Search Not Finding Repository

- Wait 24-48 hours for indexing
- Ensure repository is public
- Add relevant topics to repository
- Ensure README has descriptive content

---

## Files Created

| File | Purpose |
|------|---------|
| `.github/workflows/sync-to-standalone.yml` | Auto-sync workflow for fork |
| `templates/standalone-readme.md` | README template for standalone repo |
| `templates/IMPLEMENTATION_GUIDE.md` | This implementation guide |
| `plans/standalone-repository-plan.md` | Detailed architecture plan |

---

## Next Steps

1. ✅ Create standalone repository on GitHub
2. ✅ Add repository topics
3. ✅ Create Personal Access Token
4. ✅ Add `PAT_STANDALONE` secret to fork
5. ✅ Push workflow to fork
6. ✅ Initialize standalone repository with files
7. ✅ Test sync workflow
8. ⏳ Wait for GitHub search indexing

---

## Questions?

If you encounter issues:
1. Check the Actions tab in your fork for workflow logs
2. Verify all secrets are set correctly
3. Ensure file paths match between fork and standalone
