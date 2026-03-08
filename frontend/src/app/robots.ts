import type { MetadataRoute } from "next";

import { basePath } from "@/config/site-config";

export const dynamic = "force-static";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
    },
    sitemap: `https://community-unscripted.github.io/${basePath}/sitemap.xml`,
  };
}
