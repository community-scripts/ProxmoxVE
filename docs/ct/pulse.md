# Pulse - Proxmox Monitoring Dashboard

Pulse is a modern, lightweight monitoring dashboard specifically designed for Proxmox Virtual Environment (PVE). It provides a clean, user-friendly interface for monitoring your Proxmox cluster's health, resource usage, and virtual machine/container status in real time.

![Pulse Dashboard](https://raw.githubusercontent.com/rcourtman/pulse/main/docs/images/dashboard.png)

## Features

- **Real-time Monitoring**: View live statistics and metrics from your Proxmox nodes
- **Multi-Node Support**: Monitor multiple Proxmox nodes from a single dashboard
- **Resource Visualization**: Interactive graphs for CPU, memory, storage, and network usage
- **VM/CT Overview**: Status and resource allocation overview for all virtual machines and containers
- **Demo Mode**: Built-in demo data allows exploring the interface without connecting to a real Proxmox server
- **Mobile Responsive**: Access your monitoring dashboard from any device
- **Lightweight**: Minimal resource footprint, perfect for running in an LXC container

## Installation

You can install Pulse using the community scripts installation command:

```bash
bash -c "$(curl -s https://raw.githubusercontent.com/rcourtman/ProxmoxVE/main/ct/pulse.sh)"
```

The installation script will:

1. Create a new Debian 12 LXC container
2. Install Node.js and necessary dependencies
3. Download and install Pulse
4. Configure services for automatic startup
5. Start the Pulse monitoring dashboard

### Default Settings

- **CPU**: 1 core
- **RAM**: 1024 MB
- **Disk**: 2 GB
- **OS**: Debian 12
- **Network**: DHCP, standard network bridge

## Usage

After installation, Pulse starts in demo mode, showing sample data to help you explore the interface. 

### Accessing the Dashboard

Access the dashboard in your web browser using:

```
http://YOUR_CONTAINER_IP:7654
```

### Connecting to Proxmox

To connect to your actual Proxmox server(s):

1. SSH into your Proxmox host and execute:
   ```
   pct exec YOUR_CONTAINER_ID -- bash -c "nano /opt/pulse/.env"
   ```

2. Update the following settings:
   - Set `USE_MOCK_DATA=false`
   - Set `MOCK_DATA_ENABLED=false`
   - Configure your Proxmox credentials:
     ```
     PROXMOX_NODE_1_NAME=your-node-name
     PROXMOX_NODE_1_HOST=https://your-proxmox-ip:8006
     PROXMOX_NODE_1_TOKEN_ID=your-token-id
     PROXMOX_NODE_1_TOKEN_SECRET=your-token-secret
     ```

3. Save the file and restart the service:
   ```
   pct exec YOUR_CONTAINER_ID -- bash -c "systemctl restart pulse"
   ```

### API Tokens

For security, Pulse uses API tokens to connect to your Proxmox server instead of username/password. To create an API token:

1. In the Proxmox web interface, go to Datacenter → Permissions → API Tokens
2. Click "Add" and create a token for a user with appropriate privileges
3. Use the Token ID and Secret in your Pulse configuration

## Updating

To update Pulse in the future, run:

```
pct exec YOUR_CONTAINER_ID -- bash -c "update"
```

## Troubleshooting

### Locale Warnings
You may see locale warnings during installation. These are expected and don't affect functionality.

### Connection Issues
If you cannot connect to your Proxmox server:
1. Verify your API token has the correct permissions
2. Check that Proxmox is accessible from the container
3. For self-signed certificates, ensure `IGNORE_SSL_ERRORS=true` is set in the .env file

## More Information

- **Source Code**: [GitHub Repository](https://github.com/rcourtman/pulse)
- **Issues**: [GitHub Issues](https://github.com/rcourtman/pulse/issues)
- **Updates**: [GitHub Releases](https://github.com/rcourtman/pulse/releases) 