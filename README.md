# Clawdbot for Proxmox VE

An automation tool for managing and automating various tasks in your homelab.

## Quick Install

Run this command in your **Proxmox VE Shell** (not inside a container):

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/clawdbot.sh)"
```

## Default Resources

| Resource | Value |
|----------|-------|
| CPU | 2 cores |
| RAM | 8192 MB |
| Disk | 8 GB |
| OS | Ubuntu 24.04 |

## Requirements

- Proxmox VE 8.x or 9.x
- Internet connection
- Available storage for the container

## Post-Installation

After installation completes, the container will be accessible via the IP address shown in the completion message.

## Documentation

For more information, visit [molt.bot](https://molt.bot/)

## License

This project is licensed under the [MIT License](LICENSE).
