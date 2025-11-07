"use client";

import { ClipboardCheck } from "lucide-react";
import { toast } from "sonner";

export default async function handleCopy(type: string, value: string) {
  try {
    // Jalur normal: https / localhost
    if (
      typeof navigator !== "undefined" &&
      navigator.clipboard &&
      typeof navigator.clipboard.writeText === "function"
    ) {
      await navigator.clipboard.writeText(value);
    } else if (typeof document !== "undefined") {
      // Fallback: http + IP, dll.
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

    toast.success(`Copied ${type} to clipboard`, {
      icon: <ClipboardCheck className="h-4 w-4" />,
    });
  } catch (err) {
    console.error("Copy failed", err);
    toast.error(`Failed to copy ${type}`, {
      icon: <ClipboardCheck className="h-4 w-4" />,
    });
  }
}
