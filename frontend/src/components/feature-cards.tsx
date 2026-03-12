"use client";

import { FileCode, FolderOpen, LayoutGrid, Scroll } from "lucide-react";
import Link from "next/link";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

const features = [
  {
    title: "All Scripts",
    description: "Browse all available scripts for Proxmox VE",
    icon: <FileCode className="h-6 w-6" />,
    href: "/scripts",
  },
  {
    title: "Categories",
    description: "Explore scripts organized by category",
    icon: <FolderOpen className="h-6 w-6" />,
    href: "/categories",
  },
  {
    title: "Generator",
    description: "Create new script metadata with ease",
    icon: <LayoutGrid className="h-6 w-6" />,
    href: "/json-editor",
  },
  {
    title: "Changelog",
    description: "View recent updates and changes",
    icon: <Scroll className="h-6 w-6" />,
    href: "https://github.com/Heretek-AI/ProxmoxVE/blob/main/CHANGELOG.md",
    external: true,
  },
];

export function FeatureCards() {
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      {features.map(feature => (
        <Link
          key={feature.title}
          href={feature.href}
          target={feature.external ? "_blank" : undefined}
          rel={feature.external ? "noopener noreferrer" : undefined}
          className="group"
        >
          <Card className="h-full transition-all duration-300 hover:border-rust-500/50 hover:shadow-lg hover:shadow-rust-500/10 rust-border">
            <CardHeader>
              <div className="mb-2 text-rust-400 group-hover:text-rust-300 transition-colors duration-300 group-hover:animate-heretic-glow">
                {feature.icon}
              </div>
              <CardTitle className="text-lg font-[family-name:var(--font-cinzel)] group-hover:text-brass-400 transition-colors duration-300">
                {feature.title}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <CardDescription className="text-muted-foreground group-hover:text-foreground/80 transition-colors duration-300">
                {feature.description}
              </CardDescription>
            </CardContent>
          </Card>
        </Link>
      ))}
    </div>
  );
}
