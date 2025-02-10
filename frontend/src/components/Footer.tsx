import { basePath } from "@/config/siteConfig";
import Link from "next/link";
import { FileJson, Server, ExternalLink } from "lucide-react";
import { buttonVariants } from "./ui/button";
import { cn } from "@/lib/utils";

export default function Footer() {
  return (
    <div className="supports-backdrop-blur:bg-background/90 mt-auto border-t w-full flex justify-between border-border bg-background/40 py-6 backdrop-blur-lg">
      <div className="mx-6 w-full flex justify-between text-xs sm:text-sm text-muted-foreground">
        <div className="flex items-center">
          <p>
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
          </p>
        </div>
        <div className="sm:flex hidden">
          <Link
            href="/json-editor"
            className={cn(buttonVariants({ variant: "link" }), "text-muted-foreground flex items-center gap-2")}
          >
            <FileJson className="h-4 w-4" /> JSON Editor
          </Link>
          <Link
            href="/data"
            className={cn(buttonVariants({ variant: "link" }), "text-muted-foreground flex items-center gap-2")}
          >
            <Server className="h-4 w-4" /> API Data
          </Link>
        </div>
      </div>
    </div>
  );
}
