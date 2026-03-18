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
      {features.map((feature) => (
        <Link
          key={feature.title}
          href={feature.href}
          target={feature.external ? "_blank" : undefined}
          rel={feature.external ? "noopener noreferrer" : undefined}
          className="group"
        >
          <Card className="h-full transition-all duration-300 hover:border-blood-500/60 hover:shadow-lg hover:shadow-blood-500/20 heretek-card glitch relative overflow-hidden">
            {/* Glitch overlay on hover */}
            <div className="absolute inset-0 bg-gradient-to-r from-blood-500/5 via-transparent to-blood-500/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />

            {/* Scan line effect */}
            <div className="absolute inset-0 pointer-events-none opacity-0 group-hover:opacity-100 transition-opacity duration-300">
              <div className="absolute inset-0 bg-gradient-to-b from-transparent via-blood-500/5 to-transparent animate-scan-line" />
            </div>

            <CardHeader className="relative z-10">
              <div className="mb-2 text-blood-400 group-hover:text-blood-300 transition-colors duration-300 group-hover:animate-heretic-glow">
                {feature.icon}
              </div>
              <CardTitle className="text-lg font-[family-name:var(--font-cinzel)] group-hover:text-blood-400 transition-colors duration-300 relative">
                <span className="relative inline-block">
                  {feature.title}
                  {/* Underline glitch effect */}
                  <span className="absolute bottom-0 left-0 w-full h-px bg-gradient-to-r from-transparent via-blood-500 to-transparent transform scale-x-0 group-hover:scale-x-100 transition-transform duration-300" />
                </span>
              </CardTitle>
            </CardHeader>
            <CardContent className="relative z-10">
              <CardDescription className="text-muted-foreground group-hover:text-foreground/80 transition-colors duration-300">
                {feature.description}
              </CardDescription>
            </CardContent>

            {/* Corner accent */}
            <div className="absolute top-0 right-0 w-8 h-8 overflow-hidden">
              <div className="absolute top-0 right-0 w-16 h-16 bg-gradient-to-br from-blood-500/20 to-transparent transform rotate-45 translate-x-8 -translate-y-8 group-hover:translate-x-4 group-hover:-translate-y-4 transition-transform duration-300" />
            </div>
          </Card>
        </Link>
      ))}
    </div>
  );
}
