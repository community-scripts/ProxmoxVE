# Rebranding Plan: community-unscripted → Heretek-AI

## Overview

This document outlines the plan to rebrand all references from `community-unscripted` to `Heretek-AI` throughout the ProxmoxVE codebase.

**Scope:**
- ✅ Replace all `community-unscripted` organization references with `Heretek-AI`
- ✅ Replace all `Community Unscripted` / `Community-Unscripted` display names with `Heretek-AI`
- ❌ Keep `community-scripts` upstream references unchanged (orthodox source)
- ❌ Keep `telemetry.community-scripts.org` unchanged (upstream service)

---

## Summary of Changes

Based on the codebase analysis, there are **81 occurrences** of `community-unscripted` across **26 files** that need to be updated.

### Categories of Files to Update

| Category | Files | Occurrences |
|----------|-------|-------------|
| Documentation | README.md, CHANGELOG.md, frontend/README.md | 20+ |
| GitHub Workflows | 12 workflow files in .github/workflows/ | 20+ |
| Frontend Source | 10+ TypeScript/TSX files | 25+ |
| Shell Scripts | ct/*.sh, install/*.sh, tools/addon/*.sh | 12+ |
| GitHub Templates | .github/pull_request_template.md | 1 |

---

## Detailed File Changes

### 1. Documentation Files

#### [`README.md`](../README.md)
- Line 9-10: Badge URL `github.com/community-unscripted/ProxmoxVE`
- Line 21-28: Multiple badge URLs
- Line 185-189: Installation example URLs
- Line 197: Script installation URL
- Line 222-230: Discussion and issue links
- Line 270: Contributing guidelines link
- Line 305-318: Star history chart URLs

#### [`CHANGELOG.md`](../CHANGELOG.md)
- Line 427: PR link `github.com/community-unscripted/ProxmoxVE/pull/11`
- Line 433: PR link `github.com/community-unscripted/ProxmoxVE/pull/6`

#### [`frontend/README.md`](../frontend/README.md)
- Line 3-5: Project description
- Line 81: Clone URL
- Line 262: Organization credit
- Line 269-278: Links section

### 2. GitHub Workflows

All workflow files in [`.github/workflows/`](../.github/workflows/):

| File | Lines to Update |
|------|-----------------|
| `auto-update-app-headers.yml` | Line 13 |
| `changelog-archive.yml` | Line 11 |
| `autolabeler.yml` | Line 11 |
| `check-node-versions.yml` | Line 15 |
| `changelog-pr.yml` | Line 10, 123-124 |
| `close-discussion.yml` | Line 14 |
| `close_issue_in_dev.yaml` | Lines 8, 15, 31, 64-65 |
| `close-new-script-prs.yml` | Lines 10, 90, 93 |
| `close-tteck-issues.yaml` | Lines 8, 28 |
| `create-docker-for-runner.yml` | Line 14 |
| `delete-json-branch.yml` | Line 12 |
| `frontend-cicd.yml` | Lines 102, 137 |
| `github-release.yml` | Line 10 |
| `update-versions-github.yml` | Line 20 |
| `update-json-date.yml` | Line 13 |
| `upstream-sync.yml` | Line 131 |

### 3. Frontend Files

#### Configuration
- [`frontend/src/config/site-config.tsx`](../frontend/src/config/site-config.tsx)
  - Lines 12, 24, 31: GitHub links

#### Components
- [`frontend/src/components/footer.tsx`](../frontend/src/components/footer.tsx) - Line 18
- [`frontend/src/components/navbar.tsx`](../frontend/src/components/navbar.tsx) - Line 53
- [`frontend/src/components/command-menu.tsx`](../frontend/src/components/command-menu.tsx) - Line 227
- [`frontend/src/components/ui/codeblock.tsx`](../frontend/src/components/ui/codeblock.tsx) - Line 76
- [`frontend/src/components/ui/star-on-github-button.tsx`](../frontend/src/components/ui/star-on-github-button.tsx) - Lines 18, 44

#### App Files
- [`frontend/src/app/layout.tsx`](../frontend/src/app/layout.tsx) - Lines 40, 43-47, 62, 66, 81
- [`frontend/src/app/page.tsx`](../frontend/src/app/page.tsx) - Lines 91, 107
- [`frontend/src/app/robots.ts`](../frontend/src/app/robots.ts) - Line 13
- [`frontend/src/app/sitemap.ts`](../frontend/src/app/sitemap.ts) - Line 8

#### Script Components
- [`frontend/src/app/scripts/_components/script-items/buttons.tsx`](../frontend/src/app/scripts/_components/script-items/buttons.tsx) - Lines 15, 20, 37
- [`frontend/src/app/scripts/_components/script-items/install-command.tsx`](../frontend/src/app/scripts/_components/script-items/install-command.tsx) - Lines 13-14

#### Package Files
- [`frontend/package.json`](../frontend/package.json) - Line 8

### 4. Shell Scripts

#### CT Scripts (Container Templates)
| File | Lines |
|------|-------|
| [`ct/agregarr.sh`](../ct/agregarr.sh) | Lines 2, 6 |
| [`ct/drop.sh`](../ct/drop.sh) | Lines 2, 5 |
| [`ct/hermes.sh`](../ct/hermes.sh) | Lines 3, 7 |
| [`ct/lemonade.sh`](../ct/lemonade.sh) | Lines 2, 6 |
| [`ct/mcphub.sh`](../ct/mcphub.sh) | Lines 2, 6 |
| [`ct/swarmui.sh`](../ct/swarmui.sh) | Lines 2, 6 |

#### Install Scripts
| File | Lines |
|------|-------|
| [`install/agregarr-install.sh`](../install/agregarr-install.sh) | Line 3 |
| [`install/drop-install.sh`](../install/drop-install.sh) | Line 4 |
| [`install/hermes-install.sh`](../install/hermes-install.sh) | Line 4 |
| [`install/lemonade-install.sh`](../install/lemonade-install.sh) | Line 4 |
| [`install/mcphub-install.sh`](../install/mcphub-install.sh) | Line 4 |
| [`install/swarmui-install.sh`](../install/swarmui-install.sh) | Line 4 |

#### Tools
- [`tools/addon/rocm.sh`](../tools/addon/rocm.sh) - Line 5

### 5. GitHub Templates
- [`.github/pull_request_template.md`](../.github/pull_request_template.md) - Line 1

---

## Replacement Patterns

### URL Replacements
```
github.com/community-unscripted/ProxmoxVE → github.com/Heretek-AI/ProxmoxVE
raw.githubusercontent.com/community-unscripted/ProxmoxVE → raw.githubusercontent.com/Heretek-AI/ProxmoxVE
community-unscripted.github.io/ProxmoxVE → heretek-ai.github.io/ProxmoxVE
```

### Display Name Replacements
```
Community Unscripted → Heretek-AI
Community-Unscripted → Heretek-AI
community-unscripted → Heretek-AI
```

### Organization References
```
community-unscripted/ProxmoxVE → Heretek-AI/ProxmoxVE
community-unscripted/ProxmoxVED → Heretek-AI/ProxmoxVED
```

---

## Execution Order

1. **Documentation** - Start with README.md and CHANGELOG.md for visibility
2. **GitHub Workflows** - Critical for CI/CD pipeline functionality
3. **Frontend** - Update all TypeScript/TSX files
4. **Shell Scripts** - Update CT and install scripts
5. **Templates** - Update GitHub templates
6. **Verification** - Test all links and run frontend build

---

## Post-Rebranding Checklist

- [ ] Verify GitHub repository URLs work
- [ ] Test frontend build: `cd frontend && npm run build`
- [ ] Verify GitHub Actions workflows run successfully
- [ ] Update GitHub repository description and settings
- [ ] Update any external documentation or links
- [ ] Verify GitHub Pages deployment (if applicable)

---

## Notes

- The `community-scripts` upstream references are intentionally kept unchanged as they reference the orthodox source repository
- Telemetry endpoints (`telemetry.community-scripts.org`) are kept unchanged as they're upstream services
- The git remote is already configured to point to `Heretek-AI/ProxmoxVE` (verified in `.git/config`)
