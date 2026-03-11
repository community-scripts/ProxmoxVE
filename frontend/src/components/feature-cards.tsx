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
          <Card className="h-full transition-all hover:border-primary/50 hover:shadow-md">
            <CardHeader>
              <div className="mb-2 text-primary">{feature.icon}</div>
              <CardTitle className="text-lg">{feature.title}</CardTitle>
            </CardHeader>
            <CardContent>
              <CardDescription>{feature.description}</CardDescription>
            </CardContent>
          </Card>
        </Link>
      ))}
    </div>
  );
}
