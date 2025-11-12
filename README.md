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

</div>

<br />

<div align="center">
  <sub>🙌 <strong>Shoutout to</strong></sub>
  <br />
  <br />
  <a href="https://selfh.st/">
    <img src="https://img.shields.io/badge/selfh.st-Icons_for_Self--Hosted-2563eb?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJNMTIgMkM2LjQ4IDIgMiA2LjQ4IDIgMTJzNC40OCAxMCAxMCAxMCAxMC00LjQ4IDEwLTEwUzE3LjUyIDIgMTIgMnptMCAxOGMtNC40MSAwLTgtMy41OS04LThzMy41OS04IDgtOCA4IDMuNTkgOCA4LTMuNTkgOC04IDh6IiBmaWxsPSJ3aGl0ZSIvPjwvc3ZnPg==&labelColor=1e3a8a" alt="selfh.st Icons" />
  </a>
  <br />
  <sub><a href="https://github.com/selfhst/icons">View on GitHub</a> • Consistent, beautiful icons for 5000+ self-hosted apps</sub>
</div>

---

## 🎯 Key Features

<div align="center">

<table>
  <tr>
    <td align="center" width="25%">
      <h3>⚡ Quick Setup</h3>
      <p>One-command installations for popular services and containers</p>
    </td>
    <td align="center" width="25%">
      <h3>⚙️ Flexible Config</h3>
      <p>Simple mode for beginners, advanced options for power users</p>
    </td>
    <td align="center" width="25%">
      <h3>🔄 Auto Updates</h3>
      <p>Keep your installations current with built-in update mechanisms</p>
    </td>
    <td align="center" width="25%">
      <h3>🛠️ Easy Management</h3>
      <p>Post-install scripts for configuration and troubleshooting</p>
    </td>
  </tr>
  <tr>
    <td align="center" width="25%">
      <h3>👥 Community Driven</h3>
      <p>Actively maintained with contributions from users worldwide</p>
    </td>
    <td align="center" width="25%">
      <h3>📖 Well Documented</h3>
      <p>Comprehensive guides and community support</p>
    </td>
    <td align="center" width="25%">
      <h3>🔒 Secure</h3>
      <p>Regular security updates and best practices</p>
    </td>
    <td align="center" width="25%">
      <h3>⚡ Performance</h3>
      <p>Optimized configurations for best performance</p>
    </td>
  </tr>
</table>

</div>

---

## 📋 Requirements

<div align="center">

<table>
  <tr>
    <td align="center" width="33%">
      <h3>🖥️ Proxmox VE</h3>
      <p>Version 8.4.x or 9.0.x</p>
    </td>
    <td align="center" width="33%">
      <h3>🐧 Operating System</h3>
      <p>Debian-based with Proxmox Tools</p>
    </td>
    <td align="center" width="33%">
      <h3>🌐 Network</h3>
      <p>Internet connection required</p>
    </td>
  </tr>
</table>

</div>

---

## 📥 Getting Started

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

## 💬 Join the Community

<div align="center">

<table>
  <tr>
    <td align="center" width="33%">
      <h3>💬 Discord</h3>
      <p>Real-time chat, support, and discussions</p>
      <a href="https://discord.gg/3AnUqsXnmK">
        <img src="https://img.shields.io/badge/Join-7289da?style=for-the-badge&logo=discord&logoColor=white" alt="Discord" />
      </a>
    </td>
    <td align="center" width="33%">
      <h3>💭 Discussions</h3>
      <p>Feature requests, Q&A, and ideas</p>
      <a href="https://github.com/community-scripts/ProxmoxVE/discussions">
        <img src="https://img.shields.io/badge/Discuss-238636?style=for-the-badge&logo=github&logoColor=white" alt="Discussions" />
      </a>
    </td>
    <td align="center" width="33%">
      <h3>🐛 Issues</h3>
      <p>Bug reports and issue tracking</p>
      <a href="https://github.com/community-scripts/ProxmoxVE/issues">
        <img src="https://img.shields.io/badge/Report-d73a4a?style=for-the-badge&logo=github&logoColor=white" alt="Issues" />
      </a>
    </td>
  </tr>
</table>

</div>

---

## 🛠️ Contribute

<div align="center">

<table>
  <tr>
    <td align="center" width="25%">
      <h3>💻 Code</h3>
      <p>Add new scripts or improve existing ones</p>
    </td>
    <td align="center" width="25%">
      <h3>📝 Documentation</h3>
      <p>Write guides, improve READMEs, translate content</p>
    </td>
    <td align="center" width="25%">
      <h3>🧪 Testing</h3>
      <p>Test scripts and report compatibility issues</p>
    </td>
    <td align="center" width="25%">
      <h3>💡 Ideas</h3>
      <p>Suggest features or workflow improvements</p>
    </td>
  </tr>
</table>

</div>

<div align="center">
  <br />
  
  👉 Check our **[Contributing Guidelines](https://github.com/community-scripts/ProxmoxVE/blob/main/.github/CONTRIBUTOR_AND_GUIDES/CONTRIBUTING.md)** to get started
  
</div>

---

## ❤️ Support the Project

This project is maintained by volunteers in memory of tteck. Your support helps us maintain infrastructure, improve documentation, and give back to important causes.

**🎗️ 30% of all donations go directly to cancer research and hospice care**

<div align="center">

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
