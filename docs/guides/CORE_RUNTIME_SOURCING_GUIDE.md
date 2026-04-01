# Core Runtime Sourcing Guide

This guide explains how runtime module loading works after the core hardening changes, and how to operate it safely in production.

## Why this exists

The runtime now uses a **local-first** loading strategy for core modules (`core.func`, `error_handler.func`, `tools.func`, `install.func`, `alpine-install.func`).

That means:

1. Try local files first (preferred, deterministic)
2. Fall back to remote source only if local files are not available
3. Allow pinning to a specific branch/tag/commit via environment variables

This reduces failures from transient network/CDN issues and improves deployment reproducibility.

---

## Default behavior (no config needed)

If you do nothing, scripts will:

- Use local `misc/*.func` files when available
- Otherwise use GitHub raw URLs under `community-scripts/ProxmoxVE/main`

This is backward compatible with existing usage.

---

## Host vs LXC: where data is needed

Short answer: **for normal online operation, no full duplication is required**.

### If you only care about `update` inside the LXC

That is now the simplest path:

- Installer writes `/usr/local/community-scripts/runtime-source.env` inside the container
- `/usr/bin/update` reads that file first
- `update` therefore keeps using the container's pinned source settings by default

In other words, you can manage update source behavior entirely inside the LXC without requiring host-side duplication.

### Runtime split

- **Host side**
  - `misc/build.func` orchestrates creation and bootstrapping.
  - It provides bootstrap function payload for install scripts.

- **LXC side**
  - install scripts run inside the container.
  - They try local core modules first; if not present, they use remote fallback.

### Practical implications

1. **Online default mode**
   - Host local files + remote fallback inside LXC are enough.
   - No manual copy of all `misc/*.func` into the container is strictly required.

2. **Strict reproducible/offline mode**
   - You should provide the same module set on both sides:
     - host checkout (for orchestration)
     - local module files in LXC (for local-first resolution)
   - Otherwise LXC may use remote fallback and pick newer content than host-local branch state.

3. **Pinned mode (`COMMUNITY_SCRIPTS_REF`)**
   - Greatly reduces mismatch risk because all fallback URLs resolve to the same ref/tag/commit.

---

## Configuration knobs

You can control runtime source resolution with these environment variables.

### 1) `COMMUNITY_SCRIPTS_REF`

- Purpose: Select branch/tag/commit reference used for remote fallback
- Default: `main`

Example values:

- `main`
- `v2026.04`
- `<commit-sha>`

### 2) `COMMUNITY_SCRIPTS_REMOTE_BASE`

- Purpose: Override remote base for `misc/*.func`
- Default: `https://raw.githubusercontent.com/community-scripts/ProxmoxVE/${COMMUNITY_SCRIPTS_REF}/misc`

### 3) `COMMUNITY_SCRIPTS_INSTALL_BASE`

- Purpose: Override remote base for `install/*.sh`
- Default: `https://raw.githubusercontent.com/community-scripts/ProxmoxVE/${COMMUNITY_SCRIPTS_REF}/install`

### 4) `COMMUNITY_SCRIPTS_CT_BASE`

- Purpose: Override remote base for `ct/*.sh` update launcher (`/usr/bin/update` inside CT)
- Default: `https://raw.githubusercontent.com/community-scripts/ProxmoxVE/${COMMUNITY_SCRIPTS_REF}/ct`

---

## Recommended operating modes

### Mode A: Standard users (recommended default)

- Do not set any variables
- Local-first will automatically improve resilience

### Mode B: Release pinning (stable operations)

- Set `COMMUNITY_SCRIPTS_REF` to a known release tag
- Keeps behavior reproducible across nodes and rebuilds

### Mode C: Controlled mirror / internal hosting

- Set `COMMUNITY_SCRIPTS_REMOTE_BASE`, `COMMUNITY_SCRIPTS_INSTALL_BASE`, `COMMUNITY_SCRIPTS_CT_BASE`
- Useful for air-gapped or enterprise mirror setups

---

## What changed in runtime flow

### `misc/build.func`

- Core/API/tools/install payload loading now uses local-first helper resolution
- Remote fallback is configurable via `COMMUNITY_SCRIPTS_*` variables
- Upstream drift check warns if local code differs from latest `origin/main` (when using `COMMUNITY_SCRIPTS_REF=main`)

### `misc/install.func` and `misc/alpine-install.func`

- `core.func` and `error_handler.func` are loaded local-first
- `tools.func` is loaded local-first with remote fallback and retries
- `/usr/bin/update` now uses configurable `COMMUNITY_SCRIPTS_CT_BASE`

---

## Troubleshooting

### How upstream changes are detected

When running from `main` (default), runtime checks for upstream drift:

1. **Git mode (preferred)**
   - If the script runs from a git worktree, it compares:
     - local `HEAD`
     - `origin/main` (`git ls-remote`)
   - If different, a warning is shown.

2. **API fallback (non-git environments)**
   - Reads latest `main` commit SHA from GitHub API
   - Compares it with a locally cached SHA (`/var/cache/community-scripts/upstream-main.sha`)
   - Warns when it changed since the previous run

> Note: drift check is advisory (warning only), not blocking.

### How to avoid stale variants

- **Best practice for production:**
  - Pin a known release/tag/commit via `COMMUNITY_SCRIPTS_REF`
- **If following `main`:**
  - Update/sync local checkout regularly (fetch/rebase or merge)
  - Watch for drift warnings during installation flow

### Symptom: "Failed to load core.func" / "Failed to download tools.func"

Check:

1. Local files exist in one of the expected locations:
   - script directory (`$(dirname "${BASH_SOURCE[0]}")`)
   - `/opt/community-scripts/misc`
   - `/usr/local/share/community-scripts/misc`
   - `/usr/local/community-scripts/misc`
2. Remote base URLs are reachable
3. `COMMUNITY_SCRIPTS_REF` points to a valid branch/tag/commit

### Symptom: CT `update` script points to unexpected source

Check:

- `COMMUNITY_SCRIPTS_CT_BASE`
- `COMMUNITY_SCRIPTS_REF`

---

## Security and reproducibility notes

- For production-grade reproducibility, prefer **pinning** (`COMMUNITY_SCRIPTS_REF` as tag/commit)
- For highest control, use internal mirrors with explicit base URLs
- Local-first loading reduces runtime dependence on external services

---

## Summary

You now have a safer runtime model:

- **Resilient**: local-first
- **Flexible**: configurable remote bases
- **Reproducible**: ref pinning

Use defaults for simplicity, pin refs for stability, and override bases for enterprise/mirrored deployments.
