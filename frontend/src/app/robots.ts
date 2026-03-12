import type { MetadataRoute } from "next";

import { basePath } from "@/config/site-config";

export const dynamic = "force-static";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
    },
    sitemap: `https://Heretek-AI.github.io/${basePath}/sitemap.xml`,
  };
}
