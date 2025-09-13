import type { MetadataRoute } from "next";

import { basePath } from "@/config/site-config";

export function generateStaticParams() {
  return [];
}

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Proxmox VE Helper-Scripts",
    short_name: "Proxmox VE Helper-Scripts",
    description:
      "A redesigned front-end for the Proxmox VE Helper-Scripts repository. Featuring over 300+ scripts to help you manage your Proxmox Virtual Environment.",
    theme_color: "#030712",
    background_color: "#030712",
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
