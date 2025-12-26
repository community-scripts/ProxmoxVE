# api.func Documentation

## Overview

The `api.func` file provides Proxmox API integration and diagnostic reporting functionality for the Community Scripts project. It handles API communication, error reporting, and status updates to the community-scripts.org API.

## Purpose and Use Cases

- **API Communication**: Send installation and status data to community-scripts.org API
- **Diagnostic Reporting**: Report installation progress and errors for analytics
- **Error Description**: Provide detailed error code explanations
- **Status Updates**: Track installation success/failure status
- **Analytics**: Contribute anonymous usage data for project improvement

## Quick Reference

### Key Function Groups
- **Error Handling**: `get_error_description()` - Convert exit codes to human-readable messages
- **API Communication**: `post_to_api()`, `post_to_api_vm()` - Send installation data
- **Status Updates**: `post_update_to_api()` - Report installation completion status

### Dependencies
- **External**: `curl` command for HTTP requests
- **Internal**: Uses environment variables from other scripts

### Integration Points
- Used by: All installation scripts for diagnostic reporting
- Uses: Environment variables from build.func and other scripts
- Provides: API communication and error reporting services

## Documentation Files

### 📊 [API_FLOWCHART.md](./API_FLOWCHART.md)
Visual execution flows showing API communication processes and error handling.

### 📚 [API_FUNCTIONS_REFERENCE.md](./API_FUNCTIONS_REFERENCE.md)
Complete alphabetical reference of all functions with parameters, dependencies, and usage details.

### 💡 [API_USAGE_EXAMPLES.md](./API_USAGE_EXAMPLES.md)
Practical examples showing how to use API functions and common patterns.

### 🔗 [API_INTEGRATION.md](./API_INTEGRATION.md)
How api.func integrates with other components and provides API services.

## Key Features

### Error Code Descriptions
- **Comprehensive Coverage**: 50+ error codes with detailed explanations
- **LXC-Specific Errors**: Container creation and management errors
- **System Errors**: General system and network errors
- **Signal Errors**: Process termination and signal errors

### API Communication
- **LXC Reporting**: Send LXC container installation data
- **VM Reporting**: Send VM installation data
- **Status Updates**: Report installation success/failure
- **Diagnostic Data**: Anonymous usage analytics

### Diagnostic Integration
- **Optional Reporting**: Only sends data when diagnostics enabled
- **Privacy Respect**: Respects user privacy settings
- **Error Tracking**: Tracks installation errors for improvement
- **Usage Analytics**: Contributes to project statistics

## Common Usage Patterns

### Basic API Setup
```bash
#!/usr/bin/env bash
# Basic API setup

source api.func

# Set up diagnostic reporting
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# Report installation start
post_to_api
```

### Error Reporting
```bash
#!/usr/bin/env bash
source api.func

# Get error description
error_msg=$(get_error_description 127)
echo "Error 127: $error_msg"
# Output: Error 127: Command not found: Incorrect path or missing dependency.
```

### Status Updates
```bash
#!/usr/bin/env bash
source api.func

# Report successful installation
post_update_to_api "success" 0

# Report failed installation
post_update_to_api "failed" 127
```

## Environment Variables

### Required Variables
- `DIAGNOSTICS`: Enable/disable diagnostic reporting ("yes"/"no")
- `RANDOM_UUID`: Unique identifier for tracking

### Optional Variables
- `CT_TYPE`: Container type (1 for LXC, 2 for VM)
- `DISK_SIZE`: Disk size in GB
- `CORE_COUNT`: Number of CPU cores
- `RAM_SIZE`: RAM size in MB
- `var_os`: Operating system type
- `var_version`: OS version
- `DISABLEIP6`: IPv6 disable setting
- `NSAPP`: Namespace application name
- `METHOD`: Installation method

### Internal Variables
- `POST_UPDATE_DONE`: Prevents duplicate status updates
- `API_URL`: Community scripts API endpoint
- `JSON_PAYLOAD`: API request payload
- `RESPONSE`: API response

## Error Code Categories

### General System Errors
- **0-9**: Basic system errors
- **18, 22, 28, 35**: Network and I/O errors
- **56, 60**: TLS/SSL errors
- **125-128**: Command execution errors
- **129-143**: Signal errors
- **152**: Resource limit errors
- **255**: Unknown critical errors

### LXC-Specific Errors
- **100-101**: LXC installation errors
- **200-209**: LXC creation and management errors

### Docker Errors
- **125**: Docker container start errors

## Best Practices

### Diagnostic Reporting
1. Always check if diagnostics are enabled
2. Respect user privacy settings
3. Use unique identifiers for tracking
4. Report both success and failure cases

### Error Handling
1. Use appropriate error codes
2. Provide meaningful error descriptions
3. Handle API communication failures gracefully
4. Don't block installation on API failures

### API Usage
1. Check for curl availability
2. Handle network failures gracefully
3. Use appropriate HTTP methods
4. Include all required data

## Troubleshooting

### Common Issues
1. **API Communication Fails**: Check network connectivity and curl availability
2. **Diagnostics Not Working**: Verify DIAGNOSTICS setting and RANDOM_UUID
3. **Missing Error Descriptions**: Check error code coverage
4. **Duplicate Updates**: POST_UPDATE_DONE prevents duplicates

### Debug Mode
Enable diagnostic reporting for debugging:
```bash
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"
```

### API Testing
Test API communication:
```bash
source api.func
export DIAGNOSTICS="yes"
export RANDOM_UUID="test-$(date +%s)"
post_to_api
```

## Related Documentation

- [core.func](../core.func/) - Core utilities and error handling
- [error_handler.func](../error_handler.func/) - Error handling utilities
- [build.func](../build.func/) - Container creation with API integration
- [tools.func](../tools.func/) - Extended utilities with API integration

---

*This documentation covers the api.func file which provides API communication and diagnostic reporting for all Proxmox Community Scripts.*
