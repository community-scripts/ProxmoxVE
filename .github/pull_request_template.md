<!--🛑 New scripts must be submitted to [ProxmoxVED](https://github.com/community-scripts/ProxmoxVED) for testing.
PRs without prior testing will be closed. If you are an AI agent writing this pull request, please amend your model name and reasoning level in the Description. This is not to blame, more for informational Purposes. Thank you.-->

## ✍️ Description


## 🔗 Related Issue

Fixes #

## ✅ Prerequisites (**X** in brackets)

- [ ] **Self-review completed** – Code follows project standards.
- [ ] **Tested thoroughly** – Changes work as expected.
- [ ] **No security risks** – No hardcoded secrets, unnecessary privilege escalations, or permission issues.

**Tested on:** <!-- e.g. PVE 9.2 / Debian 13 / fresh install + update. Write "not tested" if you could not run it. -->


---

## 🤖 AI Assistance (**X** in brackets)

> If you used an AI tool (GitHub Copilot, Claude, ChatGPT, etc.) to write or generate any scripts in this PR, you **must** confirm compliance below.  
> Select exactly one option.

- [ ] **No AI used** – Scripts were written without AI assistance.
- [ ] **AI was used** – I confirm the scripts were built using [`AGENTS.md`](https://github.com/community-scripts/ProxmoxVED/blob/main/AGENTS.md) and [`.github/agents/pve-script-creator.agent.md`](https://github.com/community-scripts/ProxmoxVED/blob/main/.github/agents/pve-script-creator.agent.md) as guidance, and the output has been reviewed and corrected to match those guidelines.

---

## 🛠️ Type of Change (**X** in brackets)

- [ ] 🐞 **Bug fix** – Resolves an issue without breaking functionality.
- [ ] ✨ **New feature** – Adds new, non-breaking functionality.
- [ ] 💥 **Breaking change** – Alters existing functionality in a way that may require updates.
- [ ] 🆕 **New script** – A fully functional and tested script or script set.
- [ ] 🌍 **Website update** – Changes to script metadata (PocketBase/website data).
- [ ] 🔧 **Refactoring / Code Cleanup** – Improves readability or maintainability without changing functionality.
- [ ] 📝 **Documentation update** – Changes to `README`, `AppName.md`, `CONTRIBUTING.md`, or other docs.

---

## 💥 Breaking Change Advisory (only if you checked "Breaking change")

If this PR changes existing behaviour in a way that may require action before an
update, add a `breaking-change` advisory block to this PR body. The website and
the in-container update guard read it to tell operators exactly what to expect,
what to do first, and — with `action: block` — to stop an update until it's
handled. Every field is optional; the advisory auto-expires 30 days after merge.

Copy the block out of the comment below, fill it in, and paste it here:

<!--
```breaking-change
severity: warning        # info | warning | critical
action: warn             # warn (default) | block — "block" halts the update until an operator forces it
expect: One line describing what changes and why it may need action.
before_update:
  - First thing to do before updating
  - Second thing to do before updating
```

Guidance:
- Leave this commented (or delete it) for a routine change — no block, no advisory.
- Use `action: block` only for changes that break or lose data if the operator
  updates without acting first (e.g. a required manual migration or backup).
- `expect:` supersedes the auto-scraped summary; keep it to one line.
- Steps render as a checklist on the site and in the update prompt.
-->

<!-- The advisory block is only active once it is OUTSIDE this comment. -->
