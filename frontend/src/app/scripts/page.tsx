"use client";
import { Suspense, useEffect, useState, useMemo } from "react";
import { Loader2, X, Search as SearchIcon } from "lucide-react";
import { useQueryState } from "nuqs";

import type { Category, Script } from "@/lib/types";

import { ScriptItem } from "@/app/scripts/_components/script-item";
import { fetchCategories } from "@/lib/data";
import { Search } from "@/components/search";
import { AdvancedFilter } from "@/components/advanced-filter";
import {
  filterScripts,
  hasActiveFilters,
  sortScriptsByDate,
  type FilterState,
  type ScriptType,
} from "@/lib/filter-utils";

import { LatestScripts, MostViewedScripts } from "./_components/script-info-blocks";
import Sidebar from "./_components/sidebar";

export const dynamic = "force-static";

function ScriptContent() {
  const [selectedScript, setSelectedScript] = useQueryState("id");
  const [selectedCategory, setSelectedCategory] = useQueryState("category");
  const [links, setLinks] = useState<Category[]>([]);
  const [item, setItem] = useState<Script>();
  const [latestPage, setLatestPage] = useState(1);

  // Filter state from URL
  const [search, setSearch] = useQueryState("search");
  const [types, setTypes] = useQueryState("types");
  const [categoryIds, setCategoryIds] = useQueryState("categories");
  const [status, setStatus] = useQueryState("status");
  const [minCpu, setMinCpu] = useQueryState("minCpu");
  const [maxCpu, setMaxCpu] = useQueryState("maxCpu");
  const [minRam, setMinRam] = useQueryState("minRam");
  const [maxRam, setMaxRam] = useQueryState("maxRam");

  // Parse filter state
  const filterState: FilterState = useMemo(() => ({
    search: search || "",
    types: (types?.split(",").filter(Boolean) as ScriptType[]) || [],
    categoryIds: (categoryIds?.split(",").filter(Boolean).map(Number)) || [],
    status: (status as FilterState["status"]) || "all",
    minCpu: minCpu ? parseInt(minCpu) : null,
    maxCpu: maxCpu ? parseInt(maxCpu) : null,
    minRam: minRam ? parseInt(minRam) : null,
    maxRam: maxRam ? parseInt(maxRam) : null,
  }), [search, types, categoryIds, status, minCpu, maxCpu, minRam, maxRam]);

  // Get all scripts from all categories
  const allScripts = useMemo(() => {
    if (!links.length) return [];
    const scripts = links.flatMap((category) => category.scripts || []);
    // Remove duplicates by slug
    const uniqueScripts = new Map<string, Script>();
    scripts.forEach((script) => {
      if (!uniqueScripts.has(script.slug)) {
        uniqueScripts.set(script.slug, script);
      }
    });
    return Array.from(uniqueScripts.values());
  }, [links]);

  // Filter scripts based on current filter state
  const filteredScripts = useMemo(() => {
    if (!hasActiveFilters(filterState)) {
      return allScripts;
    }
    return filterScripts(allScripts, filterState, links);
  }, [allScripts, filterState, links]);

  // Check if any filters are active
  const isFiltering = hasActiveFilters(filterState);

  const closeScript = () => {
    window.history.pushState({}, document.title, window.location.pathname);
    setSelectedScript(null);
  };

  useEffect(() => {
    if (selectedScript && links.length > 0) {
      const script = links
        .map((category) => category.scripts)
        .flat()
        .find((script) => script.slug === selectedScript);
      setItem(script);
      if (script) {
        document.title = `${script.name} | Heretek AI`;
      }
    } else {
      document.title = "Heretek AI";
    }
  }, [selectedScript, links]);

  useEffect(() => {
    fetchCategories()
      .then((categories) => {
        setLinks(categories);
      })
      .catch((error) => console.error(error));
  }, []);

  return (
    <div className="mb-3">
      <div className="mt-20 flex gap-4 sm:px-4 xl:px-0">
        <div className="hidden sm:flex">
          <Sidebar
            items={links}
            selectedScript={selectedScript}
            setSelectedScript={setSelectedScript}
            selectedCategory={selectedCategory}
            setSelectedCategory={setSelectedCategory}
          />
        </div>
        <div className="px-4 w-full sm:max-w-[calc(100%-350px-16px)]">
          {selectedScript && item ? (
            <div className="flex w-full flex-col">
              <div className="mb-3 flex items-center justify-between">
                <h2 className="text-2xl font-semibold tracking-tight text-foreground/90">
                  Selected Script
                </h2>
                <button
                  onClick={closeScript}
                  className="rounded-full p-2 text-muted-foreground hover:bg-card/50 transition-colors"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>
              <ScriptItem item={item} />
            </div>
          ) : (
            <div className="flex w-full flex-col gap-5">
              {/* Search and Filter Section */}
              <div className="space-y-4">
                <Search
                  placeholder="Search scripts by name or description..."
                  className="w-full"
                />
                <AdvancedFilter categories={links} />
              </div>

              {/* Results Count */}
              {isFiltering && (
                <div className="flex items-center gap-2 text-sm text-muted-foreground">
                  <SearchIcon className="h-4 w-4" />
                  <span>
                    {filteredScripts.length} script{filteredScripts.length !== 1 ? "s" : ""} found
                  </span>
                </div>
              )}

              {/* Script Lists */}
              {isFiltering ? (
                <FilteredScriptsList scripts={filteredScripts} onSelect={setSelectedScript} />
              ) : (
                <>
                  <LatestScripts items={links} page={latestPage} onPageChange={setLatestPage} />
                  <MostViewedScripts items={links} />
                </>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// Component to display filtered scripts
function FilteredScriptsList({
  scripts,
  onSelect,
}: {
  scripts: Script[];
  onSelect: (slug: string) => void;
}) {
  const sortedScripts = useMemo(() => sortScriptsByDate(scripts), [scripts]);

  if (sortedScripts.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-12 text-center">
        <SearchIcon className="h-12 w-12 text-muted-foreground/50 mb-4" />
        <h3 className="text-lg font-semibold text-foreground/80">No scripts found</h3>
        <p className="text-muted-foreground">Try adjusting your search or filters</p>
      </div>
    );
  }

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-1">
      {sortedScripts.map((script) => (
        <ScriptCard key={script.slug} script={script} onSelect={onSelect} />
      ))}
    </div>
  );
}

// Simple script card for filtered results
import Image from "next/image";
import Link from "next/link";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { basePath } from "@/config/site-config";
import { extractDate } from "@/lib/time";
import { CalendarPlus } from "lucide-react";

function ScriptCard({
  script,
  onSelect,
}: {
  script: Script;
  onSelect: (slug: string) => void;
}) {
  const getDisplayValueFromType = (type: string) => {
    switch (type) {
      case "ct":
        return "LXC";
      case "vm":
        return "VM";
      case "pve":
        return "PVE";
      case "addon":
        return "ADDON";
      default:
        return "";
    }
  };

  return (
    <Card className="min-w-[250px] flex-1 flex-grow bg-accent/30 hover:border-brass/50 transition-colors">
      <CardHeader>
        <CardTitle className="flex items-center gap-3">
          <div className="flex h-16 w-16 min-w-16 items-center justify-center rounded-lg bg-accent p-1">
            <Image
              src={script.logo || `/${basePath}/logo.png`}
              unoptimized
              height={64}
              width={64}
              alt=""
              onError={(e) => {
                (e.currentTarget as HTMLImageElement).src = `/${basePath}/logo.png`;
              }}
              className="h-11 w-11 object-contain"
            />
          </div>
          <div className="flex flex-col">
            <p className="text-lg line-clamp-1">
              {script.name} {getDisplayValueFromType(script.type)}
            </p>
            <p className="text-sm text-muted-foreground flex items-center gap-1">
              <CalendarPlus className="h-4 w-4" />
              {extractDate(script.date_created)}
            </p>
          </div>
        </CardTitle>
      </CardHeader>
      <CardContent>
        <CardDescription className="line-clamp-3 text-card-foreground">
          {script.description}
        </CardDescription>
      </CardContent>
      <CardFooter>
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
  );
}

export default function Page() {
  return (
    <Suspense
      fallback={
        <div className="flex h-screen w-full flex-col items-center justify-center gap-5 bg-background px-4 md:px-6">
          <div className="space-y-2 text-center">
            <Loader2 className="h-10 w-10 animate-spin" />
          </div>
        </div>
      }
    >
      <ScriptContent />
    </Suspense>
  );
}
