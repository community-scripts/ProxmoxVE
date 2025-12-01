# API Integration Documentation (/api)

This directory contains comprehensive documentation for API integration and the `/api` directory.

## Overview

The `/api` directory contains the Proxmox Community Scripts API backend for diagnostic reporting, telemetry, and analytics integration.

## Key Components

### Main API Service
Located in `/api/main.go`:
- RESTful API for receiving telemetry data
- Installation statistics tracking
- Error reporting and analytics
- Performance monitoring

### Integration with Scripts
The API is integrated into all installation scripts via `api.func`:
- Sends installation start/completion events
- Reports errors and exit codes
- Collects anonymous usage statistics
- Enables project analytics

## Documentation Structure

API documentation covers:
- API endpoint specifications
- Integration methods
- Data formats and schemas
- Error handling
- Privacy and data handling

## Key Resources

- **[misc/api.func/](../misc/api.func/)** - API function library documentation
- **[misc/api.func/README.md](../misc/api.func/README.md)** - Quick reference
- **[misc/api.func/API_FUNCTIONS_REFERENCE.md](../misc/api.func/API_FUNCTIONS_REFERENCE.md)** - Complete function reference

## API Functions

The `api.func` library provides:

### `post_to_api()`
Send container installation data to API.

**Usage**:
```bash
post_to_api CTID STATUS APP_NAME
```

### `post_update_to_api()`
Report application update status.

**Usage**:
```bash
post_update_to_api CTID APP_NAME VERSION
```

### `get_error_description()`
Get human-readable error description from exit code.

**Usage**:
```bash
ERROR_DESC=$(get_error_description EXIT_CODE)
```

## API Integration Points

### In Container Creation (`ct/AppName.sh`)
- Called by build.func to report container creation
- Sends initial container setup data
- Reports success or failure

### In Installation Scripts (`install/appname-install.sh`)
- Called at start of installation
- Called on installation completion
- Called on error conditions

### Data Collected
- Container/VM ID
- Application name and version
- Installation duration
- Success/failure status
- Error codes (if failure)
- Anonymous usage metrics

## Privacy

All API data:
- ✅ Anonymous (no personal data)
- ✅ Aggregated for statistics
- ✅ Used only for project improvement
- ✅ No tracking of user identities
- ✅ Can be disabled if desired

## API Architecture

```
Installation Scripts
    │
    ├─ Call: api.func functions
    │
    └─ POST to: https://api.community-scripts.org
                │
                ├─ Receives data
                ├─ Validates format
                ├─ Stores metrics
                └─ Aggregates statistics
                    │
                    └─ Used for:
                       ├─ Download tracking
                       ├─ Error trending
                       ├─ Feature usage stats
                       └─ Project health monitoring
```

## Common API Tasks

- **Enable API reporting** → Built-in by default, no configuration needed
- **Disable API** → Set `api_disable="yes"` before running
- **View API data** → Visit https://community-scripts.org/stats
- **Report API errors** → [GitHub Issues](https://github.com/community-scripts/ProxmoxVE/issues)

## Debugging API Issues

If API calls fail:
1. Check internet connectivity
2. Verify API endpoint availability
3. Review error codes in [EXIT_CODES.md](../EXIT_CODES.md)
4. Check API function logs
5. Report issues on GitHub

## API Endpoint

**Base URL**: `https://api.community-scripts.org`

**Endpoints**:
- `POST /install` - Report container installation
- `POST /update` - Report application update
- `GET /stats` - Public statistics

---

**Last Updated**: December 2025
**Maintainers**: community-scripts team
