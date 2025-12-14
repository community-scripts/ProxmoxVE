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

function CustomArrowRightIcon() {
  return <ArrowRightIcon className="h-4 w-4" width={1} />;
}

export default function Page() {
  const { theme } = useTheme();

  const [color, setColor] = useState("#000000");

  useEffect(() => {
    setColor(theme === "dark" ? "#ffffff" : "#000000");
  }, [theme]);

  return (
    <div className="mt-16 w-full">
      <Particles
        className="-z-40 absolute inset-0"
        quantity={100}
        ease={80}
        color={color}
        refresh
      />
      <div className="container mx-auto">
        <div className="flex h-[80vh] flex-col items-center justify-center gap-4 py-20 lg:py-40">
          <Dialog>
            <DialogTrigger>
              <div>
                <AnimatedGradientText>
                  <div
                    className={cn(
                      `absolute inset-0 block size-full animate-gradient bg-[length:var(--bg-size)_100%] bg-gradient-to-r from-[#ffaa40]/50 via-[#9c40ff]/50 to-[#ffaa40]/50 [border-radius:inherit] [mask:linear-gradient(#fff_0_0)_content-box,linear-gradient(#fff_0_0)]`,
                      `![mask-composite:subtract] p-px`
                    )}
                  />
                  ❤️ <Separator className="mx-2 h-4" orientation="vertical" />
                  <span
                    className={cn(
                      `animate-gradient bg-[length:var(--bg-size)_100%] bg-gradient-to-r from-[#ffaa40] via-[#9c40ff] to-[#ffaa40] bg-clip-text text-transparent`,
                      `inline`
                    )}
                  >
                    Scripts by tteck
                  </span>
                </AnimatedGradientText>
              </div>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Thank You!</DialogTitle>
                <DialogDescription>
                  A big thank you to tteck and the many contributors who have
                  made this project possible. Your hard work is truly
                  appreciated by the entire Proxmox community!
                </DialogDescription>
              </DialogHeader>
              <CardFooter className="flex flex-col gap-2">
                <Button className="w-full" variant="outline" asChild>
                  <a
                    href="https://github.com/tteck"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center justify-center"
                  >
                    <FaGithub className="mr-2 h-4 w-4" /> Tteck&apos;s GitHub
                  </a>
                </Button>
                <Button className="w-full" asChild>
                  <a
                    href={`https://github.com/community-scripts/${basePath}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center justify-center"
                  >
                    <ExternalLink className="mr-2 h-4 w-4" /> Proxmox Helper
                    Scripts
                  </a>
                </Button>
              </CardFooter>
            </DialogContent>
          </Dialog>

          <div className="flex flex-col gap-4">
            <h1 className="max-w-2xl text-center font-semibold text-3xl tracking-tighter md:text-7xl">
              Make managing your Homelab a breeze
            </h1>
            <div className="flex max-w-2xl flex-col gap-2 text-center text-muted-foreground text-sm leading-relaxed tracking-tight sm:text-lg md:text-xl">
              <p>
                We are a community-driven initiative that simplifies the setup
                of Proxmox Virtual Environment (VE).
              </p>
              <p>
                With 400+ scripts to help you manage your <b>Proxmox VE</b>,
                whether you&#39;re a seasoned user or a newcomer, we&#39;ve got
                you covered.
              </p>
            </div>
          </div>
          <div className="flex flex-row gap-3">
            <Link href="/scripts">
              <Button
                size="lg"
                variant="expandIcon"
                Icon={CustomArrowRightIcon}
                iconPlacement="right"
                className="hover:"
              >
                View Scripts
              </Button>
            </Link>
          </div>
        </div>

        {/* FAQ Section */}
        <div className="py-20" id="faq">
          <div className="mx-auto max-w-4xl px-4">
            <div className="mb-12 text-center">
              <h2 className="mb-4 font-bold text-3xl tracking-tighter md:text-5xl">
                Frequently Asked Questions
              </h2>
              <p className="text-lg text-muted-foreground">
                Find answers to common questions about our Proxmox VE scripts
              </p>
            </div>
            <FAQ />
          </div>
        </div>
      </div>
    </div>
  );
}
