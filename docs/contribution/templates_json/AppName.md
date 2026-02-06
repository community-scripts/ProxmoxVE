# JSON Metadata Files - Quick Reference

The metadata file (`frontend/public/json/myapp.json`) tells the web interface how to display your application.

---

## Quick Start

**Use the JSON Generator Tool:**
[https://community-scripts.github.io/ProxmoxVE/json-editor](https://community-scripts.github.io/ProxmoxVE/json-editor)

1. Enter application details
2. Generator creates `frontend/public/json/myapp.json`
3. Copy the output to your contribution

---

## File Structure

```json
{
  "name": "MyApp",
  "slug": "myapp",
  "categories": [1],
  "date_created": "2026-01-18",
  "type": "ct",
  "updateable": true,
  "privileged": false,
  "interface_port": 3000,
  "documentation": "https://docs.example.com/",
  "website": "https://example.com/",
  "logo": "https://cdn.jsdelivr.net/gh/selfhst/icons@main/webp/myapp.webp",
  "config_path": "/opt/myapp/.env",
  "description": "Brief description of what MyApp does",
  "install_methods": [
    {
      "type": "default",
      "script": "ct/myapp.sh",
      "resources": {
        "cpu": 2,
        "ram": 2048,
        "hdd": 8,
        "os": "Debian",
        "version": "13"
      }
    }
  ],
  "default_credentials": {
    "username": null,
    "password": null
  },
  "notes": [
    {
      "text": "Change the default password after first login!",
      "type": "warning"
    }
  ]
}
```

---

## Field Reference

| Field                 | Required | Example           | Notes                                          |
| --------------------- | -------- | ----------------- | ---------------------------------------------- |
| `name`                | Yes      | "MyApp"           | Display name                                   |
| `slug`                | Yes      | "myapp"           | URL-friendly identifier (lowercase, no spaces) |
| `categories`          | Yes      | [1]               | One or more category IDs                       |
| `date_created`        | Yes      | "2026-01-18"      | Format: YYYY-MM-DD                             |
| `type`                | Yes      | "ct"              | Container type: "ct" or "vm"                   |
| `interface_port`      | Yes      | 3000              | Default web interface port                     |
| `logo`                | No       | "https://..."     | Logo URL (64px x 64px PNG)                     |
| `config_path`         | Yes      | "/opt/myapp/.env" | Main config file location                      |
| `description`         | Yes      | "App description" | Brief description (100 chars)                  |
| `install_methods`     | Yes      | See below         | Installation resources (array)                 |
| `default_credentials` | No       | See below         | Optional default login                         |
| `notes`               | No       | See below         | Additional notes (array)                       |

---

## Install Methods

Each installation method specifies resource requirements:

```json
"install_methods": [
  {
    "type": "default",
    "script": "ct/myapp.sh",
    "resources": {
      "cpu": 2,
      "ram": 2048,
      "hdd": 8,
      "os": "Debian",
      "version": "13"
    }
  }
]
```

**Resource Defaults:**

- CPU: Cores (1-8)
- RAM: Megabytes (256-4096)
- Disk: Gigabytes (4-50)

---

## Common Categories

- `0` Miscellaneous
- `1` Proxmox & Virtualization
- `2` Operating Systems
- `3` Containers & Docker
- `4` Network & Firewall
- `5` Adblock & DNS
- `6` Authentication & Security
- `7` Backup & Recovery
- `8` Databases
- `9` Monitoring & Analytics
- `10` Dashboards & Frontends
- `11` Files & Downloads
- `12` Documents & Notes
- `13` Media & Streaming
- `14` \*Arr Suite
- `15` NVR & Cameras
- `16` IoT & Smart Home
- `17` ZigBee, Z-Wave & Matter
- `18` MQTT & Messaging
- `19` Automation & Scheduling
- `20` AI / Coding & Dev-Tools
- `21` Webservers & Proxies
- `22` Bots & ChatOps
- `23` Finance & Budgeting
- `24` Gaming & Leisure
- `25` Business & ERP

---

## Best Practices

1. **Use the JSON Generator** - It validates structure
2. **Keep descriptions short** - 100 characters max
3. **Use real resource requirements** - Based on your testing
4. **Include sensible defaults** - Pre-filled in install_methods
5. **Slug must be lowercase** - No spaces, use hyphens

---

## Reference Examples

See actual examples in the repo:

- [frontend/public/json/trip.json](https://github.com/community-scripts/ProxmoxVE/blob/main/frontend/public/json/trip.json)
- [frontend/public/json/thingsboard.json](https://github.com/community-scripts/ProxmoxVE/blob/main/frontend/public/json/thingsboard.json)
- [frontend/public/json/unifi.json](https://github.com/community-scripts/ProxmoxVE/blob/main/frontend/public/json/unifi.json)

---

## Need Help?

- **[JSON Generator](https://community-scripts.github.io/ProxmoxVE/json-editor)** - Interactive tool
- **[README.md](../README.md)** - Full contribution workflow
- **[Quick Start](../README.md)** - Step-by-step guide
