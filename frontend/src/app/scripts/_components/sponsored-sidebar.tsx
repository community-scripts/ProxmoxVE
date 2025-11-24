"use client";

import { useMemo, useState, useEffect } from "react";
import { Crown, Mail, CalendarPlus, LayoutGrid } from "lucide-react";
import Link from "next/link";
import Image from "next/image";

import type { Category, Script } from "@/lib/types";
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { extractDate } from "@/lib/time";

interface SponsoredSidebarProps {
  items: Category[];
  onScriptSelect?: (slug: string) => void;
}

// Icon loader with fallback
function AppIcon({ src, name, size = 64 }: { src?: string | null; name: string; size?: number }) {
  const [errored, setErrored] = useState(false);

  useEffect(() => setErrored(false), [src]);

  const fallbackClass = "h-11 w-11 object-contain rounded-md p-1";

  const resolvedSrc = src && !errored ? src : undefined;

  return (
    <>
      {resolvedSrc ? (
        <Image
          src={resolvedSrc}
          unoptimized
          height={size}
          width={size}
          alt={`${name} icon`}
          onError={() => setErrored(true)}
          className={fallbackClass}
        />
      ) : (
        <div className="flex h-16 w-16 min-w-16 items-center justify-center rounded-lg bg-accent/10 dark:bg-accent/20 p-1">
          <LayoutGrid className="h-11 w-11 text-muted-foreground" aria-hidden />
        </div>
      )}
    </>
  );
}

export function SponsoredSidebar({ items, onScriptSelect }: SponsoredSidebarProps) {
  const sponsoredScripts = useMemo(() => {
    if (!items) return [];

    const scripts = items.flatMap(category => category.scripts || []);

    // Filter out duplicates and get only sponsored scripts
    const uniqueScriptsMap = new Map<string, Script>();
    scripts.forEach(script => {
      if (!uniqueScriptsMap.has(script.slug) && script.sponsored) {
        uniqueScriptsMap.set(script.slug, script);
      }
    });

    return Array.from(uniqueScriptsMap.values()).slice(0, 3); // Max 3 sponsored scripts
  }, [items]);

  if (!items || sponsoredScripts.length === 0) return null;

  return (
    <aside className="hidden lg:block lg:min-w-[380px] lg:max-w-[380px]">
      <div className="sticky top-4 space-y-4">
        {/* Header */}
        <div className="flex items-center gap-2 px-1">
          <Crown className="h-5 w-5 text-blue-600 dark:text-blue-500" />
          <h2 className="text-lg font-bold">Sponsored</h2>
        </div>

        {/* Sponsored Scripts */}
        <div className="space-y-4">
          {sponsoredScripts.map(script => (
            <Card
              key={script.slug}
              className="bg-accent/30 border-2 border-blue-500/40 hover:border-blue-500/60 transition-all duration-300 hover:shadow-lg flex flex-col relative overflow-hidden"
            >
              {/* Sponsored Badge */}
              <div className="absolute top-2 right-2 z-10">
                <Badge className="bg-blue-500 text-white border-0 text-xs">
                  <span className="h-1.5 w-1.5 rounded-full bg-white mr-1.5" />
                  SPONSORED
                </Badge>
              </div>

              {/* Blue accent bar */}
              <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-blue-400 via-blue-500 to-blue-400" />

              <CardHeader>
                <CardTitle className="flex items-start gap-3">
                  <div className="flex h-16 w-16 min-w-16 items-center justify-center rounded-xl bg-gradient-to-br from-accent/40 to-accent/60 p-1 shadow-md ring-1 ring-blue-500/30">
                    <AppIcon src={script.logo} name={script.name || script.slug} />
                  </div>
                  <div className="flex flex-col flex-1 min-w-0">
                    <h3 className="font-semibold text-base line-clamp-1 mb-1">{script.name}</h3>
                    <p className="text-xs text-muted-foreground flex items-center gap-1">
                      <CalendarPlus className="h-3 w-3" />
                      {extractDate(script.date_created)}
                    </p>
                  </div>
                </CardTitle>
              </CardHeader>

              <CardContent className="flex-grow">
                <CardDescription className="line-clamp-3 text-sm leading-relaxed">
                  {script.description}
                </CardDescription>
              </CardContent>

              <CardFooter className="pt-2">
                <Button asChild className="w-full bg-blue-500 hover:bg-blue-600 text-white">
                  <Link
                    href={{
                      pathname: "/scripts",
                      query: { id: script.slug },
                    }}
                  >
                    View Details
                  </Link>
                </Button>
              </CardFooter>
            </Card>
          ))}
        </div>

        {/* Advertise Here Card */}
        <Card className="border-2 border-dashed border-blue-500/30 bg-blue-500/5">
          <CardHeader className="text-center pb-3">
            <div className="mx-auto mb-2 flex h-12 w-12 items-center justify-center rounded-full bg-blue-500/10">
              <Crown className="h-6 w-6 text-blue-600 dark:text-blue-500" />
            </div>
            <CardTitle className="text-lg">Advertise Here</CardTitle>
          </CardHeader>
          <CardContent className="text-center space-y-3">
            <CardDescription className="text-sm">
              Reach VPS enthusiasts & developers
            </CardDescription>
            <ul className="text-xs space-y-1.5 text-muted-foreground">
              <li className="flex items-center justify-center gap-2">
                <span className="h-1.5 w-1.5 rounded-full bg-green-500" />
                Highly engaged audience
              </li>
              <li className="flex items-center justify-center gap-2">
                <span className="h-1.5 w-1.5 rounded-full bg-green-500" />
                Premium visibility
              </li>
              <li className="flex items-center justify-center gap-2">
                <span className="h-1.5 w-1.5 rounded-full bg-green-500" />
                Flexible terms
              </li>
            </ul>
            <Button asChild className="w-full bg-blue-500 hover:bg-blue-600 text-white" size="sm">
              <a href="mailto:support@example.com" className="flex items-center gap-2">
                <Mail className="h-3.5 w-3.5" />
                Get In Touch
              </a>
            </Button>
            <p className="text-[10px] text-muted-foreground">
              Starting at $99/month • Limited spots
            </p>
          </CardContent>
        </Card>
      </div>
    </aside>
  );
}
