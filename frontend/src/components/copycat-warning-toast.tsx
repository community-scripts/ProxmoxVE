"use client";

import { useEffect } from "react";
import { toast } from "sonner";

const STORAGE_KEY = "copycat-warning-dismissed";

export function CopycatWarningToast() {
  useEffect(() => {
    if (typeof window === "undefined")
      return;
    if (localStorage.getItem(STORAGE_KEY) === "true")
      return;

    toast.warning("Beware of copycat sites. Always verify the URL is correct before trusting or running scripts.", {
      position: "top-center",
      duration: Number.POSITIVE_INFINITY,
      closeButton: true,
      onDismiss: () => localStorage.setItem(STORAGE_KEY, "true"),
    });
  }, []);

  return null;
}
