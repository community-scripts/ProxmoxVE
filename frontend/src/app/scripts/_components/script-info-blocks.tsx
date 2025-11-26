import { CalendarPlus, LayoutGrid, TrendingUp, Sparkles, Crown } from "lucide-react";
import { useMemo, useState, useEffect } from "react";
import Image from "next/image";
import Link from "next/link";

import type { Category, Script } from "@/lib/types";

import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { mostPopularScripts } from "@/config/site-config";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { extractDate } from "@/lib/time";

const ITEMS_PER_PAGE = 3;
const ITEMS_PER_PAGE_LARGE = 6;

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

// ⬇️ Get deployment methods from script
function getDeploymentMethods(script: Script): string[] {
  const methods: string[] = [];

  if (script.install_methods && script.install_methods.length > 0) {
    const deployment = script.install_methods[0]?.platform?.deployment;
    if (deployment) {
      if (deployment.docker) methods.push("Docker");
      if (deployment.docker_compose) methods.push("Compose");
      if (deployment.kubernetes) methods.push("K8s");
      if (deployment.helm) methods.push("Helm");
      if (deployment.terraform) methods.push("Terraform");
      if (deployment.script) methods.push("Script");
    }
  }

  return methods.slice(0, 3); // Limit to 3 badges
}

