"use client";
import AnimatedGradientText from "@/components/ui/animated-gradient-text";
import { Button } from "@/components/ui/button";
import { CardFooter } from "@/components/ui/card";
import { CodeBlock } from "@/components/ui/codeblock";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import Particles from "@/components/ui/particles";
import { Separator } from "@/components/ui/separator";
import { basePath } from "@/config/siteConfig";
import { cn } from "@/lib/utils";
import { ArrowRightIcon, ExternalLink } from "lucide-react";
import { useTheme } from "next-themes";
import Link from "next/link";
import { useEffect, useState } from "react";
import { FaGithub } from "react-icons/fa";

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
    <div className="w-full mt-16">
      <Particles
        className="absolute inset-0 -z-40"
        quantity={100}
        ease={80}
        color={color}
        refresh
      />
      <div className="container mx-auto">
        <div className="flex h-[80vh] flex-col items-center justify-center gap-4 py-20 lg:py-40">


          <div className="flex flex-col gap-4">
            <h1 className="max-w-2xl text-center text-3xl font-semibold tracking-tighter md:text-7xl">
              Install the IncusScripts CLI
            </h1>
            <div className="max-w-2xl gap-2 flex flex-col text-center sm:text-lg text-sm leading-relaxed tracking-tight text-muted-foreground md:text-xl">
              <p>
                IncusScripts is a CLI tool that helps you manage your Incus
                environment with ease.
              </p>

            </div>
            <div className="max-w-2xl gap-2 flex flex-col sm:text-lg text-sm leading-relaxed tracking-tight text-muted-foreground md:text-xl">

              <p>
                To install,<Link href="https://github.com/bketelsen/IncusScripts/releases"> download</Link> the latest release from GitHub.
              </p>
              <p>
                Extract the downloaded file and make the binary executable.
              </p>
              <p>
                Optionally, you can move the binary to a directory in your PATH.
              </p>
            </div>
            <div>
            <Link href="https://github.com/bketelsen/IncusScripts/releases">
              <Button
                size="lg"
                variant="expandIcon"
                Icon={CustomArrowRightIcon}
                iconPlacement="right"
                className="hover: my-3"
              >
                Download IncusScripts CLI
              </Button>
            </Link>
              <CodeBlock code={`chmod +x ./scripts-cli`} />
              <CodeBlock code={`mv ./scripts-cli /usr/local/bin/`} />
            </div>
          </div>
          <div className="flex flex-row gap-3">
            <Link href="https://github.com/bketelsen/IncusScripts/releases">
              <Button
                size="lg"
                variant="expandIcon"
                Icon={CustomArrowRightIcon}
                iconPlacement="right"
                className="hover:"
              >
                Download IncusScripts CLI
              </Button>
            </Link>
            <Link href="/scripts">
              <Button
                size="lg"
                variant="expandIcon"
                Icon={CustomArrowRightIcon}
                iconPlacement="right"
                className="hover:"
              >
                See available scripts
              </Button>
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
