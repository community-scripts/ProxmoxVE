import { basePath } from "@/config/siteConfig";
import type { MetadataRoute } from "next";

export const dynamic = "force-static";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  let domain = "community-scripts.github.io";
  let protocol = "https";
  return [
    {
      url: `${protocol}://${domain}/${basePath}`,
      lastModified: new Date(),
    },
    {
      url: `${protocol}://${domain}/${basePath}/scripts`,
      lastModified: new Date(),
    },
    {
      url: `${protocol}://${domain}/${basePath}/json-editor`,
      lastModified: new Date(),
    }
  ];
}
