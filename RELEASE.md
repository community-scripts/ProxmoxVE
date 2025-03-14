# Pulse Deployment Release Guide

This document outlines the key requirements for creating new releases of the Pulse installation scripts and ensuring they work correctly with the Pulse application releases.

## Release Criteria

Create script releases for:
- New script features or improvements
- Bug fixes in installation process
- Changes to support new Pulse application features
- Security enhancements
- Performance improvements

## Release Requirements

### Script Version Consistency

Ensure version references are updated in:
- `ct/pulse.sh`
- `install/pulse-install.sh`

### Application Distribution Package

For each Pulse application release:
- Create a distribution package (tar.gz) containing only production files
- Include compiled server code, built frontend assets, and production dependencies
- Include configuration templates (.env.example)
- Include version information file
- Exclude development dependencies, source maps, and build artifacts
- Upload package with GitHub release

### Installation Script Updates

When updating scripts to use a new Pulse release:
- Update version references to point to the latest release
- Update configuration templates if needed
- Test installation in clean container environments

### CHANGELOG Generation

- Review ALL commits since the last release tag
- Use `git log <last-tag>..HEAD --oneline` to see changes
- Document all significant changes, organized by type:
  - Added: New features
  - Changed: Changes to existing functionality
  - Fixed: Bug fixes
  - Security: Security improvements

### Git Requirements

- Commit changes with descriptive messages using prefixes:
  - FIX: Bug fixes
  - ENHANCE: Improvements to existing features
  - FEATURE: New features
  - SECURITY: Security-related changes
- Create and push a version tag when appropriate

### Pre-Release Validation

- Test scripts on clean Proxmox environments
- Verify scripts can download and install distribution packages
- Ensure all services start correctly
- Verify the application is accessible after installation
- Check update functionality works correctly

## Distribution Package Structure

The expected structure of the Pulse distribution package:
- Server-side compiled JavaScript
- Frontend built assets
- Production-only node_modules
- Configuration templates
- License and documentation files
- Version information

## Common Issues

### Download/Installation Problems

- Ensure URLs are correct in scripts
- Check file permissions in distribution packages
- Verify network connectivity from container to GitHub

### Service Startup Issues

- Check logs with `systemctl status pulse`
- Ensure dependencies are properly installed
- Verify configuration files are properly set up

### Command Pager Issues

For commands that invoke a pager, append `| cat` to avoid interactive pager issues:
```
git log | cat
systemctl status pulse | cat
``` 