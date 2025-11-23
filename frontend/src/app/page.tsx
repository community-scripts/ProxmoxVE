"use client";
import { ArrowRightIcon, ExternalLink, Zap, Shield, Users, Code2, Rocket, BookOpen } from "lucide-react";
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
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
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
    <>
      <div className="w-full mt-16">
        <Particles className="absolute inset-0 -z-40" quantity={100} ease={80} color={color} refresh />
        <div className="container mx-auto px-4">
          {/* Hero Section */}
          <div className="flex min-h-[85vh] flex-col items-center justify-center gap-6 py-20 lg:py-32">
            <Dialog>
              <DialogTrigger>
                <div>
                  <AnimatedGradientText>
                    <div
                      className={cn(
                        `absolute inset-0 block size-full animate-gradient bg-gradient-to-r from-[#ffaa40]/50 via-[#9c40ff]/50 to-[#ffaa40]/50 bg-[length:var(--bg-size)_100%] [border-radius:inherit] [mask:linear-gradient(#fff_0_0)_content-box,linear-gradient(#fff_0_0)]`,
                        `p-px ![mask-composite:subtract]`,
                      )}
                    />
                    ❤️
                    {" "}
                    <Separator className="mx-2 h-4" orientation="vertical" />
                    <span
                      className={cn(
                        `animate-gradient bg-gradient-to-r from-[#ffaa40] via-[#9c40ff] to-[#ffaa40] bg-[length:var(--bg-size)_100%] bg-clip-text text-transparent`,
                        `inline`,
                      )}
                    >
                      Your Daily FOSS Discovery
                    </span>
                  </AnimatedGradientText>
                </div>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>About Daily FOSS</DialogTitle>
                  <DialogDescription>
                    Daily FOSS is your go-to platform for discovering and deploying free and open source software.
                    We curate the best FOSS projects with easy deployment options across multiple platforms.
                  </DialogDescription>
                </DialogHeader>
                <CardFooter className="flex flex-col gap-2">
                  <Button className="w-full" asChild>
                    <a
                      href={`https://github.com/community-scripts/${basePath}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center justify-center"
                    >
                      <FaGithub className="mr-2 h-4 w-4" />
                      {" "}
                      View on GitHub
                    </a>
                  </Button>
                </CardFooter>
              </DialogContent>
            </Dialog>

            <div className="flex flex-col gap-6 items-center">
              <h1 className="max-w-4xl text-center text-4xl font-bold tracking-tighter sm:text-5xl md:text-6xl lg:text-7xl">
                Discover & Deploy
                {" "}
                <span className="bg-gradient-to-r from-[#ffaa40] via-[#9c40ff] to-[#ffaa40] bg-clip-text text-transparent">
                  Open Source
                </span>
                {" "}
                Tools Daily
              </h1>
              <p className="max-w-2xl text-center text-lg leading-relaxed text-muted-foreground md:text-xl">
                Your curated platform for exploring and deploying free and open source software.
                From self-hosted apps to cloud solutions, we make FOSS accessible to everyone.
              </p>
            </div>

            <div className="flex flex-col sm:flex-row gap-4 mt-4">
              <Link href="/scripts">
                <Button
                  size="lg"
                  variant="expandIcon"
                  Icon={CustomArrowRightIcon}
                  iconPlacement="right"
                  className="text-base"
                >
                  Explore Tools
                </Button>
              </Link>
              <Button size="lg" variant="outline" asChild className="text-base">
                <a
                  href={`https://github.com/community-scripts/${basePath}`}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <FaGithub className="mr-2 h-5 w-5" />
                  View on GitHub
                </a>
              </Button>
            </div>
          </div>

          {/* Stats Section */}
          <div className="py-16 border-y">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-4xl mx-auto text-center">
              <div className="flex flex-col items-center gap-2">
                <div className="text-4xl md:text-5xl font-bold bg-gradient-to-r from-[#ffaa40] to-[#9c40ff] bg-clip-text text-transparent">
                  Curated
                </div>
                <div className="text-muted-foreground">FOSS Collection</div>
              </div>
              <div className="flex flex-col items-center gap-2">
                <div className="text-4xl md:text-5xl font-bold bg-gradient-to-r from-[#9c40ff] to-[#ffaa40] bg-clip-text text-transparent">
                  Multi-Platform
                </div>
                <div className="text-muted-foreground">Deployment Options</div>
              </div>
              <div className="flex flex-col items-center gap-2">
                <div className="text-4xl md:text-5xl font-bold bg-gradient-to-r from-[#ffaa40] to-[#9c40ff] bg-clip-text text-transparent">
                  Daily
                </div>
                <div className="text-muted-foreground">New Discoveries</div>
              </div>
            </div>
          </div>

          {/* Features Section */}
          <div className="py-24" id="features">
            <div className="text-center mb-16">
              <h2 className="text-3xl font-bold tracking-tighter md:text-5xl mb-4">
                Why Choose Daily FOSS?
              </h2>
              <p className="text-muted-foreground text-lg max-w-2xl mx-auto">
                Your complete platform for discovering and deploying free and open source software
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-6xl mx-auto">
              <Card className="border-2 hover:border-primary/50 transition-colors">
                <CardHeader>
                  <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-[#ffaa40]/20 to-[#9c40ff]/20 flex items-center justify-center mb-4">
                    <Zap className="h-6 w-6 text-[#ffaa40]" />
                  </div>
                  <CardTitle>Quick Deployment</CardTitle>
                  <CardDescription>
                    Deploy with scripts, Docker, Kubernetes, or Terraform. Choose the method that works best for you.
                  </CardDescription>
                </CardHeader>
              </Card>

              <Card className="border-2 hover:border-primary/50 transition-colors">
                <CardHeader>
                  <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-[#9c40ff]/20 to-[#ffaa40]/20 flex items-center justify-center mb-4">
                    <Shield className="h-6 w-6 text-[#9c40ff]" />
                  </div>
                  <CardTitle>Trusted & Verified</CardTitle>
                  <CardDescription>
                    Every tool is carefully curated and verified for security, reliability, and active maintenance.
                  </CardDescription>
                </CardHeader>
              </Card>

              <Card className="border-2 hover:border-primary/50 transition-colors">
                <CardHeader>
                  <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-[#ffaa40]/20 to-[#9c40ff]/20 flex items-center justify-center mb-4">
                    <Users className="h-6 w-6 text-[#ffaa40]" />
                  </div>
                  <CardTitle>Community Powered</CardTitle>
                  <CardDescription>
                    Built by the FOSS community. Contribute, suggest new tools, and help others discover great software.
                  </CardDescription>
                </CardHeader>
              </Card>

              <Card className="border-2 hover:border-primary/50 transition-colors">
                <CardHeader>
                  <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-[#9c40ff]/20 to-[#ffaa40]/20 flex items-center justify-center mb-4">
                    <Code2 className="h-6 w-6 text-[#9c40ff]" />
                  </div>
                  <CardTitle>Cross-Platform</CardTitle>
                  <CardDescription>
                    Find tools for Linux, Windows, macOS, web, mobile, and more. All in one place.
                  </CardDescription>
                </CardHeader>
              </Card>

              <Card className="border-2 hover:border-primary/50 transition-colors">
                <CardHeader>
                  <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-[#ffaa40]/20 to-[#9c40ff]/20 flex items-center justify-center mb-4">
                    <Rocket className="h-6 w-6 text-[#ffaa40]" />
                  </div>
                  <CardTitle>Rich Metadata</CardTitle>
                  <CardDescription>
                    Detailed information including platforms, deployment methods, documentation, and default credentials.
                  </CardDescription>
                </CardHeader>
              </Card>

              <Card className="border-2 hover:border-primary/50 transition-colors">
                <CardHeader>
                  <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-[#9c40ff]/20 to-[#ffaa40]/20 flex items-center justify-center mb-4">
                    <BookOpen className="h-6 w-6 text-[#9c40ff]" />
                  </div>
                  <CardTitle>Always Updated</CardTitle>
                  <CardDescription>
                    Daily updates with new tools, features, and improvements. Never miss out on the latest FOSS.
                  </CardDescription>
                </CardHeader>
              </Card>
            </div>
          </div>

          {/* FAQ Section */}
          <div className="py-24 border-t" id="faq">
            <div className="max-w-4xl mx-auto">
              <div className="text-center mb-12">
                <h2 className="text-3xl font-bold tracking-tighter md:text-5xl mb-4">
                  Frequently Asked Questions
                </h2>
                <p className="text-muted-foreground text-lg">
                  Find answers to common questions about Daily FOSS
                </p>
              </div>
              <FAQ />
            </div>
          </div>

          {/* CTA Section */}
          <div className="py-24">
            <div className="max-w-4xl mx-auto text-center border rounded-2xl p-12 bg-gradient-to-br from-[#ffaa40]/5 to-[#9c40ff]/5">
              <h2 className="text-3xl font-bold tracking-tighter md:text-4xl mb-4">
                Ready to Explore?
              </h2>
              <p className="text-muted-foreground text-lg mb-8 max-w-2xl mx-auto">
                Start discovering amazing free and open source software. Find the perfect tools for your next project.
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <Link href="/scripts">
                  <Button
                    size="lg"
                    variant="expandIcon"
                    Icon={CustomArrowRightIcon}
                    iconPlacement="right"
                  >
                    Browse All Tools
                  </Button>
                </Link>
                <Button size="lg" variant="outline" asChild>
                  <a
                    href={`https://github.com/community-scripts/${basePath}/blob/main/CONTRIBUTING.md`}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    Contribute
                  </a>
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
