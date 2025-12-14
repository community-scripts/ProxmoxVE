export const FAQ_Items = [
  {
    title: "Why do you use tarballs instead of git pull for installation?",
    content:
      "Our LXC scripts install applications using release tarballs. Tarballs contain stable code versions tested for release. Using `git pull` directly fetches the latest development code, which might be unstable or contain bugs. Tarballs offer a more reliable installation.",
  },
  {
    title: "Why do the scripts install applications using HTTP by default?",
    content:
      "Our LXC scripts install applications using HTTP by default. Setting up HTTPS often requires manual configuration specific to your setup, which our automated scripts cannot handle reliably. If an application requires HTTPS, the script will configure it. For others, you need to enable HTTPS yourself, often following the application's official documentation.",
  },
  {
    title: "Where can I find documentation for the installed application?",
    content:
      "We link to the official documentation for each application whenever possible. You can usually find this link on the script's information page for the specific LXC script. If you notice a missing link for an application that has official docs, please report it so we can add it.",
  },
  {
    title: "What should I do if I find a bug in an LXC script?",
    content:
      "Our LXC scripts are maintained by volunteers in their free time. Bugs can occur due to our errors or changes in the applications themselves. If you find a bug in one of our LXC scripts, please report it on our GitHub issues page. Your feedback helps us improve the scripts.",
  },
  {
    title: "Why isn't the application updating to the very latest version?",
    content:
      "Updates via our LXC scripts might not pull the absolute latest version for a few reasons:\n- A bug in the application's release naming on GitHub.\n- A bug in our update script.\n- We intentionally pinned the version. This happens if a newer version has breaking changes or serious bugs that could affect your data or LXC stability. We wait for fixes before allowing the update.",
  },
  {
    title: 'Why am I getting a "502 Bad Gateway" error?',
    content:
      'A "502 Bad Gateway" error usually means the application inside the LXC is not running or responding correctly. Check the application\'s logs first. If you use a reverse proxy, check its logs too. If you still have problems after checking the logs, report the issue, providing details from the logs.',
  },
  {
    title: "What should I do if a script fails during execution?",
    content:
      "If an LXC script fails, run it again using Verbose mode. Standard mode hides detailed output for neatness, showing only progress. Verbose mode displays all messages, which helps you (and us) diagnose the error. Include this verbose output if you report the issue.",
  },
];
