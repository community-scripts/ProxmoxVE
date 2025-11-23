"use client";
import { Suspense, useEffect, useState } from "react";
import { Loader2, Search } from "lucide-react";
import { useQueryState } from "nuqs";

import type { Category, Script } from "@/lib/types";

import { ScriptItem } from "@/app/scripts/_components/script-item";
import { fetchCategories } from "@/lib/data";
import { Input } from "@/components/ui/input";

import { LatestScripts, MostViewedScripts } from "./_components/script-info-blocks";
import Sidebar from "./_components/sidebar";

export const dynamic = "force-static";

function ScriptContent() {
  const [selectedScript, setSelectedScript] = useQueryState("id");
  const [selectedCategory, setSelectedCategory] = useQueryState("category");
  const [links, setLinks] = useState<Category[]>([]);
  const [item, setItem] = useState<Script>();
  const [searchQuery, setSearchQuery] = useState("");

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

  const filteredLinks = links.map(category => ({
    ...category,
    scripts: category.scripts.filter(script =>
      script.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      script.description.toLowerCase().includes(searchQuery.toLowerCase())
    )
  })).filter(category => category.scripts.length > 0);

  const totalScripts = links.reduce((acc, category) => acc + category.scripts.length, 0);
  const uniqueScripts = new Set(links.flatMap(cat => cat.scripts.map(s => s.slug))).size;

  return (
    <div className="mb-3">
      {/* Hero Section - Only show when no script is selected */}
      {!selectedScript && (
        <div className="w-full border-b bg-gradient-to-br from-accent/20 to-accent/5">
          <div className="container mx-auto px-4 py-12 sm:py-16">
            <div className="max-w-3xl mx-auto text-center space-y-6">
              <h1 className="text-3xl sm:text-4xl md:text-5xl font-bold tracking-tighter">
                Explore FOSS
                {" "}
                <span className="bg-gradient-to-r from-[#ffaa40] via-[#9c40ff] to-[#ffaa40] bg-clip-text text-transparent">
                  Scripts & Tools
                </span>
              </h1>
              <p className="text-muted-foreground text-base sm:text-lg max-w-2xl mx-auto">
                Browse our curated collection of {uniqueScripts}+ open source deployment scripts and tools
              </p>

              {/* Search Bar */}
              <div className="max-w-xl mx-auto">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                    type="text"
                    placeholder="Search scripts..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="pl-10 h-12 text-base"
                  />
                </div>
              </div>

              {/* Stats */}
              <div className="grid grid-cols-3 gap-4 max-w-2xl mx-auto pt-4">
                <div className="flex flex-col items-center">
                  <div className="text-2xl sm:text-3xl font-bold bg-gradient-to-r from-[#ffaa40] to-[#9c40ff] bg-clip-text text-transparent">
                    {uniqueScripts}
                  </div>
                  <div className="text-xs sm:text-sm text-muted-foreground">Scripts</div>
                </div>
                <div className="flex flex-col items-center">
                  <div className="text-2xl sm:text-3xl font-bold bg-gradient-to-r from-[#9c40ff] to-[#ffaa40] bg-clip-text text-transparent">
                    {links.length}
                  </div>
                  <div className="text-xs sm:text-sm text-muted-foreground">Categories</div>
                </div>
                <div className="flex flex-col items-center">
                  <div className="text-2xl sm:text-3xl font-bold bg-gradient-to-r from-[#ffaa40] to-[#9c40ff] bg-clip-text text-transparent">
                    Daily
                  </div>
                  <div className="text-xs sm:text-sm text-muted-foreground">Updates</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="mt-6 sm:mt-8 flex sm:px-4 xl:px-0">
        {/* Desktop Sidebar */}
        <div className="hidden sm:flex">
          <Sidebar
            items={searchQuery ? filteredLinks : links}
            selectedScript={selectedScript}
            setSelectedScript={setSelectedScript}
            selectedCategory={selectedCategory}
            setSelectedCategory={setSelectedCategory}
          />
        </div>

        <div className="mx-4 w-full sm:mx-0 sm:ml-4 pb-8">
          {selectedScript && item ? (
            <ScriptItem item={item} setSelectedScript={setSelectedScript} />
          ) : (
            <div className="flex w-full flex-col gap-6">
              <LatestScripts items={searchQuery ? filteredLinks : links} />
              <MostViewedScripts items={searchQuery ? filteredLinks : links} />
            </div>
          )}
        </div>
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
