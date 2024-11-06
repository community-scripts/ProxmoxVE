import { Button } from "@/components/ui/button";
import { Script } from "@/lib/types";
import { BookOpenText, Code, ExternalLink, Globe } from "lucide-react";
import Link from "next/link";
import { useMemo } from "react";

export default function Buttons({ item }: { item: Script }) {
  const pattern = useMemo(
    () =>
      /(https:\/\/github\.com\/community-scripts\/ProxmoxVE\/raw\/main\/(ct|misc|vm)\/([^\/]+)\.sh)/,
    [],
  );

    const transformUrlToInstallScript = (url: string): string => {
      if (url.includes("/pve/")) {
        return url;
      } else if (url.includes("/ct/")) {
        return url.replace("/ct/", "/install/").replace(/\.sh$/, "-install.sh");
      }
      return url;
    };

  const sourceUrl = useMemo(() => {
    if (item.install_methods[0]?.script) {
      const match = item.install_methods[0].script.match(pattern);
      return match ? transformUrlToInstallScript(match[0]) : null;
    }
    return null;
  }, [item.install_methods, pattern]);

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
      {item.install_methods[0]?.script && sourceUrl && (
        <Button variant="secondary" asChild>
          <Link target="_blank" href={transformUrlToInstallScript(sourceUrl)}>
            <span className="flex items-center gap-2">
              <Code className="h-4 w-4" />
              Source Code
            </span>
          </Link>
        </Button>
      )}
    </div>
  );
}
