"use client";

import { useMemo } from "react";
import { Crown, ArrowRight, Mail } from "lucide-react";
import Link from "next/link";

import type { Category, Script } from "@/lib/types";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

interface SponsoredSidebarProps {
  items: Category[];
  onScriptSelect?: (slug: string) => void;
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

    return Array.from(uniqueScriptsMap.values()).slice(0, 4); // Max 4 sponsored scripts
  }, [items]);

  if (!items || sponsoredScripts.length === 0) return null;

  const handleScriptClick = (slug: string) => {
    if (onScriptSelect) {
      onScriptSelect(slug);
    }
  };

  return (
    <aside className="hidden lg:block lg:min-w-[320px] lg:max-w-[320px]">
      <div className="sticky top-4 space-y-4">
        {/* Sponsored Scripts */}
        <div className="space-y-3">
          {sponsoredScripts.map(script => (
            <Card
              key={script.slug}
              className="border-2 border-amber-500/40 hover:border-amber-500/60 transition-all duration-200 overflow-hidden"
            >
              {/* Sponsored Badge */}
              <div className="px-4 pt-3 pb-2">
                <Badge variant="secondary" className="bg-blue-500/10 text-blue-600 dark:text-blue-400 border-0">
                  <span className="h-1.5 w-1.5 rounded-full bg-blue-500 mr-2" />
                  SPONSORED
                </Badge>
              </div>

              <CardHeader className="pt-0 pb-3">
                <CardTitle className="flex items-center gap-3">
                  {script.logo && (
                    <div className="flex h-12 w-12 min-w-12 items-center justify-center rounded-lg bg-accent/50 p-1.5">
                      <img
                        src={script.logo}
                        alt={`${script.name} logo`}
                        className="h-full w-full object-contain rounded"
                      />
                    </div>
                  )}
                  <h3 className="font-semibold text-base line-clamp-1">{script.name}</h3>
                </CardTitle>
              </CardHeader>

              <CardContent className="space-y-3 pt-0">
                <CardDescription className="line-clamp-2 text-sm leading-relaxed">
                  {script.description}
                </CardDescription>

                <Button
                  variant="ghost"
                  className="w-full justify-between hover:bg-amber-500/10 hover:text-amber-600 dark:hover:text-amber-400 group"
                  onClick={() => handleScriptClick(script.slug)}
                  asChild
                >
                  <Link
                    href={{
                      pathname: "/scripts",
                      query: { id: script.slug },
                    }}
                  >
                    <span className="font-medium">LEARN MORE</span>
                    <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
                  </Link>
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Advertise Here Card */}
        <Card className="border-2 border-dashed border-primary/30 bg-accent/20">
          <CardHeader className="text-center pb-3">
            <div className="mx-auto mb-2 flex h-12 w-12 items-center justify-center rounded-full bg-primary/10">
              <Crown className="h-6 w-6 text-primary" />
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
            <Button asChild className="w-full" size="sm">
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
