# Security Policy

## Supported Versions

This project currently supports the following versions of Proxmox VE (PVE):

| Version | Supported          |
| ------- | ------------------ |
| 9.0.x   | :white_check_mark: |
| 8.4.x   | :white_check_mark: |
| 8.3.x   | Limited support* ❕ |
| 8.2.x   | Limited support* ❕ |
| 8.1.x   | Limited support* ❕ |
| 8.0.x   | Limited support* ❕ |
| < 8.0   | :x:                |

*Version 8.0.x  - 8.3.x has limited support. Security updates may not be provided for all issues affecting this version. 

*Debian 13 Containers may fail to install. You can write var_version=12 before the bash call. 

---

## Reporting a Vulnerability

Security vulnerabilities must not be reported publicly to avoid potential exploitation.  
Instead, please report them privately via one of the following channels:

- **Discord**: Join our [Discord server](https://discord.gg/jsYVk5JBxq) and send a direct message to a maintainer.  
- **Email**: Write to us at **contact@community-scripts.org** with the subject line:  
  `Vulnerability Report - <Project/Script Name>`.

When reporting a vulnerability, please provide:

- A clear description of the issue  
- Steps to reproduce the vulnerability  
- Affected versions or environments  
- (Optional) Suggested fixes or workarounds  

---

## Response Process

1. **Acknowledgment**  
   - We will review and acknowledge your report within **7 business days**.

2. **Assessment**  
   - The maintainers will verify the issue and classify its severity.  
   - Depending on impact, a patch may be released immediately or scheduled for the next update.

3. **Resolution**  
   - Critical security fixes will be prioritized.  
   - Non-critical issues may be deferred or declined with an explanation.

---

## Disclaimer

Not all reported issues will be treated as vulnerabilities.  
Reports may be declined if they are deemed:  
- Low-risk  
- Out of project scope  
- Conflicting with intended design or architecture  

---

If you have any questions or concerns about this security policy, please reach out to the maintainers through the contact options above.
