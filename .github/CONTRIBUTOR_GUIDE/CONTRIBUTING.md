
# Community Scripts Contribution Guide

## **Welcome to the communty-scripts Repository!** 
📜 These documents outlines the essential coding standards for all our scripts and JSON files. Adhering to these standards ensures that our codebase remains consistent, readable, and maintainable. By following these guidelines, we can improve collaboration, reduce errors, and enhance the overall quality of our project.

### Why Coding Standards Matter

Coding standards are crucial for several reasons:

1. **Consistency**: Consistent code is easier to read, understand, and maintain. It helps new team members quickly get up to speed and reduces the learning curve.
2. **Readability**: Clear and well-structured code is easier to debug and extend. It allows developers to quickly identify and fix issues.
3. **Maintainability**: Code that follows a standard structure is easier to refactor and update. It ensures that changes can be made with minimal risk of introducing new bugs.
4. **Collaboration**: When everyone follows the same standards, it becomes easier to collaborate on code. It reduces friction and misunderstandings during code reviews and merges.

### Scope of These Documents

These documents covers the coding standards for the following types of files in our project:

- **`APP-install.sh` Scripts**: These scripts are responsible for the installation of applications and are located in the `/install` directory.
- **`APP.sh` Scripts**: These scripts handle the creation and updating of containers and are found in the `/ct` directory.
- **JSON Files**: These files store structured data and are located in the `/json` directory.

Each section provides detailed guidelines on various aspects of coding, including shebang usage, comments, variable naming, function naming, indentation, error handling, command substitution, quoting, script structure, and logging. Additionally, examples are provided to illustrate the application of these standards.

By following the coding standards outlined in this document, we ensure that our scripts and JSON files are of high quality, making our project more robust and easier to manage. Please refer to this guide whenever you create or update scripts and JSON files to maintain a high standard of code quality across the project. 📚🔍

Let's work together to keep our codebase clean, efficient, and maintainable! 💪🚀


## Getting Started

Before contributing, please ensure that you have the following setup:

1. **Visual Studio Code** (recommended for script development)
2. **Recommended VS Code Extensions:**
   - [Shell Syntax](https://marketplace.visualstudio.com/items?itemName=bmalehorn.shell-syntax)
   - [ShellCheck](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck)
   - [Shell Format](https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format)

### Important Notes
- Use [AppName.sh](https://github.com/community-scripts/ProxmoxVE/blob/contributor_guide/.github/CONTRIBUTOR_GUIDE/ct/AppName.sh) and [AppName-install.sh](https://github.com/community-scripts/ProxmoxVE/blob/contributor_guide/.github/CONTRIBUTOR_GUIDE/install/AppName-install.sh) as templates when creating new scripts.
- The call to `community-scripts/ProxmoxVE` should be adjusted to reflect the correct fork URL.

---

# 🚀 The Application Script (ct/AppName.sh)

- You can find all coding standards, as well as the structure for this files [here](https://github.com/community-scripts/ProxmoxVE/blob/contributor_guide/.github/CONTRIBUTOR_GUIDE/ct/AppName.md).
- These Scripts are responsible for container creation, setting the necessary variables and handles the update of the application.

---

# 🛠 The Installation Script (install/AppName-install.sh)

- You can find all coding standards, as well as the structure for this files [here](https://github.com/community-scripts/ProxmoxVE/blob/contributor_guide/.github/CONTRIBUTOR_GUIDE/install/AppName-install.md).
- These scripts are responsible for the installation of the application.

---

## 🚀 Building Your Own Scripts

Start with the [template script](https://github.com/community-scripts/ProxmoxVE/blob/contributor_guide/.github/CONTRIBUTOR_GUIDE/install/AppName-install.sh)

---

## 🤝 Contribution Process

### 1. Fork the Repository
Fork to your GitHub account

### 2. Clone Your Fork on your Pc 
```bash
git clone https://github.com/yourUserName/ForkName
```

### 3. Create a New Branch
```bash
git switch -c your-feature-branch
```

### 4. Change Paths in build.func install.func and AppName.sh
You need to switch `https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main` to `https://raw.githubusercontent.com/[USER]/[REPOSITORY]/refs/head/[BRANCH]` to test your script in your repository. Before opening a Pull Request change all this back to point to the community-scripts Repository.

### 4. Commit Changes (without build.func and install.func!)
```bash
git commit -m "Your commit message"
```

### 5. Push to Your Fork
```bash
git push origin your-feature-branch
```

### 6. Create a Pull Request
Open a PR from your feature branch to the main repository branch. You may only include your **AppName.sh**, **AppName-install.sh** and **AppName.json** files in the pull request.

---

## 📚 Pages

- [Function-Overview](https://github.com/community-scripts/ProxmoxVE/wiki/Function_Overview)
- [CT Template: AppName.sh](https://github.com/community-scripts/ProxmoxVE/blob/contributor_guide/.github/CONTRIBUTOR_GUIDE/ct/AppName.sh)
- [Install Template: AppName-install.sh](https://github.com/community-scripts/ProxmoxVE/blob/contributor_guide/.github/CONTRIBUTOR_GUIDE/install/AppName-install.sh)
- [JSON Template: AppName.json](https://github.com/community-scripts/ProxmoxVE/blob/contributor_guide/.github/CONTRIBUTOR_GUIDE/json/AppName.json)

---

