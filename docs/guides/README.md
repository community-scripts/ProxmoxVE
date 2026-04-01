# Configuration & Deployment Guides

This directory contains comprehensive guides for configuring and deploying Proxmox VE containers using community-scripts.

## 📚 Available Guides

### [Configuration Reference](CONFIGURATION_REFERENCE.md)

Complete reference for all configuration options, environment variables, and advanced settings available in the build system.

**Topics covered:**

- Container specifications (CPU, RAM, Disk)
- Network configuration (IPv4/IPv6, VLAN, MTU)
- Storage selection and management
- Privilege modes and features
- OS selection and versions

### [Defaults System Guide](DEFAULTS_SYSTEM_GUIDE.md)

Understanding and customizing default settings for container deployments.

**Topics covered:**

- Default system settings
- Per-script overrides
- Custom defaults configuration
- Environment variable precedence

### [Unattended Deployments](UNATTENDED_DEPLOYMENTS.md)

Automating container deployments without user interaction.

**Topics covered:**

- Environment variable configuration
- Batch deployments
- CI/CD integration
- Scripted installations
- Pre-configured templates

### [Core Runtime Sourcing Guide](CORE_RUNTIME_SOURCING_GUIDE.md)

How local-first loading, remote fallback, and ref/base pinning work for core runtime modules.

**Topics covered:**

- Local-first module resolution (`misc/*.func`)
- Branch/tag/commit pinning with `COMMUNITY_SCRIPTS_REF`
- Custom remote base URLs (`COMMUNITY_SCRIPTS_REMOTE_BASE`, `COMMUNITY_SCRIPTS_INSTALL_BASE`, `COMMUNITY_SCRIPTS_CT_BASE`)
- CT update behavior (`/usr/bin/update` source resolution)
- Production hardening and troubleshooting

## 🔗 Related Documentation

- **[CT Scripts Guide](../ct/)** - Container script structure and usage
- **[Install Scripts Guide](../install/)** - Installation script internals
- **[API Documentation](../api/)** - API integration and endpoints
- **[Build Functions](../misc/build.func/)** - Build system functions reference
- **[Tools Functions](../misc/tools.func/)** - Utility functions reference

## 💡 Quick Start

For most users, start with the **Unattended Deployments** guide to learn how to automate your container setups.

For advanced configuration options, refer to the **Configuration Reference**.

For runtime source hardening and pinning, read the **Core Runtime Sourcing Guide**.

## 🤝 Contributing

If you'd like to improve these guides or add new ones, please see our [Contribution Guide](../contribution/).
