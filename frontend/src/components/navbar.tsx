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
        className={`fixed left-0 top-0 z-50 flex w-screen justify-center px-4 xl:px-0 ${isScrolled ? "glass border-b bg-background/50" : ""
        }`}
      >
        <div className="flex h-20 w-full max-w-[1440px] items-center justify-between sm:flex-row">
          <Link
            href="/"
            className="cursor-pointer w-full justify-center sm:justify-start flex-row-reverse hidden sm:flex items-center gap-2 font-semibold sm:flex-row"
          >
            <Image height={18} unoptimized width={18} alt="logo" src="/ProxmoxVE/logo.png" className="" />
            <span className="">Proxmox VE Helper-Scripts</span>
          </Link>
          <div className="flex items-center justify-between sm:justify-end gap-2 w-full">
            <div className="flex sm:hidden">
              <Suspense>
                <MobileSidebar />
              </Suspense>
            </div>
            <div className="flex sm:gap-2">
              <CommandMenu />
              <GitHubStarsButton username="community-scripts" repo="ProxmoxVE" className="hidden md:flex" />
              {navbarLinks.map(({ href, event, icon, text, mobileHidden }) => (
                <TooltipProvider key={event}>
                  <Tooltip delayDuration={100}>
                    <TooltipTrigger className={mobileHidden ? "hidden lg:block" : ""}>
                      <Button variant="ghost" size="icon" asChild>
                        <Link target="_blank" href={href} data-umami-event={event}>
                          {icon}
                          <span className="sr-only">{text}</span>
                        </Link>
                      </Button>
                    </TooltipTrigger>
                    <TooltipContent side="bottom" className="text-xs">
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
