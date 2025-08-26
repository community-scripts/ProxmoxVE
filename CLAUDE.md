# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the **Proxmox VE Helper-Scripts** repository - a collection of tools to simplify the setup and management of Proxmox Virtual Environment (VE). The project was originally created by tteck and is now maintained by the community.

## Architecture Structure

The repository contains several main components:

### Core Script Categories
- **`ct/`**: Container creation scripts (e.g., `ct/jellyfin.sh`) - handles LXC container setup
- **`install/`**: Installation scripts (e.g., `install/jellyfin-install.sh`) - handles application installation within containers
- **`vm/`**: Virtual machine creation scripts for various operating systems
- **`tools/`**: Utility scripts organized by function:
  - `tools/pve/`: Proxmox VE management utilities
  - `tools/addon/`: Additional service installers
  - `tools/copy-data/`: Data migration scripts

### Web Components
- **`frontend/`**: Next.js website with TypeScript/React
- **`api/`**: Go-based API service with MongoDB integration

### Script Infrastructure
- **`misc/`**: Core utility functions and shared libraries:
  - `core.func`: Error handling, formatting, colors, icons
  - `build.func`: Container/VM building utilities
  - `install.func`: Installation helper functions
  - `api.func`: API interaction utilities

## Development Commands

### Frontend Development
```bash
cd frontend/
npm run dev          # Start development server with turbopack
npm run build        # Build for production
npm run lint         # Run ESLint with auto-fix
npm run typecheck    # TypeScript type checking
```

### API Development
```bash
cd api/
go run main.go       # Run the Go API server
go build            # Build the API binary
```

### Script Testing
The repository includes GitHub Actions workflows for script testing and validation. Scripts are automatically tested for syntax and basic functionality.

## Key Conventions

### Script Structure
All scripts follow a standardized format:
- Use `#!/usr/bin/env bash` shebang
- Include copyright header with MIT license
- Load core functions via `source <(curl -s https://...)`
- Follow error handling patterns from `misc/core.func`

### Naming Conventions
- Container scripts: `ct/appname.sh`
- Install scripts: `install/appname-install.sh`
- JSON metadata: `frontend/public/json/appname.json`
- Header files: `ct/headers/appname` and `install/headers/appname`

### Code Quality
- All scripts must pass ShellCheck validation
- Follow the coding standards outlined in `.github/CONTRIBUTOR_AND_GUIDES/CONTRIBUTING.md`
- Use the template files (`AppName.sh`, `AppName-install.sh`) as starting points
- Remove all comments except file headers in final versions

## Working with Scripts

### Common Patterns
1. **Container Creation**: Scripts in `ct/` create LXC containers with specific configurations
2. **Application Installation**: Scripts in `install/` handle software installation and configuration
3. **Function Libraries**: Core utilities are loaded dynamically from `misc/*.func` files
4. **Error Handling**: Standardized error handling with helpful hints via `_tool_error_hint()`

### Testing Scripts
Use the testing infrastructure in `.github/workflows/` for validation. The repository includes:
- Script format validation
- Syntax checking with ShellCheck
- Basic functionality tests

### Security Considerations
- All scripts include security checks and validation
- No sensitive information should be hardcoded
- Follow the security guidelines in `SECURITY.md`
- Report vulnerabilities privately via Discord or email

## Important Notes

- This repository contains defensive security tools and infrastructure scripts
- Scripts are designed for Proxmox VE 8.x environments
- The community maintains both legacy compatibility and modern features
- All contributions must follow the established coding standards and pass automated tests