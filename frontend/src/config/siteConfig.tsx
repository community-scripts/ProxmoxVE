import { MessagesSquare, Scroll } from "lucide-react";
import { FaGithub } from "react-icons/fa";

export const basePath = process.env.BASE_PATH;

export const navbarLinks = [
  {
    href: `https://github.com/community-scripts/${basePath}`,
    event: "Github",
    icon: <FaGithub className="h-4 w-4" />,
    text: "Github",
  },
  {
    href: `https://github.com/community-scripts/${basePath}/blob/main/CHANGELOG.md`,
    event: "Change Log",
    icon: <Scroll className="h-4 w-4" />,
    text: "Change Log",
  },
  {
    href: `https://github.com/community-scripts/${basePath}/discussions`,
    event: "Discussions",
    icon: <MessagesSquare className="h-4 w-4" />,
    text: "Discussions",
  },
];

export const mostPopularScripts = [
  "Proxmox VE Post Install",
  "Docker",
  "Home Assistant OS",
];

export const analytics = {
  url: "analytics.proxmoxve-scripts.com",
  token: "b60d3032-1a11-4244-a100-81d26c5c49a7",
};

export const AlertColors = {
  warning:
    "border-yellow-400 bg-yellow-50 dark:border-yellow-900 dark:bg-yellow-900",
  danger: "border-red-500/25 bg-destructive/25",
  info: "border-cyan-500/25 bg-cyan-50 dark:border-cyan-900/25 dark:bg-cyan-900",
};