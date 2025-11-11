<div align="center">
  <img src="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/images/logo-81x112.png" height="120px" alt="Proxmox VE Helper-Scripts Logo" />
  
  <h1>Proxmox VE Helper-Scripts</h1>
  <p><em>A Community Legacy in Memory of @tteck</em></p>

  <p>
    <a href="https://helper-scripts.com">
      <img src="https://img.shields.io/badge/🌐_Website-Visit-4c9b3f?style=for-the-badge&labelColor=2d3748" alt="Website" />
    </a>
    <a href="https://discord.gg/3AnUqsXnmK">
      <img src="https://img.shields.io/badge/💬_Discord-Join-7289da?style=for-the-badge&labelColor=2d3748" alt="Discord" />
    </a>
    <a href="https://ko-fi.com/community_scripts">
      <img src="https://img.shields.io/badge/❤️_Support-Donate-FF5F5F?style=for-the-badge&labelColor=2d3748" alt="Donate" />
    </a>
  </p>

  <p>
    <a href="https://github.com/community-scripts/ProxmoxVE/blob/main/.github/CONTRIBUTOR_AND_GUIDES/CONTRIBUTING.md">
      <img src="https://img.shields.io/badge/🤝_Contribute-Guidelines-ff4785?style=for-the-badge&labelColor=2d3748" alt="Contribute" />
    </a>
    <a href="https://github.com/community-scripts/ProxmoxVE/blob/main/.github/CONTRIBUTOR_AND_GUIDES/USER_SUBMITTED_GUIDES.md">
      <img src="https://img.shields.io/badge/📚_Guides-Read-0077b5?style=for-the-badge&labelColor=2d3748" alt="Guides" />
    </a>
    <a href="https://github.com/community-scripts/ProxmoxVE/blob/main/CHANGELOG.md">
      <img src="https://img.shields.io/badge/📋_Changelog-View-6c5ce7?style=for-the-badge&labelColor=2d3748" alt="Changelog" />
    </a>
  </p>

  <br />

  > **Simplify your Proxmox VE setup with community-driven automation scripts**  
  > Originally created by tteck, now maintained and expanded by the community

  <br />

  <table>
    <tr>
      <td align="center">
        <sub>🤝 <strong>Proud Partner:</strong></sub>
        <br />
        <br />
        <a href="https://selfh.st/">
          <img src="https://img.shields.io/badge/selfh.st-Icons_for_Self--Hosted_-2563eb?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJNMTIgMkM2LjQ4IDIgMiA2LjQ4IDIgMTJzNC40OCAxMCAxMCAxMCAxMC00LjQ4IDEwLTEwUzE3LjUyIDIgMTIgMnptMCAxOGMtNC40MSAwLTgtMy41OS04LThzMy41OS04IDgtOCA4IDMuNTkgOCA4LTMuNTkgOC04IDh6IiBmaWxsPSJ3aGl0ZSIvPjwvc3ZnPg==&labelColor=1e3a8a" alt="selfh.st Icons" />
        </a>
        <br />
        <sub><a href="https://github.com/selfhst/icons">View on GitHub</a> • Consistent, beautiful icons for 400+ self-hosted apps</sub>
      </td>
    </tr>
  </table>

</div>

---

## 🎯 What We Offer

<table>
  <tr>
    <td align="center" width="33%">
      <h3>🚀 Quick Setup</h3>
      <p>One-command installations for popular services and containers</p>
    </td>
    <td align="center" width="33%">
      <h3>⚙️ Flexible Config</h3>
      <p>Simple mode for beginners, advanced options for power users</p>
    </td>
    <td align="center" width="33%">
      <h3>🔄 Auto Updates</h3>
      <p>Keep your installations current with built-in update mechanisms</p>
    </td>
  </tr>
  <tr>
    <td align="center" width="33%">
      <h3>🛠️ Easy Management</h3>
      <p>Post-install scripts for configuration and troubleshooting</p>
    </td>
    <td align="center" width="33%">
      <h3>👥 Community Driven</h3>
      <p>Actively maintained with contributions from users worldwide</p>
    </td>
    <td align="center" width="33%">
      <h3>📖 Well Documented</h3>
      <p>Comprehensive guides and community support</p>
    </td>
  </tr>
</table>

---

