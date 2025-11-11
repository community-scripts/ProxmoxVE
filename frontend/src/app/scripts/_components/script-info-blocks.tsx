import { CalendarPlus, LayoutGrid } from "lucide-react";
import { useMemo, useState, useEffect } from "react";
import Image from "next/image";
import Link from "next/link";

import type { Category, Script } from "@/lib/types";

import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { basePath, mostPopularScripts } from "@/config/site-config";
import { Button } from "@/components/ui/button";
import { extractDate } from "@/lib/time";

const ITEMS_PER_PAGE = 3;

// ⬇️ Reusable icon loader with fallback
function AppIcon({ src, name, size = 64 }: { src?: string | null; name: string; size?: number }) {
  const [errored, setErrored] = useState(false);

  useEffect(() => setErrored(false), [src]);

  const fallbackClass = "h-11 w-11 object-contain rounded-md p-1";
  const iconClass =
    "h-11 w-11 min-w-[44px] min-h-[44px] rounded-md p-1 text-muted-foreground dark:text-muted text-opacity-90";

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
          className={`${fallbackClass} dark:brightness-0 dark:invert`}
        />
      ) : (
        <div className="flex h-16 w-16 min-w-16 items-center justify-center rounded-lg bg-accent/10 dark:bg-accent/20 p-1">
          <LayoutGrid className={iconClass} aria-hidden />
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
        <div className="flex w-full items-center justify-between">
          <h2 className="text-lg font-semibold">Newest Scripts</h2>
          <div className="flex items-center justify-end gap-1">
            {page > 1 && (
              <div className="cursor-pointer select-none p-2 text-sm font-semibold" onClick={goToPreviousPage}>
                Previous
              </div>
            )}
            {endIndex < latestScripts.length && (
              <div onClick={goToNextPage} className="cursor-pointer select-none p-2 text-sm font-semibold">
                {page === 1 ? "More.." : "Next"}
              </div>
            )}
          </div>
        </div>
      )}
      <div className="min-w flex w-full flex-row flex-wrap gap-4">
        {latestScripts.slice(startIndex, endIndex).map(script => (
          <Card key={script.slug} className="min-w-[250px] flex-1 flex-grow bg-accent/30">
            <CardHeader>
              <CardTitle className="flex items-center gap-3">
                <div className="flex h-16 w-16 min-w-16 items-center justify-center rounded-lg bg-accent p-1">
                  <AppIcon src={script.logo || `/${basePath}/logo.svg`} name={script.name || script.slug} />
                </div>
                <div className="flex flex-col">
                  <p className="text-sm text-muted-foreground flex items-center gap-1">
                    <CalendarPlus className="h-4 w-4" />
                    {extractDate(script.date_created)}
                  </p>
                </div>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <CardDescription className="line-clamp-3 text-card-foreground">{script.description}</CardDescription>
            </CardContent>
            <CardFooter className="">
              <Button asChild variant="outline">
                <Link
                  href={{
                    pathname: "/scripts",
                    query: { id: script.slug },
                  }}
                >
                  View Script
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
        <>
          <h2 className="text-lg font-semibold mb-1">Most Viewed Scripts</h2>
        </>
      )}
      <div className="min-w flex w-full flex-row flex-wrap gap-4">
        {mostViewedScripts.map(script => (
          <Card key={script.slug} className="min-w-[250px] flex-1 flex-grow bg-accent/30">
            <CardHeader>
              <CardTitle className="flex items-center gap-3">
                <div className="flex h-16 w-16 min-w-16 items-center justify-center rounded-lg bg-accent p-1">
                  <AppIcon src={script.logo || `/${basePath}/logo.svg`} name={script.name || script.slug} />
                </div>
                <div className="flex flex-col">
                  <p className="flex items-center gap-1 text-sm text-muted-foreground">
                    <CalendarPlus className="h-4 w-4" />
                    {extractDate(script.date_created)}
                  </p>
                </div>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <CardDescription className="line-clamp-3 text-card-foreground break-words">
                {script.description}
              </CardDescription>
            </CardContent>
            <CardFooter className="">
              <Button asChild variant="outline">
                <Link
                  href={{
                    pathname: "/scripts",
                    query: { id: script.slug },
                  }}
                  prefetch={false}
                >
                  View Script
                </Link>
              </Button>
            </CardFooter>
          </Card>
        ))}
      </div>
    </div>
  );
}
