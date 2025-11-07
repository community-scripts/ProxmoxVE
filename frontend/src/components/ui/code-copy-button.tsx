"use client";

import { CheckIcon, ClipboardIcon } from "lucide-react";
import { useEffect, useState } from "react";

import { cn } from "@/lib/utils";
import { Card } from "./card";
import handleCopy from "../handle-copy";

type CodeCopyButtonProps = {
  children: React.ReactNode;  // YAML / command
  label?: string;             // teks untuk toast, default "code"
};

export default function CodeCopyButton({
  children,
  label = "code",
}: CodeCopyButtonProps) {
  const [hasCopied, setHasCopied] = useState(false);
  const [isMobile, setIsMobile] = useState(false);

  // deteksi mobile di client
  useEffect(() => {
    if (typeof window !== "undefined") {
      setIsMobile(window.innerWidth <= 640);
    }
  }, []);

  // reset icon setelah 2 detik
  useEffect(() => {
    if (!hasCopied) return;
    const timer = setTimeout(() => setHasCopied(false), 2000);
    return () => clearTimeout(timer);
  }, [hasCopied]);

  const onCopyClick = async () => {
    const value =
      typeof children === "string"
        ? children
        : Array.isArray(children)
          ? children.join("")
          : String(children ?? "");

    await handleCopy(label, value);
    setHasCopied(true);
  };

  return (
    <div className="mt-4">
      <Card className="relative w-full bg-primary-foreground">
        {/* Tombol copy di kanan atas */}
        <button
          type="button"
          className={cn(
            "absolute right-2 top-2 flex items-center justify-center",
            "cursor-pointer rounded-md bg-muted px-2 py-1 text-xs"
          )}
          onClick={onCopyClick}
        >
          {hasCopied ? (
            <CheckIcon className="h-3 w-3" />
          ) : (
            <ClipboardIcon className="h-3 w-3" />
          )}
          <span className="sr-only">Copy</span>
        </button>

        {/* Area kode/YAML */}
        <div className="overflow-x-auto whitespace-pre-wrap break-all text-sm p-4 pr-12">
          {!isMobile && children ? children : "Copy Config File Path"}
        </div>
      </Card>
    </div>
  );
}
