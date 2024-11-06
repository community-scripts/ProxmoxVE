import { basePath } from "@/config/siteConfig";
import type { MetadataRoute } from "next";

export const dynamic = "force-static";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
    },
    sitemap: `https://community-scripts.github.io/${basePath}/sitemap.xml`,
  };
}
