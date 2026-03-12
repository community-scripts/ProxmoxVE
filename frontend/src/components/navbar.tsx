"use client";

import { Suspense, useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";

import { navbarLinks } from "@/config/site-config";

import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "./ui/tooltip";
import { GitHubStarsButton } from "./animate-ui/components/buttons/github-stars";
import { Button } from "./animate-ui/components/buttons/button";
import MobileSidebar from "./navigation/mobile-sidebar";
import { ThemeToggle } from "./ui/theme-toggle";
import CommandMenu from "./command-menu";

export const dynamic = "force-dynamic";

function Navbar() {
  const [isScrolled, setIsScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 0);
    };

    window.addEventListener("scroll", handleScroll);

    return () => {
      window.removeEventListener("scroll", handleScroll);
    };
  }, []);

  return (
    <>
      <div
        className={`fixed left-0 top-0 z-50 flex w-screen justify-center px-4 xl:px-0 transition-all duration-300 ${isScrolled
            ? "glass rust-border border-b bg-background/50"
            : ""
          }`}
      >
        <div className="flex h-20 w-full max-w-[1440px] items-center justify-between sm:flex-row">
          <Link
            href="/"
            className="cursor-pointer w-full justify-center sm:justify-start flex-row-reverse hidden sm:flex items-center gap-2 font-semibold sm:flex-row group"
          >
            <div className="relative machine-icon">
              <Image height={18} unoptimized width={18} alt="logo" src="/ProxmoxVE/logo.png" className="" />
            </div>
            <span className="font-[family-name:var(--font-cinzel)] tracking-wide text-foreground group-hover:text-rust-400 transition-colors duration-300">
              Heretek AI
            </span>
          </Link>
          <div className="flex items-center justify-between sm:justify-end gap-2 w-full">
            <div className="flex sm:hidden">
              <Suspense>
                <MobileSidebar />
              </Suspense>
            </div>
            <div className="hidden sm:flex items-center gap-2">
              {navbarLinks.filter(link => !link.external).map(({ href, event, icon, text }) => (
                <TooltipProvider key={event}>
                  <Tooltip delayDuration={100}>
                    <TooltipTrigger>
                      <Button
                        variant="ghost"
                        size="sm"
                        asChild
                        className="text-muted-foreground hover:text-rust-400 hover:bg-rust-500/10 transition-colors duration-300"
                      >
                        <Link href={href} data-umami-event={event}>
                          {icon}
                          <span className="ml-2 hidden lg:inline">{text}</span>
                        </Link>
                      </Button>
                    </TooltipTrigger>
                    <TooltipContent side="bottom" className="text-xs bg-card border-rust-500/30">
                      {text}
                    </TooltipContent>
                  </Tooltip>
                </TooltipProvider>
              ))}
            </div>
            <div className="flex sm:gap-2">
              <CommandMenu />
              <GitHubStarsButton username="Heretek-AI" repo="ProxmoxVE" className="hidden md:flex" />
              {navbarLinks.filter(link => link.external).map(({ href, event, icon, text, mobileHidden }) => (
                <TooltipProvider key={event}>
                  <Tooltip delayDuration={100}>
                    <TooltipTrigger className={mobileHidden ? "hidden lg:block" : ""}>
                      <Button
                        variant="ghost"
                        size="icon"
                        asChild
                        className="text-muted-foreground hover:text-rust-400 hover:bg-rust-500/10 transition-colors duration-300"
                      >
                        <Link target="_blank" href={href} data-umami-event={event}>
                          {icon}
                          <span className="sr-only">{text}</span>
                        </Link>
                      </Button>
                    </TooltipTrigger>
                    <TooltipContent side="bottom" className="text-xs bg-card border-rust-500/30">
                      {text}
                    </TooltipContent>
                  </Tooltip>
                </TooltipProvider>
              ))}
              <ThemeToggle />
            </div>
          </div>
        </div>
      </div>
    </>
  );
}

export default Navbar;
