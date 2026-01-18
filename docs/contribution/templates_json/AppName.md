# JSON Metadata Files - Quick Reference

The metadata file (`config/myapp.json`) tells the web interface how to display your application.

---

## Quick Start

**Use the JSON Generator Tool:**
[https://community-scripts.github.io/ProxmoxVE/json-editor](https://community-scripts.github.io/ProxmoxVE/json-editor)

1. Enter application details
2. Generator creates `config/myapp.json`
3. Copy the output to your contribution

---

## File Structure

```json
{
  "name": "MyApp",
  "slug": "myapp",
  "categories": ["utilities", "monitoring"],
  "date_created": "2025-01-15",
  "type": "ct",
  "interface_port": "3000",
  "logo": "https://example.com/logo.png",
  "config_path": "/etc/myapp/config.json",
  "description": "Brief description of what MyApp does",
  "install_methods": {
    "1": {
      "type": "ct",
      "resources": {
        "cpu": "2",
        "ram": "2048",
        "disk": "10"
      },
      "pre_install_msg": "Optional message shown before installation"
    }
  },
  "default_credentials": {
    "username": "admin",
    "password": "Generated during install"
  },
  "notes": "Optional setup notes",
  "notes_type": "markdown"
}
```

---

## Field Reference

| Field                 | Required | Example                  | Notes                                          |
| --------------------- | -------- | ------------------------ | ---------------------------------------------- |
| `name`                | Yes      | "MyApp"                  | Display name                                   |
| `slug`                | Yes      | "myapp"                  | URL-friendly identifier (lowercase, no spaces) |
| `categories`          | Yes      | ["utilities"]            | One or more from available list                |
| `date_created`        | Yes      | "2025-01-15"             | Format: YYYY-MM-DD                             |
| `type`                | Yes      | "ct"                     | Container type: "ct" or "vm"                   |
| `interface_port`      | Yes      | "3000"                   | Default web interface port                     |
| `logo`                | No       | "https://..."            | Logo URL (64px x 64px PNG)                     |
| `config_path`         | Yes      | "/etc/myapp/config.json" | Main config file location                      |
| `description`         | Yes      | "App description"        | Brief description (100 chars)                  |
| `install_methods`     | Yes      | See below                | Installation resources                         |
| `default_credentials` | No       | See below                | Optional default login                         |
| `notes`               | No       | "Setup info"             | Additional notes                               |
| `notes_type`          | No       | "markdown"               | Format of notes field                          |

---

## Install Methods

Each installation method specifies resource requirements:

```json
"install_methods": {
  "1": {
    "type": "ct",
    "resources": {
      "cpu": "2",
      "ram": "2048",
      "disk": "10"
    },
    "pre_install_msg": "Optional message"
  }
}
```

**Resource Defaults:**

- CPU: Cores (1-8)
- RAM: Megabytes (256-4096)
- Disk: Gigabytes (4-50)

---

## Common Categories

- `utilities` - Tools and utilities
- `monitoring` - Monitoring/logging
- `media` - Media servers
- `databases` - Database systems
- `communication` - Chat/messaging
- `smart-home` - Home automation
- `development` - Dev tools
- `security` - Security tools
- `storage` - File storage

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

- [config/trip.json](https://github.com/community-scripts/ProxmoxVE/blob/main/config/trip.json)
- [config/thingsboard.json](https://github.com/community-scripts/ProxmoxVE/blob/main/config/thingsboard.json)
- [config/unifi.json](https://github.com/community-scripts/ProxmoxVE/blob/main/config/unifi.json)

---

## Need Help?

- **[JSON Generator](https://community-scripts.github.io/ProxmoxVE/json-editor)** - Interactive tool
- **[README.md](../README.md)** - Full contribution workflow
- **[Quick Start](../README.md)** - Step-by-step guide
