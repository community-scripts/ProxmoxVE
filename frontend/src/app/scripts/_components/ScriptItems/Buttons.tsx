import { Button } from "@/components/ui/button";
import { basePath } from "@/config/siteConfig";
import { Script } from "@/lib/types";
import { BookOpenText, Code, Globe } from "lucide-react";
import Link from "next/link";

const generateSourceUrl = (slug: string, type: string) => {
  if (type === "ct") {
    return `https://raw.githubusercontent.com/community-scripts/${basePath}/main/install/${slug}-install.sh`;
  } else {
    return `https://raw.githubusercontent.com/community-scripts/${basePath}/main/${type}/${slug}.sh`;
  }
};

export default function Buttons({ item }: { item: Script }) {
  return (
    <div className="flex flex-wrap justify-end gap-2">
      {item.website && (
        <Button variant="secondary" asChild>
          <Link target="_blank" href={item.website}>
            <span className="flex items-center gap-2">
              <Globe className="h-4 w-4" /> Website
            </span>
          </Link>
        </Button>
      )}
      {item.documentation && (
        <Button variant="secondary" asChild>
          <Link target="_blank" href={item.documentation}>
            <span className="flex items-center gap-2">
              <BookOpenText className="h-4 w-4" />
              Documentation
            </span>
          </Link>
        </Button>
      )}
      {
        <Button variant="secondary" asChild>
          <Link target="_blank" href={generateSourceUrl(item.slug, item.type)}>
            <span className="flex items-center gap-2">
              <Code className="h-4 w-4" />
              Source Code
            </span>
          </Link>
        </Button>
      }
    </div>
  );
}
