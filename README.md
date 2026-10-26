<div align="center">
  <a href="misc/images/community-scripts.svg"><img src="misc/images/community-scripts.png" width="112" height="112" alt="Community Scripts — Proxmox VE logo" /></a>
  <!-- Editable artwork: misc/images/community-scripts.svg; PNG export: 512 × 512. -->

  <h1>Community Scripts — Proxmox VE</h1>
  <p><strong>One-command installations for services, containers and VMs on Proxmox VE</strong><br/>
  A community project — built on the foundation of <a href="https://github.com/tteck">@tteck</a>'s original work</p>

  <p>
    <a href="https://community-scripts.org"><img src="https://img.shields.io/badge/Website-community--scripts.org-4c9b3f?style=flat-square" alt="Website" /></a>
    <a href="https://discord.gg/3AnUqsXnmK"><img src="https://img.shields.io/badge/Discord-Join_us-7289da?style=flat-square&logo=discord&logoColor=white" alt="Discord" /></a>
    <a href="https://github.com/community-scripts/ProxmoxVE/stargazers"><img src="https://img.shields.io/github/stars/community-scripts/ProxmoxVE?style=flat-square&label=Stars&color=f5a623" alt="Stars" /></a>
    <a href="https://github.com/community-scripts/ProxmoxVE/blob/main/CHANGELOG.md"><img src="https://img.shields.io/badge/Changelog-view-6c5ce7?style=flat-square" alt="Changelog" /></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License" /></a>
  </p>
</div>

---

## What is this?

**The canonical application scripts.** More than 600 of them, covering home
automation, media, networking, databases, monitoring, security and developer
tooling. Paste one command into your Proxmox shell and the container or VM is
built, configured and running.

