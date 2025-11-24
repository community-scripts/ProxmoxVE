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
function AppIcon({ src, name, size = 48 }: { src?: string | null; name: string; size?: number }) {
  const [errored, setErrored] = useState(false);

  useEffect(() => setErrored(false), [src]);

  const imgClass = size <= 48 ? "h-8 w-8 object-contain rounded-md p-0.5" : "h-11 w-11 object-contain rounded-md p-1";
  const fallbackIconClass = size <= 48 ? "h-8 w-8" : "h-11 w-11";

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
          className={imgClass}
        />
      ) : (
        <LayoutGrid className={`${fallbackIconClass} text-muted-foreground`} aria-hidden />
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
    <aside className="hidden lg:block lg:min-w-[300px] lg:max-w-[300px]">
      <div className="sticky top-4 space-y-3">
        {/* Header */}
        <div className="flex items-center gap-2 px-1">
          <Crown className="h-4 w-4 text-blue-600 dark:text-blue-500" />
          <h2 className="text-base font-bold">Sponsored</h2>
        </div>

        {/* Sponsored Scripts */}
        <div className="space-y-3">
          {sponsoredScripts.map(script => (
            <Card
              key={script.slug}
              className="bg-accent/30 border-2 border-blue-500/40 hover:border-blue-500/60 transition-all duration-300 hover:shadow-lg flex flex-col relative overflow-hidden"
            >
              {/* Sponsored Badge */}
              <div className="absolute top-2 right-2 z-10">
                <Badge variant="secondary" className="text-[10px] px-1.5 py-0.5">
                  <span className="h-1 w-1 rounded-full bg-blue-500 mr-1" />
                  SPONSORED
                </Badge>
              </div>

              <CardHeader className="pb-2">
                <CardTitle className="flex items-start gap-2">
                  <div className="flex h-12 w-12 min-w-12 items-center justify-center rounded-lg bg-gradient-to-br from-accent/40 to-accent/60 p-1 shadow-sm">
                    <AppIcon src={script.logo} name={script.name || script.slug} size={48} />
                  </div>
                  <div className="flex flex-col flex-1 min-w-0">
                    <h3 className="font-semibold text-sm line-clamp-2 leading-tight">{script.name}</h3>
                  </div>
                </CardTitle>
              </CardHeader>

              <CardContent className="flex-grow py-2">
                <CardDescription className="line-clamp-2 text-xs leading-snug">
                  {script.description}
                </CardDescription>
              </CardContent>

              <CardFooter className="pt-0">
                <Button asChild variant="outline" className="w-full h-8 text-xs">
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
        <Card className="border-2 border-dashed border-primary/20 bg-accent/10">
          <CardHeader className="text-center pb-2">
            <div className="mx-auto mb-1 flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
              <Crown className="h-5 w-5 text-primary" />
            </div>
            <CardTitle className="text-base">Advertise Here</CardTitle>
          </CardHeader>
          <CardContent className="text-center space-y-2">
            <CardDescription className="text-xs">
              Reach VPS enthusiasts & developers
            </CardDescription>
            <ul className="text-[10px] space-y-1 text-muted-foreground">
              <li className="flex items-center justify-center gap-1.5">
                <span className="h-1 w-1 rounded-full bg-green-500" />
                Highly engaged audience
              </li>
              <li className="flex items-center justify-center gap-1.5">
                <span className="h-1 w-1 rounded-full bg-green-500" />
                Premium visibility
              </li>
              <li className="flex items-center justify-center gap-1.5">
                <span className="h-1 w-1 rounded-full bg-green-500" />
                Flexible terms
              </li>
            </ul>
            <Button asChild variant="outline" className="w-full h-8" size="sm">
              <a href="mailto:support@example.com" className="flex items-center gap-1.5 text-xs">
                <Mail className="h-3 w-3" />
                Get In Touch
              </a>
            </Button>
            <p className="text-[9px] text-muted-foreground pt-1">
              Starting at $99/month
            </p>
          </CardContent>
        </Card>
      </div>
    </aside>
  );
}
