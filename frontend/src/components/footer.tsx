import { FileJson, Server, FolderOpen, MessageCircle } from "lucide-react";
import Link from "next/link";

import { basePath } from "@/config/site-config";
import { cn } from "@/lib/utils";

import { buttonVariants } from "./ui/button";

export default function Footer() {
  return (
    <div className="supports-backdrop-blur:bg-background/90 mt-auto border-t w-full flex justify-between border-border bg-background/40 py-4 backdrop-blur-lg">
      <div className="mx-6 w-full flex justify-between text-xs sm:text-sm text-muted-foreground">
        <div className="flex items-center">
          <p>
            Website built by the community. The source code is available on
            {" "}
            <Link
              href={`https://github.com/Heretek-AI/${basePath}/tree/main/frontend`}
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
        <div className="sm:flex hidden gap-2">
          <Link
            href="/scripts"
            className={cn(buttonVariants({ variant: "link" }), "text-muted-foreground flex items-center gap-2")}
          >
            <FileJson className="h-4 w-4" />
            Scripts
          </Link>
          <Link
            href="/categories"
            className={cn(buttonVariants({ variant: "link" }), "text-muted-foreground flex items-center gap-2")}
          >
            <FolderOpen className="h-4 w-4" />
            Categories
          </Link>
          <Link
            href="/community"
            className={cn(buttonVariants({ variant: "link" }), "text-muted-foreground flex items-center gap-2")}
          >
            <MessageCircle className="h-4 w-4" />
            Community
          </Link>
          <Link
            href="/json-editor"
            className={cn(buttonVariants({ variant: "link" }), "text-muted-foreground flex items-center gap-2")}
          >
            <FileJson className="h-4 w-4" />
            JSON Editor
          </Link>
          <Link
            href="/data"
            className={cn(buttonVariants({ variant: "link" }), "text-muted-foreground flex items-center gap-2")}
          >
            <Server className="h-4 w-4" />
            API Data
          </Link>
        </div>
      </div>
    </div>
  );
}
