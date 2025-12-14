import { FileJson, Server } from "lucide-react";
import Link from "next/link";

import { basePath } from "@/config/site-config";
import { cn } from "@/lib/utils";

import { buttonVariants } from "./ui/button";

export default function Footer() {
  return (
    <div className="mt-auto flex w-full justify-between border-border border-t bg-background/40 py-4 backdrop-blur-lg supports-backdrop-blur:bg-background/90">
      <div className="mx-6 flex w-full justify-between text-muted-foreground text-xs sm:text-sm">
        <div className="flex items-center">
          <p>
            Website built by the community. The source code is available on{" "}
            <Link
              href={`https://github.com/community-scripts/${basePath}/tree/main/frontend`}
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
        <div className="hidden sm:flex">
          <Link
            href="/json-editor"
            className={cn(
              buttonVariants({ variant: "link" }),
              "flex items-center gap-2 text-muted-foreground"
            )}
          >
            <FileJson className="h-4 w-4" /> JSON Editor
          </Link>
          <Link
            href="/data"
            className={cn(
              buttonVariants({ variant: "link" }),
              "flex items-center gap-2 text-muted-foreground"
            )}
          >
            <Server className="h-4 w-4" /> API Data
          </Link>
        </div>
      </div>
    </div>
  );
}