A script only describes *what* to install. Creating the container, asking the
questions and handling the errors is the job of the shared engine in
[core](https://github.com/community-scripts/core), which every script loads at
start-up. The same scripts run unchanged on an Incus host through
[the Incus repository](https://github.com/community-scripts/Incus).

Ready-made commands for every application are on
[community-scripts.org](https://community-scripts.org).

---

## Getting started

1. Go to **[community-scripts.org](https://community-scripts.org)**
2. Search for the service you want — Home Assistant, Nginx Proxy Manager, Jellyfin
3. Copy the one-line install command from the script page
4. Open your **Proxmox shell** and paste it
5. Choose **Default** or **Advanced** and follow the prompts

Each script page lists what the container includes, the default resources and
the post-install notes.

> These commands run as root on your host. Every script is readable in this
> repository, and each script page links to its source — read it before you
> paste it, as you would with any installer.

---

## How scripts work

**Default** picks sensible resources and asks only what it has to. Most installs
finish in a few minutes.

**Advanced** hands you container settings, networking, storage backend and
application options before anything is created.

Every container gets an `update` command. Type it in the container console:

```bash
update
```

It updates the installed application and reaches settings that would otherwise
mean editing config files by hand. VM scripts have no built-in updater — use the
guest's own package manager.

---

## Requirements

| Component | Details |
| --------- | ------- |
| **Proxmox VE** | 8.0 – 8.4, or 9.0 – 9.2 |
| **Access** | Root shell on the Proxmox host |
| **Network** | Internet access during installation |

Virtual machine scripts need the same versions as containers.

---

## Repository map

| Repository | Contains |
| ---------- | -------- |
| [core](https://github.com/community-scripts/core) | The engine — container and VM creation, the wizard, error handling |
| **ProxmoxVE** (this repo) | Canonical application scripts, plus `tools/pve/`, `vm/` and `turnkey/` |
| [Incus](https://github.com/community-scripts/Incus) | The same scripts on an Incus host, plus Incus VMs and host tooling |
| [DevScripts](https://github.com/community-scripts/DevScripts) | Where new scripts are tested before they land here |

---

## Layout

| Folder | Contents |
| ------ | -------- |
| `ct/` | Application scripts — the command you paste |
| `install/` | What each script installs inside the container |
| `vm/` | Virtual machine scripts |
| `tools/pve/` | Host tooling: post-install, hardware passthrough, maintenance |
| `turnkey/` | TurnKey Linux appliance helper |
| `misc/` | Legacy engine copies — current scripts load [core](https://github.com/community-scripts/core) at runtime, so changes here never reach a running install |

Application metadata — name, description, logo, tags — is managed on the website,
not in this repository. Use the **Report Issue** link on any script page to
request a change.

---

## Testing a fork or branch

Engine and scripts resolve independently, so either can point somewhere else.
Put the variable on the command itself — nothing needs exporting.

To run your own copy of the scripts:

```bash
COMMUNITY_SCRIPTS_URL=https://raw.githubusercontent.com/YOU/ProxmoxVE/my-branch \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOU/ProxmoxVE/my-branch/ct/debian.sh)"
```

A `ct/` script fetched with `curl` cannot tell the engine where it came from, so
without that variable it would look for its `install/` half upstream.

Only when you are changing the engine itself:

```bash
COMMUNITY_SCRIPTS_CORE_URL=https://raw.githubusercontent.com/YOU/core/my-branch \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"
```

A local checkout of core wins over both — point at it with
`COMMUNITY_SCRIPTS_CORE_DIR`.

---

## Contributing

This project runs on community contributions. New scripts, fixes, bug reports —
all of it helps.

| I want to… | Go here |
| ---------- | ------- |
| Add a **new** script | [DevScripts](https://github.com/community-scripts/DevScripts) — new scripts are tested there first |
| Fix or improve an **existing** script | [Contributing Guidelines](CONTRIBUTING.md) — open a PR here |
| Change how containers are built | [core](https://github.com/community-scripts/core) |
| Report a bug or a broken script | [Issues](https://github.com/community-scripts/ProxmoxVE/issues) |
| Request a script or a feature | [Discussions](https://github.com/community-scripts/ProxmoxVE/discussions) |
| Report a security vulnerability | [Security Policy](SECURITY.md) |
| Ask a question | [Discord](https://discord.gg/3AnUqsXnmK) |

### Before you open a PR

- **New scripts go to [DevScripts](https://github.com/community-scripts/DevScripts), not here.** PRs adding new scripts to this repository will be closed.
- Keep a PR to one fix or one feature.
- A bug that also happens on Incus is an application or engine bug — say so in the report.
- Read the [Contributing Guidelines](CONTRIBUTING.md) before your first PR.

---

## Core Team

<table align="center">
  <tr>
    <td align="center">
      <a href="https://github.com/MickLesk">
        <img src="https://github.com/MickLesk.png" width="80" height="80" style="border-radius:50%" alt="MickLesk" /><br/>
        <sub><b>MickLesk</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/michelroegl-brunner">
        <img src="https://github.com/michelroegl-brunner.png" width="80" height="80" style="border-radius:50%" alt="michelroegl-brunner" /><br/>
        <sub><b>michelroegl-brunner</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/BramSuurdje">
        <img src="https://github.com/BramSuurdje.png" width="80" height="80" style="border-radius:50%" alt="BramSuurdje" /><br/>
        <sub><b>BramSuurdje</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/CrazyWolf13">
        <img src="https://github.com/CrazyWolf13.png" width="80" height="80" style="border-radius:50%" alt="CrazyWolf13" /><br/>
        <sub><b>CrazyWolf13</b></sub>
      </a>
    </td>
  </tr>
  <tr>
    <td align="center">
      <a href="https://github.com/tremor021">
        <img src="https://github.com/tremor021.png" width="80" height="80" style="border-radius:50%" alt="tremor021" /><br/>
        <sub><b>tremor021</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/vhsdream">
        <img src="https://github.com/vhsdream.png" width="80" height="80" style="border-radius:50%" alt="vhsdream" /><br/>
        <sub><b>vhsdream</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/asylumexp">
        <img src="https://github.com/asylumexp.png" width="80" height="80" style="border-radius:50%" alt="asylumexp" /><br/>
        <sub><b>asylumexp</b></sub>
      </a>
    </td>
    <td></td>
  </tr>
</table>

---

## Project Activity

<p align="center">
  <img
    src="https://repobeats.axiom.co/api/embed/57edde03e00f88d739bdb5b844ff7d07dd079375.svg"
    alt="Repository activity"
    width="700"
  />
</p>

<p align="center">
  <a href="https://www.star-history.com/?repos=community-scripts%2FProxmoxVE&type=date&legend=top-left">
    <picture>
      <source
        media="(prefers-color-scheme: dark)"
        srcset="https://api.star-history.com/chart?repos=community-scripts/ProxmoxVE&type=date&theme=dark&legend=top-left&sealed_token=-lUy2KH6pJryUyLCbiWRwFz3ilXMDFVFHm0lJcqh-Hl5e0QNNKjINNcXzULhaZVpBugN_TDaxOawEAuzwBc5Sjqa2mCRw9K6TdCioKRDsS_qXUwhkLQSCMRSg1schCdl4rQD8qEj7PWBjin-fyHnDm7NnM6akZp59jndG7qV7PrvG8nLBgDIuuA-wAI3"
      />
      <source
        media="(prefers-color-scheme: light)"
        srcset="https://api.star-history.com/chart?repos=community-scripts/ProxmoxVE&type=date&legend=top-left&sealed_token=-lUy2KH6pJryUyLCbiWRwFz3ilXMDFVFHm0lJcqh-Hl5e0QNNKjINNcXzULhaZVpBugN_TDaxOawEAuzwBc5Sjqa2mCRw9K6TdCioKRDsS_qXUwhkLQSCMRSg1schCdl4rQD8qEj7PWBjin-fyHnDm7NnM6akZp59jndG7qV7PrvG8nLBgDIuuA-wAI3"
      />
      <img
        alt="Star History Chart"
        src="https://api.star-history.com/chart?repos=community-scripts/ProxmoxVE&type=date&legend=top-left&sealed_token=-lUy2KH6pJryUyLCbiWRwFz3ilXMDFVFHm0lJcqh-Hl5e0QNNKjINNcXzULhaZVpBugN_TDaxOawEAuzwBc5Sjqa2mCRw9K6TdCioKRDsS_qXUwhkLQSCMRSg1schCdl4rQD8qEj7PWBjin-fyHnDm7NnM6akZp59jndG7qV7PrvG8nLBgDIuuA-wAI3"
        width="700"
      />
    </picture>
  </a>
</p>

---

## Support the Project

This project is maintained by volunteers. Infrastructure costs come out of
pocket and the work happens in people's spare time.

**30% of all donations are forwarded directly to cancer research and hospice
care** — a cause that was important to tteck.

<div align="center">
  <a href="https://ko-fi.com/community_scripts">
    <img src="https://img.shields.io/badge/Support_on_Ko--fi-FF5F5F?style=for-the-badge&logo=ko-fi&logoColor=white" alt="Support on Ko-fi" />
  </a>
  &nbsp;
  <a href="https://community-scripts.org/donate">
    <img src="https://img.shields.io/badge/Donate-community--scripts.org%2Fdonate-4c9b3f?style=for-the-badge" alt="Donate via community-scripts.org" />
  </a>
</div>

---

## License

MIT — free to use, modify and redistribute, for personal and commercial
purposes. See [LICENSE](LICENSE).

---

<div align="center">
  <sub>Built on the foundation of <a href="https://github.com/tteck">tteck</a>'s original work · <a href="https://github.com/tteck/Proxmox">Original Repository</a></sub><br/>
  <sub>Maintained and expanded by the community · In memory of tteck</sub><br/>
  <sub><i>This is an independent community project. <b>Proxmox</b>® is a registered trademark of <a href="https://www.proxmox.com/en/about/company">Proxmox Server Solutions GmbH</a>.</i></sub>
</div>
