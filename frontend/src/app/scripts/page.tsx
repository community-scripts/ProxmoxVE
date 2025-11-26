"use client";
import { Suspense, useEffect, useState } from "react";
import { Loader2, Search } from "lucide-react";
import { useQueryState } from "nuqs";

import type { Category, Script } from "@/lib/types";

import { ScriptItem } from "@/app/scripts/_components/script-item";
import { fetchCategories } from "@/lib/data";
import { Input } from "@/components/ui/input";

import { LatestScripts, TrendingScripts, PopularScripts } from "./_components/script-info-blocks";
import Sidebar from "./_components/sidebar";
import { ScriptFilters, type FilterState } from "./_components/script-filters";
import { SponsoredSidebar } from "./_components/sponsored-sidebar";

export const dynamic = "force-static";

function ScriptContent() {
  const [selectedScript, setSelectedScript] = useQueryState("id");
  const [selectedCategory, setSelectedCategory] = useQueryState("category");
  const [links, setLinks] = useState<Category[]>([]);
  const [item, setItem] = useState<Script>();
  const [searchQuery, setSearchQuery] = useState("");
  const [filters, setFilters] = useState<FilterState>({
    platforms: new Set(),
    deployments: new Set(),
    hosting: new Set(),
    ui: new Set(),
  });

  useEffect(() => {
    if (selectedScript && links.length > 0) {
      const script = links
        .flatMap((category) => category.scripts)
        .find((script) => script.slug === selectedScript);
      setItem(script);
    }
  }, [selectedScript, links]);

  useEffect(() => {
    fetchCategories()
      .then((categories) => {
        // ✅ Only keep categories that contain scripts
        const filtered = categories.filter(
          (category) => category.scripts && category.scripts.length > 0
        );
        setLinks(filtered);
      })
      .catch((error) => console.error(error));
  }, []);

  const matchesFilters = (script: Script): boolean => {
    if (!script.install_methods || script.install_methods.length === 0) {
      return filters.platforms.size === 0 &&
             filters.deployments.size === 0 &&
             filters.hosting.size === 0 &&
             filters.ui.size === 0;
    }

    const platform = script.install_methods[0]?.platform;
    if (!platform) {
      return filters.platforms.size === 0 &&
             filters.deployments.size === 0 &&
             filters.hosting.size === 0 &&
             filters.ui.size === 0;
    }

    // Check platform filters
    if (filters.platforms.size > 0) {
      const platformMatches = Array.from(filters.platforms).some(filter => {
        if (filter === "desktop-linux") return platform.desktop?.linux;
        if (filter === "desktop-windows") return platform.desktop?.windows;
        if (filter === "desktop-macos") return platform.desktop?.macos;
        if (filter === "mobile-android") return platform.mobile?.android;
        if (filter === "mobile-ios") return platform.mobile?.ios;
        if (filter === "web_app") return platform.web_app;
        if (filter === "browser_extension") return platform.browser_extension;
        if (filter === "cli_only") return platform.cli_only;
        return false;
      });
      if (!platformMatches) return false;
    }

    // Check deployment filters
    if (filters.deployments.size > 0) {
      const deploymentMatches = Array.from(filters.deployments).some(filter => {
        return platform.deployment?.[filter as keyof typeof platform.deployment];
      });
      if (!deploymentMatches) return false;
    }

    // Check hosting filters
    if (filters.hosting.size > 0) {
      const hostingMatches = Array.from(filters.hosting).some(filter => {
        return platform.hosting?.[filter as keyof typeof platform.hosting];
      });
      if (!hostingMatches) return false;
    }

    // Check UI filters
    if (filters.ui.size > 0) {
      const uiMatches = Array.from(filters.ui).some(filter => {
        return platform.ui?.[filter as keyof typeof platform.ui];
      });
      if (!uiMatches) return false;
    }

    return true;
  };

  const filteredLinks = links.map(category => ({
    ...category,
    scripts: category.scripts.filter(script => {
      // First check search query
      const matchesSearch = searchQuery === "" ||
        script.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        script.description.toLowerCase().includes(searchQuery.toLowerCase());

      // Then check filters
      const matchesFilter = matchesFilters(script);

      return matchesSearch && matchesFilter;
    })
  })).filter(category => category.scripts.length > 0);

  const totalScripts = links.reduce((acc, category) => acc + category.scripts.length, 0);
  const uniqueScripts = new Set(links.flatMap(cat => cat.scripts.map(s => s.slug))).size;
  const filteredScriptsCount = new Set(filteredLinks.flatMap(cat => cat.scripts.map(s => s.slug))).size;

  return (
    <div className="mb-3 pt-6">
      {/* Hero Section - Only show when no script is selected */}
      {!selectedScript && (
        <div className="w-full border-b bg-gradient-to-br from-accent/20 to-accent/5">
          <div className="w-full py-8 sm:py-10">
            <div className="max-w-3xl mx-auto text-center space-y-4 px-2 sm:px-16">
              <h1 className="text-2xl sm:text-3xl md:text-4xl font-bold tracking-tighter">
                Explore FOSS
                {" "}
                <span className="bg-gradient-to-r from-[#ffaa40] via-[#9c40ff] to-[#ffaa40] bg-clip-text text-transparent">
                  Scripts & Tools
                </span>
              </h1>
              <p className="text-muted-foreground text-sm sm:text-base max-w-2xl mx-auto">
                Browse our curated collection of {uniqueScripts}+ open source deployment scripts and tools
              </p>

              {/* Search Bar */}
              <div className="max-w-2xl mx-auto pt-2">
                <div className="relative">
                  <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 h-5 w-5 text-muted-foreground" />
                  <Input
                    type="text"
                    placeholder="Search scripts..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="pl-12 h-14 text-lg shadow-lg ring-2 ring-accent/20 focus-visible:ring-accent/40 transition-all"
                  />
                </div>
              </div>

              {/* Stats */}
              <div className="grid grid-cols-3 gap-3 max-w-2xl mx-auto pt-2">
                <div className="flex flex-col items-center">
                  <div className="text-xl sm:text-2xl font-bold bg-gradient-to-r from-[#ffaa40] to-[#9c40ff] bg-clip-text text-transparent">
                    {uniqueScripts}
                  </div>
                  <div className="text-xs text-muted-foreground">Scripts</div>
                </div>
                <div className="flex flex-col items-center">
                  <div className="text-xl sm:text-2xl font-bold bg-gradient-to-r from-[#9c40ff] to-[#ffaa40] bg-clip-text text-transparent">
                    {links.length}
                  </div>
                  <div className="text-xs text-muted-foreground">Categories</div>
                </div>
                <div className="flex flex-col items-center">
                  <div className="text-xl sm:text-2xl font-bold bg-gradient-to-r from-[#ffaa40] to-[#9c40ff] bg-clip-text text-transparent">
                    Daily
                  </div>
                  <div className="text-xs text-muted-foreground">Updates</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Filters Section - Only show when no script is selected */}
      {!selectedScript && (
        <div className="w-full border-b bg-background/50 backdrop-blur-sm sticky top-0 z-10 shadow-sm">
          <div className="w-full py-4 px-2 sm:px-16">
            <div className="flex flex-col gap-4">
              {/* Results Count & Refine Label */}
              <div className="flex flex-col sm:flex-row sm:items-center gap-2">
                <div className="flex items-center gap-3">
                  <h2 className="text-base font-semibold">
                    {filteredScriptsCount === uniqueScripts ? (
                      `${uniqueScripts} Scripts`
                    ) : (
                      `${filteredScriptsCount} of ${uniqueScripts} Scripts`
                    )}
                  </h2>
                  <span className="text-sm text-muted-foreground">•</span>
                  <span className="text-sm font-medium text-muted-foreground">Refine results:</span>
                </div>
              </div>

              {/* Filter Pills */}
              <ScriptFilters filters={filters} onFilterChange={setFilters} />
            </div>
          </div>
        </div>
      )}

      <div className="mt-6 sm:mt-8 flex w-full gap-2 px-2 sm:px-16">
        {/* Left Sidebar - Categories */}
        <div className="hidden sm:flex">
          <Sidebar
            items={filteredLinks}
            selectedScript={selectedScript}
            setSelectedScript={setSelectedScript}
            selectedCategory={selectedCategory}
            setSelectedCategory={setSelectedCategory}
          />
        </div>

        {/* Main Content */}
        <div className="w-full px-2 sm:px-0 sm:w-auto pb-8 flex-1 min-w-0">
          {selectedScript && item ? (
            <ScriptItem item={item} setSelectedScript={setSelectedScript} />
          ) : (
            <div className="flex w-full flex-col gap-8">
              <TrendingScripts items={filteredLinks} />
              <LatestScripts items={filteredLinks} />
              <PopularScripts items={filteredLinks} />
            </div>
          )}
        </div>

        {/* Right Sidebar - Sponsored */}
        <SponsoredSidebar items={links} onScriptSelect={setSelectedScript} />
      </div>
    </div>
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
