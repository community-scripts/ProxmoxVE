import type { MetadataRoute } from "next";

import { basePath } from "@/config/site-config";

export function generateStaticParams() {
  return [];
}

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Heretek AI",
    short_name: "Heretek AI",
    description:
      "The Heretek AI repository for Proxmox VE Helper-Scripts. Embrace the machine spirit with over 400+ scripts to manage your Proxmox Virtual Environment.",
    theme_color: "#1a1410",
    background_color: "#0d0a08",
    display: "standalone",
    orientation: "portrait",
    scope: `${basePath}`,
    start_url: `${basePath}`,
    icons: [
      {
        src: "logo.png",
        sizes: "512x512",
        type: "image/png",
      },
    ],
  };
}
