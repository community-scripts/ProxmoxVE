import { basePath } from "@/config/siteConfig";
import Link from "next/link";
import { FileJson, Server, ExternalLink } from "lucide-react";

export default function Footer() {
  return (
    <div className="supports-backdrop-blur:bg-background/90 mt-auto flex border-t border-border bg-background/40 py-6 backdrop-blur-lg">
      <div className="mx-6 w-full max-w-7xl flex justify-between text-xs sm:text-sm text-muted-foreground">
        <div>
          Website built by the community. The source code is available on{" "}
          <Link
            href={`https://github.com/community-scripts/${basePath}`}
            target="_blank"
            rel="noreferrer"
            className="font-semibold underline-offset-2 duration-300 hover:underline"
            data-umami-event="View Website Source Code on Github"
          >
            GitHub
          </Link>
          .
        </div>
        <div className="flex gap-4">
          <Link
            href="/json-editor"
            className="flex items-center gap-2 text-primary hover:underline"
          >
            <FileJson className="h-4 w-4" /> JSON Editor
          </Link>
          <Link
            href="/data"
            className="flex items-center gap-2 text-primary hover:underline"
          >
            <Server className="h-4 w-4" /> API Data
          </Link>
        </div>
      </div>
    </div>
  );
}
