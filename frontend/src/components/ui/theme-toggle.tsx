"use client";

import { MoonIcon, SunIcon } from "@radix-ui/react-icons";
import { useTheme } from "next-themes";
import { Button } from "./button";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "./tooltip";

export function ThemeToggle() {
  const { setTheme, theme: currentTheme } = useTheme();

  const handleChangeTheme = (theme: "light" | "dark") => {
    if (theme === currentTheme) return;

    if (!document.startViewTransition) return setTheme(theme);
    document.startViewTransition(() => setTheme(theme));
  };

  return (
    <TooltipProvider>
      <Tooltip delayDuration={100}>
        <TooltipTrigger asChild>
          <Button
            variant="ghost"
            type="button"
            size="icon"
            className="px-2"
            aria-label="Toggle theme"
            onClick={() =>
              handleChangeTheme(currentTheme === "dark" ? "light" : "dark")
            }
          >
            <SunIcon className="size-[1.2rem] text-neutral-800 dark:hidden dark:text-neutral-200" />
            <MoonIcon className="hidden size-[1.2rem] text-neutral-800 dark:block dark:text-neutral-200" />
          </Button>
        </TooltipTrigger>
        <TooltipContent side="bottom" className="text-xs">
          Theme Toggle
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}
