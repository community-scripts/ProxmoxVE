"use client";

import { ThemeProvider as NextThemesProvider } from "next-themes";
import { type ThemeProviderProps } from "next-themes/dist/types";
import { useEffect, useState } from "react";

export function ThemeProvider({ children, ...props }: ThemeProviderProps) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return <div className="bg-black h-screen w-screen" />;
  }

  return (
    <NextThemesProvider attribute="class" defaultTheme="dark" enableSystem {...props}>
      {children}
    </NextThemesProvider>
  );
}