export function FeaturedScripts({ items }: { items: Category[] }) {
  const featuredScripts = useMemo(() => {
    if (!items) return [];

    const scripts = items.flatMap(category => category.scripts || []);

    // Filter out duplicates by slug and get only sponsored scripts
    const uniqueScriptsMap = new Map<string, Script>();
    scripts.forEach(script => {
      if (!uniqueScriptsMap.has(script.slug) && script.sponsored) {
        uniqueScriptsMap.set(script.slug, script);
      }
    });

    return Array.from(uniqueScriptsMap.values()).slice(0, 6); // Max 6 featured scripts
  }, [items]);

  if (!items || featuredScripts.length === 0) return null;

  return (
    <div className="">
      <div className="flex w-full items-center gap-2 mb-4">
        <Crown className="h-5 w-5 text-amber-600 dark:text-amber-500" />
        <h2 className="text-2xl font-bold tracking-tight">Sponsored Scripts</h2>
        <Badge variant="outline" className="ml-2 border-amber-500/40 text-amber-700 dark:text-amber-400 text-xs">
          Sponsored
        </Badge>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {featuredScripts.map(script => (
          <Card
            key={script.slug}
            className="bg-accent/30 border-2 border-amber-500/60 hover:border-amber-500 transition-all duration-300 hover:shadow-lg flex flex-col relative overflow-hidden"
          >
            {/* Sponsored Badge */}
            <div className="absolute top-2 right-2 z-10">
              <Badge className="bg-amber-500 text-white border-0">
                <Crown className="h-3 w-3 mr-1" />
                Sponsored
              </Badge>
            </div>

            {/* Subtle highlight bar */}
            <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-amber-400 via-amber-500 to-amber-400" />

            <CardHeader>
              <CardTitle className="flex items-start gap-3">
                <div className="flex h-16 w-16 min-w-16 items-center justify-center rounded-xl bg-gradient-to-br from-accent/40 to-accent/60 p-1 shadow-md ring-1 ring-amber-500/30">
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
            <CardContent className="flex-grow space-y-3">
              <CardDescription className="line-clamp-3 text-sm leading-relaxed">{script.description}</CardDescription>
              {getDeploymentMethods(script).length > 0 && (
                <div className="flex flex-wrap gap-1.5">
                  {getDeploymentMethods(script).map(method => (
                    <Badge key={method} variant="secondary" className="text-xs">
                      {method}
                    </Badge>
                  ))}
                </div>
              )}
            </CardContent>
            <CardFooter className="pt-2">
              <Button asChild className="w-full bg-amber-500 hover:bg-amber-600 text-white">
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
            <CardContent className="flex-grow space-y-3">
              <CardDescription className="line-clamp-3 text-sm leading-relaxed">{script.description}</CardDescription>
              {getDeploymentMethods(script).length > 0 && (
                <div className="flex flex-wrap gap-1.5">
                  {getDeploymentMethods(script).map(method => (
                    <Badge key={method} variant="secondary" className="text-xs">
                      {method}
                    </Badge>
                  ))}
                </div>
              )}
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
            <CardContent className="flex-grow space-y-3">
              <CardDescription className="line-clamp-3 text-sm leading-relaxed break-words">
                {script.description}
              </CardDescription>
              {getDeploymentMethods(script).length > 0 && (
                <div className="flex flex-wrap gap-1.5">
                  {getDeploymentMethods(script).map(method => (
                    <Badge key={method} variant="secondary" className="text-xs">
                      {method}
                    </Badge>
                  ))}
                </div>
              )}
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

export function TrendingScripts({ items }: { items: Category[] }) {
  const trendingScripts = useMemo(() => {
    if (!items) return [];

    const scripts = items.flatMap(category => category.scripts || []);

    // Filter out duplicates by slug
    const uniqueScriptsMap = new Map<string, Script>();
    scripts.forEach(script => {
      if (!uniqueScriptsMap.has(script.slug)) {
        uniqueScriptsMap.set(script.slug, script);
      }
    });

    // Get scripts from last 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    return Array.from(uniqueScriptsMap.values())
      .filter(script => new Date(script.date_created) >= thirtyDaysAgo)
      .sort((a, b) => new Date(b.date_created).getTime() - new Date(a.date_created).getTime())
      .slice(0, 6);
  }, [items]);

  if (!items || trendingScripts.length === 0) return null;

  return (
    <div className="">
      <div className="flex w-full items-center gap-2 mb-4">
        <TrendingUp className="h-6 w-6 text-primary" />
        <h2 className="text-2xl font-bold tracking-tight">Trending This Month</h2>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {trendingScripts.map(script => (
          <Card key={script.slug} className="bg-accent/30 border-2 hover:border-primary/50 transition-all duration-300 hover:shadow-lg flex flex-col relative overflow-hidden">
            <div className="absolute top-2 right-2 z-10">
              <Badge className="bg-primary/90 text-primary-foreground">
                <Sparkles className="h-3 w-3 mr-1" />
                New
              </Badge>
            </div>
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
            <CardContent className="flex-grow space-y-3">
              <CardDescription className="line-clamp-3 text-sm leading-relaxed">{script.description}</CardDescription>
              {getDeploymentMethods(script).length > 0 && (
                <div className="flex flex-wrap gap-1.5">
                  {getDeploymentMethods(script).map(method => (
                    <Badge key={method} variant="secondary" className="text-xs">
                      {method}
                    </Badge>
                  ))}
                </div>
              )}
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

export function PopularScripts({ items }: { items: Category[] }) {
  const [page, setPage] = useState(1);

  const popularScripts = useMemo(() => {
    if (!items) return [];

    const scripts = items.flatMap(category => category.scripts || []);

    // Filter out duplicates by slug
    const uniqueScriptsMap = new Map<string, Script>();
    scripts.forEach(script => {
      if (!uniqueScriptsMap.has(script.slug)) {
        uniqueScriptsMap.set(script.slug, script);
      }
    });

    // Prioritize scripts from mostPopularScripts, then add others
    const allScripts = Array.from(uniqueScriptsMap.values());
    const popular = mostPopularScripts
      .map(slug => allScripts.find(s => s.slug === slug))
      .filter(Boolean) as Script[];

    // Add more scripts that have docker/k8s deployment
    const additionalScripts = allScripts
      .filter(script => !mostPopularScripts.includes(script.slug))
      .filter(script => {
        const deployment = script.install_methods?.[0]?.platform?.deployment;
        return deployment && (deployment.docker || deployment.kubernetes || deployment.helm);
      })
      .slice(0, 9);

    return [...popular, ...additionalScripts];
  }, [items]);

  const goToNextPage = () => setPage(prev => prev + 1);
  const goToPreviousPage = () => setPage(prev => prev - 1);

  const startIndex = (page - 1) * ITEMS_PER_PAGE_LARGE;
  const endIndex = page * ITEMS_PER_PAGE_LARGE;

  if (!items || popularScripts.length === 0) return null;

  return (
    <div className="">
      <div className="flex w-full items-center justify-between mb-4">
        <h2 className="text-2xl font-bold tracking-tight">Popular Scripts</h2>
        <div className="flex items-center justify-end gap-2">
          {page > 1 && (
            <div className="cursor-pointer select-none px-4 py-2 text-sm font-semibold rounded-lg hover:bg-accent transition-colors" onClick={goToPreviousPage}>
              Previous
            </div>
          )}
          {endIndex < popularScripts.length && (
            <div onClick={goToNextPage} className="cursor-pointer select-none px-4 py-2 text-sm font-semibold rounded-lg hover:bg-accent transition-colors">
              {page === 1 ? "More.." : "Next"}
            </div>
          )}
        </div>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {popularScripts.slice(startIndex, endIndex).map(script => (
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
            <CardContent className="flex-grow space-y-3">
              <CardDescription className="line-clamp-3 text-sm leading-relaxed break-words">
                {script.description}
              </CardDescription>
              {getDeploymentMethods(script).length > 0 && (
                <div className="flex flex-wrap gap-1.5">
                  {getDeploymentMethods(script).map(method => (
                    <Badge key={method} variant="secondary" className="text-xs">
                      {method}
                    </Badge>
                  ))}
                </div>
              )}
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
