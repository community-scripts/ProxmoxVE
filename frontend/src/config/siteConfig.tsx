import { MessagesSquare, Scroll } from "lucide-react";
import { FaGithub } from "react-icons/fa";

export const navbarLinks = [
  {
    href: "https://github.com/community-scripts/ProxmoxVE",
    event: "Github",
    icon: <FaGithub className="h-4 w-4" />,
    text: "Github",
  },
  {
    href: "https://github.com/community-scripts/ProxmoxVE/blob/main/CHANGELOG.md",
    event: "Change Log",
    icon: <Scroll className="h-4 w-4" />,
    text: "Change Log",
  },
  {
    href: "https://github.com/community-scripts/ProxmoxVE/discussions",
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