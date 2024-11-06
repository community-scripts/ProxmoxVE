import { basePath } from "@/config/siteConfig";
import type { MetadataRoute } from "next";
import { headers } from "next/headers";

export const dynamic = "force-static";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const headersList = await headers();
  let domain = headersList.get("host") as string;
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
  ];
}
