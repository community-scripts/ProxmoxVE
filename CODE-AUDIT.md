<div align="center">
<img src="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/images/logo.png" height="100px" />
</div>
<h2><div align="center">Exploring the Scripts and Steps Involved in an Application LXC Installation</div></h2>

1) [adguard.sh](https://github.com/community-scripts/ProxmoxVE/blob/main/ct/adguard.sh): This script collects system parameters. (Also holds the function to update the application.)
2) [build.func](https://github.com/community-scripts/ProxmoxVE/blob/main/misc/build.func): Adds user settings and integrates collected information.
3) [create_lxc.sh](https://github.com/community-scripts/ProxmoxVE/blob/main/ct/create_lxc.sh): Constructs the LXC container.
4) [adguard-install.sh](https://github.com/community-scripts/ProxmoxVE/blob/main/install/adguard-install.sh): Executes functions from [install.func](https://github.com/community-scripts/ProxmoxVE/blob/main/misc/install.func), and installs the application.
5) [adguard.sh](https://github.com/community-scripts/ProxmoxVE/blob/main/ct/adguard.sh) (again): To display the completion message.

The installation process uses reusable scripts: [build.func](https://github.com/community-scripts/ProxmoxVE/blob/main/misc/build.func), [create_lxc.sh](https://github.com/community-scripts/ProxmoxVE/blob/main/ct/create_lxc.sh), and [install.func](https://github.com/community-scripts/ProxmoxVE/blob/main/misc/install.func), which are not specific to any particular application.

To gain a better understanding, focus on reviewing [adguard-install.sh](https://github.com/community-scripts/ProxmoxVE/blob/main/install/adguard-install.sh). This script contains the commands and configurations for installing and configuring AdGuard Home within the LXC container.
