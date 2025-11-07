"use client";

import { CheckIcon, ClipboardIcon } from "lucide-react";
import { useEffect, useState } from "react";

import { cn } from "@/lib/utils";
import { Card } from "./card";

type CodeCopyButtonProps = {
  children: React.ReactNode; // YAML / install command
  label?: string;            // teks untuk jenis copy, default "code"
};

export default function CodeCopyButton({
  children,
  label = "code",
}: CodeCopyButtonProps) {
  const [hasCopied, setHasCopied] = useState(false);
  const [isMobile, setIsMobile] = useState(false);

  // deteksi mobile, hanya di client
  useEffect(() => {
    if (typeof window !== "undefined") {
      setIsMobile(window.innerWidth <= 640);
    }
  }, []);

  useEffect(() => {
    if (!hasCopied) return;
    const t = setTimeout(() => setHasCopied(false), 2000);
    return () => clearTimeout(t);
  }, [hasCopied]);

  const onCopyClick = async () => {
    const value =
      typeof children === "string"
        ? children
        : String(children ?? "");

    try {
      if (
        typeof navigator !== "undefined" &&
        navigator.clipboard &&
        typeof navigator.clipboard.writeText === "function"
      ) {
        // jalur normal: https / localhost
        await navigator.clipboard.writeText(value);
      } else if (typeof document !== "undefined") {
        // fallback: http + IP
        const textarea = document.createElement("textarea");
        textarea.value = value;
        textarea.setAttribute("readonly", "");
        textarea.style.position = "fixed";
        textarea.style.left = "-9999px";
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand("copy");
        document.body.removeChild(textarea);
      } else {
        throw new Error("Clipboard API not available");
      }

      setHasCopied(true);
    } catch (err) {
      console.error("Copy failed for", label, err);
    }
  };

  return (
    <div className="mt-4 flex">
      <Card className="flex items-center overflow-x-auto bg-primary-foreground pl-4">
        <div className="overflow-x-auto whitespace-pre-wrap text-nowrap break-all pr-4 text-sm">
          {!isMobile && children ? children : "Copy Config File Path"}
        </div>
        <button
          type="button"
          className={cn("right-0 cursor-pointer bg-muted px-3 py-4")}
          onClick={onCopyClick}
        >
          {hasCopied ? (
            <CheckIcon className="h-4 w-4" />
          ) : (
            <ClipboardIcon className="h-4 w-4" />
          )}
          <span className="sr-only">Copy</span>
        </button>
      </Card>
    </div>
  );
}
