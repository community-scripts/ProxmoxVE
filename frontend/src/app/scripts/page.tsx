"use client";
import { Suspense, useEffect, useState } from "react";
import { Loader2, X } from "lucide-react";
import { useQueryState } from "nuqs";

import type { Category, Script } from "@/lib/types";

import { ScriptItem } from "@/app/scripts/_components/script-item";
import { fetchCategories } from "@/lib/data";

import { LatestScripts, MostViewedScripts } from "./_components/script-info-blocks";
import Sidebar from "./_components/sidebar";

export const dynamic = "force-static";

function ScriptContent() {
  const [selectedScript, setSelectedScript] = useQueryState("id");
  const [selectedCategory, setSelectedCategory] = useQueryState("category");
  const [links, setLinks] = useState<Category[]>([]);
  const [item, setItem] = useState<Script>();
  const [latestPage, setLatestPage] = useState(1);

  const closeScript = () => {
    window.history.pushState({}, document.title, window.location.pathname);
    setSelectedScript(null);
  };

  useEffect(() => {
    if (selectedScript && links.length > 0) {
      const script = links
        .map(category => category.scripts)
        .flat()
        .find(script => script.slug === selectedScript);
      setItem(script);
    }
  }, [selectedScript, links]);

  useEffect(() => {
    fetchCategories()
      .then((categories) => {
        setLinks(categories);
      })
      .catch(error => console.error(error));
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
          {selectedScript && item
            ? (
                <div className="flex w-full flex-col">
                  <div className="mb-3 flex items-center justify-between">
                    <h2 className="text-2xl font-semibold tracking-tight text-foreground/90">Selected Script</h2>
                    <button
                      onClick={closeScript}
                      className="rounded-full p-2 text-muted-foreground hover:bg-card/50 transition-colors"
                    >
                      <X className="h-5 w-5" />
                    </button>
                  </div>
                  <ScriptItem item={item} />
                </div>
              )
            : (
                <div className="flex w-full flex-col gap-5">
                  <LatestScripts items={links} page={latestPage} onPageChange={setLatestPage} />
                  <MostViewedScripts items={links} />
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
      fallback={(
        <div className="flex h-screen w-full flex-col items-center justify-center gap-5 bg-background px-4 md:px-6">
          <div className="space-y-2 text-center">
            <Loader2 className="h-10 w-10 animate-spin" />
          </div>
        </div>
      )}
    >
      <ScriptContent />
    </Suspense>
  );
}
