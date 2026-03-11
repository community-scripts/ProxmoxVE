import { MessagesSquare, Scroll, FolderOpen, FileCode } from "lucide-react";
import { FaDiscord, FaGithub } from "react-icons/fa";
import React from "react";

import type { OperatingSystem } from "@/lib/types";

// eslint-disable-next-line node/no-process-env
export const basePath = process.env.BASE_PATH || "ProxmoxVE";

export const navbarLinks = [
  {
    href: "/scripts",
    event: "Scripts",
    icon: <FileCode className="h-4 w-4" />,
    text: "Scripts",
  },
  {
    href: "/categories",
    event: "Categories",
    icon: <FolderOpen className="h-4 w-4" />,
    text: "Categories",
  },
  {
    href: "/community",
    event: "Community",
    icon: <MessagesSquare className="h-4 w-4" />,
    text: "Community",
    mobileHidden: true,
  },
  {
    href: `https://github.com/Heretek-AI/${basePath}`,
    event: "GitHub",
    icon: <FaGithub className="h-4 w-4" />,
    text: "GitHub",
    external: true,
  },
  {
    href: `https://discord.gg/3AnUqsXnmK`,
    event: "Discord",
    icon: <FaDiscord className="h-4 w-4" />,
    text: "Discord",
    external: true,
  },
  {
    href: `https://github.com/Heretek-AI/${basePath}/blob/main/CHANGELOG.md`,
    event: "Changelog",
    icon: <Scroll className="h-4 w-4" />,
    text: "Changelog",
    mobileHidden: true,
    external: true,
  },
].filter(Boolean) as {
  href: string;
  event: string;
  icon: React.ReactNode;
  text: string;
  mobileHidden?: boolean;
  external?: boolean;
}[];

export const mostPopularScripts = ["post-pve-install", "docker", "homeassistant"];

export const analytics = {
  url: "analytics.bramsuurd.nl",
  token: "f9eee289f931",
};

// Heretek Alert Colors - Rust & Corruption themed
export const AlertColors = {
  warning: "border-rust-500/25 bg-destructive/25",
  info: "border-corruption-400/25 bg-corruption-900/25",
  success: "border-corruption-500/25 bg-corruption-800/25",
  danger: "border-rust-600/25 bg-rust-900/25",
};

export const OperatingSystems: OperatingSystem[] = [
  {
    name: "Debian",
    versions: [
      { name: "12", slug: "bookworm" },
      { name: "13", slug: "trixie" },
    ],
  },
  {
    name: "Ubuntu",
    versions: [
      { name: "22.04", slug: "jammy" },
      { name: "24.04", slug: "noble" },
    ],
  },
];
