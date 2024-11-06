import type { MetadataRoute } from "next";
import { headers } from "next/headers";

export const dynamic = "force-static";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const headersList = await headers();
  let domain = headersList.get("host") as string;
  let protocol = "https";
  return [
    {
      url: `${protocol}://${domain}/${process.env.BASE_PATH}`,
      lastModified: new Date(),
    },
    {
      url: `${protocol}://${domain}/${process.env.BASE_PATH}/scripts`,
      lastModified: new Date(),
    },
  ];
}
