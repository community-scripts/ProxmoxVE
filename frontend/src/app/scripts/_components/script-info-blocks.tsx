import { CalendarPlus, LayoutGrid } from "lucide-react";
import { useMemo, useState, useEffect } from "react";
import Image from "next/image";
import Link from "next/link";

import type { Category, Script } from "@/lib/types";

import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { mostPopularScripts } from "@/config/site-config";
import { Button } from "@/components/ui/button";
import { extractDate } from "@/lib/time";

const ITEMS_PER_PAGE = 3;

// ⬇️ Reusable icon loader with fallback
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

export function LatestScripts({ items }: { items: Category[] }) {
  const [page, setPage] = useState(1);

  const latestScripts = useMemo(() => {
    if (!items) return [];

    const scripts = items.flatMap(category => category.scripts || []);

    // Filter out duplicates by slug
    const uniqueScriptsMap = new Map<string, Script>();
    scripts.forEach(script => {
      if (!uniqueScriptsMap.has(script.slug)) {
        uniqueScriptsMap.set(script.slug, script);
      }
    });

    return Array.from(uniqueScriptsMap.values()).sort(
      (a, b) => new Date(b.date_created).getTime() - new Date(a.date_created).getTime(),
    );
  }, [items]);

  const goToNextPage = () => setPage(prev => prev + 1);
  const goToPreviousPage = () => setPage(prev => prev - 1);

  const startIndex = (page - 1) * ITEMS_PER_PAGE;
  const endIndex = page * ITEMS_PER_PAGE;

  if (!items) return null;

  return (
    <div className="">
      {latestScripts.length > 0 && (
        <div className="flex w-full items-center justify-between mb-4">
          <h2 className="text-2xl font-bold tracking-tight">Newest Scripts</h2>
          <div className="flex items-center justify-end gap-2">
            {page > 1 && (
              <div className="cursor-pointer select-none px-4 py-2 text-sm font-semibold rounded-lg hover:bg-accent transition-colors" onClick={goToPreviousPage}>
                Previous
              </div>
            )}
            {endIndex < latestScripts.length && (
              <div onClick={goToNextPage} className="cursor-pointer select-none px-4 py-2 text-sm font-semibold rounded-lg hover:bg-accent transition-colors">
                {page === 1 ? "More.." : "Next"}
              </div>
            )}
          </div>
        </div>
      )}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {latestScripts.slice(startIndex, endIndex).map(script => (
          <Card key={script.slug} className="bg-accent/30 border-2 hover:border-primary/50 transition-all duration-300 hover:shadow-lg flex flex-col">
            <CardHeader>
              <CardTitle className="flex items-start gap-3">
                <div className="flex h-16 w-16 min-w-16 items-center justify-center rounded-xl bg-gradient-to-br from-accent/40 to-accent/60 p-1 shadow-md">
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
              <CardDescription className="line-clamp-3 text-sm leading-relaxed">{script.description}</CardDescription>
            </CardContent>
            <CardFooter className="pt-2">
              <Button asChild variant="outline" className="w-full">
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
    </div>
  );
}

export function MostViewedScripts({ items }: { items: Category[] }) {
  const mostViewedScripts = items.reduce((acc: Script[], category) => {
    const foundScripts = (category.scripts || []).filter(script => mostPopularScripts.includes(script.slug));
    return acc.concat(foundScripts);
  }, []);

  return (
    <div className="">
      {mostViewedScripts.length > 0 && (
        <div className="flex w-full items-center justify-between mb-4">
          <h2 className="text-2xl font-bold tracking-tight">Most Viewed Scripts</h2>
        </div>
      )}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {mostViewedScripts.map(script => (
          <Card key={script.slug} className="bg-accent/30 border-2 hover:border-primary/50 transition-all duration-300 hover:shadow-lg flex flex-col">
            <CardHeader>
              <CardTitle className="flex items-start gap-3">
                <div className="flex h-16 w-16 min-w-16 items-center justify-center rounded-xl bg-gradient-to-br from-accent/40 to-accent/60 p-1 shadow-md">
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
              <CardDescription className="line-clamp-3 text-sm leading-relaxed break-words">
                {script.description}
              </CardDescription>
            </CardContent>
            <CardFooter className="pt-2">
              <Button asChild variant="outline" className="w-full">
                <Link
                  href={{
                    pathname: "/scripts",
                    query: { id: script.slug },
                  }}
                  prefetch={false}
                >
                  View Details
                </Link>
              </Button>
            </CardFooter>
          </Card>
        ))}
      </div>
    </div>
  );
}
