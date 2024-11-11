# ProjectName Installation and Update Scripts

This repository contains two Bash scripts designed for the automated installation, configuration, and update management of `ProjectName` on Debian-based systems. These scripts handle the setup of dependencies, databases, and service configurations.

## Contents

- [Requirements](#requirements)
- [Installation Steps](#installation-steps)
- [Configuration](#configuration)
- [Script Breakdown](#script-breakdown)

## Requirements

- Debian or Ubuntu (e.g., Debian 12, Ubuntu 24.04)
- User with sudo privileges
- Network connection
- `curl` to fetch external scripts and dependencies

## Installation Steps

To set up `ProjectName`, follow these steps:

1. **Download and prepare the scripts**:
   - Ensure both `template-install.sh` and `template.sh` are downloaded.
   
2. **Edit Configuration** (optional):
   - Modify the default values within the scripts for database names, passwords, or service configurations as required.

3. **Execute the scripts in sequence**:
   - Run the main installation script (template.sh) to install and configure the application.
   - If an update is needed later, execute the update script to ensure the latest version is installed.

## Configuration

The scripts use configurable environment variables to control database settings, project secrets, and local URL configurations. 

### Default Variables Used in Scripts

- `DB_NAME`: Database name for `ProjectName`
- `DB_USER`: Database username
- `DB_PASS`: Auto-generated password for the database
- `PROJECT_SECRET`: Optional project secret key

## Script Breakdown

### 1. Main Installation Script

The main script performs the following tasks:

- **Database Configuration**: Sets up both PostgreSQL and MariaDB, creating necessary databases and users.
- **Dependency Installation**: Installs required dependencies (`curl`, `sudo`, `mc`) and other optional packages for PHP, Node.js, and more.
- **Node.js Repository and Installation**: Adds the Node.js repository, installs Node.js, and includes optional package managers like `yarn` or `pnpm`.
- **Project Setup**: Downloads the latest release of `ProjectName` from GitHub, extracts it, and prepares the environment configuration.
- **Service Creation**: Example services setup is included for popular platforms (e.g., Apache2, Node.js), but adapt as necessary for your environment.
- **Credential Storage**: Credentials are saved to a file (`~/projectname.creds`) for future reference.

### 2. Update Script

The update script is used to:

- **Check for Latest Release**: Fetches the latest release version from GitHub and compares it with the current installed version.
- **Stop and Restart Services**: Gracefully stops the `ProjectName` service before updating and restarts it afterward.
- **Cleanup**: Removes any temporary files or previous version archives.

