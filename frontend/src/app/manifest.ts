import { basePath } from "@/config/siteConfig";
import type { MetadataRoute } from "next";

export const generateStaticParams = () => {
  return [];
};

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Incus Helper Scripts",
    short_name: "Incus Helper Scripts",
    description:
      "A Front-end for the Incus Helper Scripts Repository. Featuring over 200+ scripts to help you manage your Incus deployment.",
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