## 📋 Requirements

<div align="center">
  
| Requirement | Details |
|:-----------:|:-------:|
| 🖥️ **Proxmox VE** | Version 8.3.x or 9.0.x |
| 🐧 **Operating System** | Debian-based with Proxmox Tools |
| 🌐 **Network** | Internet connection required |

</div>

---

## 🚀 Installation

Choose your preferred installation method:

### Method 1: One-Click Web Installer

The fastest way to get started:

1. Visit **[helper-scripts.com](https://helper-scripts.com/)** 🌐
2. Search for your desired script (e.g., "Home Assistant", "Docker")
3. Copy the bash command displayed on the script page
4. Open your **Proxmox Shell** and paste the command
5. Press Enter and follow the interactive prompts

### Method 2: PVEScripts-Local

Install a convenient script manager directly in your Proxmox UI:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/pve-scripts-local.sh)"
```

This adds a menu to your Proxmox interface for easy script access without visiting the website.

📖 **Learn more:** [ProxmoxVE-Local Repository](https://github.com/community-scripts/ProxmoxVE-Local)

---

## 🤝 Get Involved

### 💬 Join the Community

<table>
  <tr>
    <td align="center" width="33%">
      <a href="https://discord.gg/3AnUqsXnmK">
        <img src="https://img.shields.io/badge/Discord-Join_Chat-7289da?style=flat-square&logo=discord&logoColor=white" alt="Discord" />
      </a>
      <br />
      <sub>Real-time support & discussions</sub>
    </td>
    <td align="center" width="33%">
      <a href="https://github.com/community-scripts/ProxmoxVE/discussions">
        <img src="https://img.shields.io/badge/Discussions-Share_Ideas-238636?style=flat-square&logo=github&logoColor=white" alt="Discussions" />
      </a>
      <br />
      <sub>Feature requests & Q&A</sub>
    </td>
    <td align="center" width="33%">
      <a href="https://github.com/community-scripts/ProxmoxVE/issues">
        <img src="https://img.shields.io/badge/Issues-Report_Bugs-d73a4a?style=flat-square&logo=github&logoColor=white" alt="Issues" />
      </a>
      <br />
      <sub>Bug reports & tracking</sub>
    </td>
  </tr>
</table>

### 🛠️ Contribute

We welcome all types of contributions:

| Type | How to Help |
|------|-------------|
| 💻 **Code** | Add new scripts or improve existing ones |
| 📝 **Documentation** | Write guides, improve READMEs, translate content |
| 🧪 **Testing** | Test scripts and report compatibility issues |
| 💡 **Ideas** | Suggest features or workflow improvements |

👉 Check our **[Contributing Guidelines](https://github.com/community-scripts/ProxmoxVE/blob/main/.github/CONTRIBUTOR_AND_GUIDES/CONTRIBUTING.md)** to get started.

---

## ❤️ Support the Project

<div align="center">

This project is maintained by volunteers in memory of tteck.  
Your support helps us maintain infrastructure, improve documentation, and give back to important causes.

**🎗️ 30% of all donations go directly to cancer research and hospice care**

<br />

<a href="https://ko-fi.com/community_scripts">
  <img src="https://img.shields.io/badge/☕_Buy_us_a_coffee-Support_on_Ko--fi-FF5F5F?style=for-the-badge&labelColor=2d3748" alt="Support on Ko-fi" />
</a>

<br />
<sub>Every contribution helps keep this project alive and supports meaningful causes</sub>

</div>

---

## 📈 Project Growth

<div align="center">
  <a href="https://star-history.com/#community-scripts/ProxmoxVE&Date">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=community-scripts/ProxmoxVE&type=Date&theme=dark" />
      <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=community-scripts/ProxmoxVE&type=Date" />
      <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=community-scripts/ProxmoxVE&type=Date" />
    </picture>
  </a>
</div>

---

## 📜 License

This project is licensed under the **[MIT License](LICENSE)** - feel free to use, modify, and distribute.

---

<div align="center">
  <sub>Made with ❤️ by the Proxmox community in memory of tteck</sub>
  <br />
  <sub><i>Proxmox® is a registered trademark of <a href="https://www.proxmox.com/en/about/company">Proxmox Server Solutions GmbH</a></i></sub>
</div>
