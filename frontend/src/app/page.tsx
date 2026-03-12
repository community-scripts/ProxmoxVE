"use client";

import { ArrowRightIcon, ExternalLink } from "lucide-react";
import { useEffect, useState } from "react";
import { FaGithub } from "react-icons/fa";
import { useTheme } from "next-themes";
import Link from "next/link";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import AnimatedGradientText from "@/components/ui/animated-gradient-text";
import { Separator } from "@/components/ui/separator";
import { CardFooter } from "@/components/ui/card";
import Particles from "@/components/ui/particles";
import { Button } from "@/components/ui/button";
import { basePath } from "@/config/site-config";
import FAQ from "@/components/faq";
import { cn } from "@/lib/utils";
import { FeatureCards } from "@/components/feature-cards";
import { NewsHighlight } from "@/components/news-highlight";

function CustomArrowRightIcon() {
  return <ArrowRightIcon className="h-4 w-4" width={1} />;
}

export default function Page() {
  const { theme } = useTheme();

  const [color, setColor] = useState("#000000");

  useEffect(() => {
    // Use Mechanicus-themed colors for particles
    setColor(theme === "dark" ? "#b45309" : "#92400e");
  }, [theme]);

  return (
    <>
      <div className="w-full mt-16 relative overflow-hidden">
        {/* Mechanicus Background Effects */}
        <div className="pointer-events-none absolute inset-0 scan-lines opacity-5" />
        <div className="pointer-events-none absolute inset-0 noise-overlay" />

        {/* Themed Particles */}
        <Particles
          className="absolute inset-0 -z-40"
          quantity={100}
          ease={80}
          color={color}
          theme="mechanicus"
          refresh
        />

        <div className="container mx-auto relative z-10">
          <div className="flex h-[60vh] flex-col items-center justify-center gap-4 py-20 lg:py-32">
            <Dialog>
              <DialogTrigger>
                <div>
                  <AnimatedGradientText>
                    <div
                      className={cn(
                        `absolute inset-0 block size-full animate-gradient bg-gradient-to-r from-rust-500/50 via-corruption-500/50 to-brass-500/50 bg-[length:var(--bg-size)_100%] [border-radius:inherit] [mask:linear-gradient(#fff_0_0)_content-box,linear-gradient(#fff_0_0)]`,
                        `p-px ![mask-composite:subtract]`,
                      )}
                    />
                    ⚙️
                    {" "}
                    <Separator className="mx-2 h-4" orientation="vertical" />
                    <span
                      className={cn(
                        `animate-gradient bg-gradient-to-r from-rust-400 via-corruption-400 to-brass-400 bg-[length:var(--bg-size)_100%] bg-clip-text text-transparent`,
                        `inline`,
                      )}
                    >
                      Scripts by tteck
                    </span>
                  </AnimatedGradientText>
                </div>
              </DialogTrigger>
              <DialogContent className="mechanicus-panel">
                <DialogHeader>
                  <DialogTitle className="font-[family-name:var(--font-cinzel)] brass-text">
                    Praise the Omnissiah!
                  </DialogTitle>
                  <DialogDescription>
                    A big thank you to tteck and the many contributors who have made this project possible. Your hard
                    work is truly appreciated by the entire Proxmox community!
                  </DialogDescription>
                </DialogHeader>
                <CardFooter className="flex flex-col gap-2">
                  <Button className="w-full" variant="mechanicus" asChild>
                    <a
                      href="https://github.com/tteck"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center justify-center"
                    >
                      <FaGithub className="mr-2 h-4 w-4" />
                      {" "}
                      Tteck's GitHub
                    </a>
                  </Button>
                  <Button className="w-full" variant="forge" asChild>
                    <a
                      href={`https://github.com/Heretek-AI/${basePath}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center justify-center"
                    >
                      <ExternalLink className="mr-2 h-4 w-4" />
                      {" "}
                      Proxmox Helper Scripts
                    </a>
                  </Button>
                </CardFooter>
              </DialogContent>
            </Dialog>

            <div className="flex flex-col gap-4">
              <h1 className="max-w-2xl text-center text-3xl font-semibold tracking-tighter md:text-7xl font-[family-name:var(--font-cinzel)]">
                <span className="brass-text">Heretek-AI</span>
              </h1>
              <div className="max-w-2xl gap-2 flex flex-col text-center sm:text-lg text-sm leading-relaxed tracking-tight text-muted-foreground md:text-xl">
                <p className="text-rust-300 font-semibold">
                  Uncompliant scripts, made quicker.
                </p>
                <p>
                  Scripts that don't meet the strict guidelines of the official
                  {" "}
                  <a
                    href="https://github.com/community-scripts/ProxmoxVE"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="underline text-corruption-400 hover:text-corruption-300 transition-colors"
                  >
                    Community-Scripts
                  </a>
                  {" "}
                  repository, but are updated faster and built with flexibility in mind.
                </p>
              </div>
            </div>
            <div className="flex flex-row gap-3">
              <Link href="/scripts">
                <Button
                  size="lg"
                  variant="mechanicus"
                  Icon={CustomArrowRightIcon}
                  iconPlacement="right"
                >
                  View Scripts
                </Button>
              </Link>
              <Link href="/categories">
                <Button
                  size="lg"
                  variant="outline"
                  className="border-rust-500/50 hover:border-rust-400 hover:bg-rust-500/10"
                >
                  Browse Categories
                </Button>
              </Link>
            </div>
          </div>

          {/* Feature Cards Section */}
          <div className="py-12 px-4">
            <FeatureCards />
          </div>

          {/* News Section */}
          <div className="py-12 px-4">
            <NewsHighlight />
          </div>

          {/* FAQ Section */}
          <div className="py-20" id="faq">
            <div className="max-w-4xl mx-auto px-4">
              <div className="text-center mb-12">
                <h2 className="text-3xl font-bold tracking-tighter md:text-5xl mb-4 font-[family-name:var(--font-cinzel)]">
                  <span className="brass-text">Frequently Asked Questions</span>
                </h2>
                <p className="text-muted-foreground text-lg">
                  Find answers to common questions about our Proxmox VE scripts
                </p>
              </div>
              <FAQ />
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
