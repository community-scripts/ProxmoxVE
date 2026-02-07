import { useRouter } from "next/navigation";
import { ArrowRightIcon, Sparkles } from "lucide-react";
import Image from "next/image";
import React from "react";

import type { Category, Script } from "@/lib/types";

import {
  CommandDialog,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command";
import { basePath } from "@/config/site-config";
import { fetchCategories } from "@/lib/data";
import { cn } from "@/lib/utils";

import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "./ui/tooltip";
import { DialogTitle } from "./ui/dialog";
import { Button } from "./ui/button";
import { Badge } from "./ui/badge";
import Link from "next/link";

export function search(scripts: Script[], query: string): Script[] {
  const queryLower = query.toLowerCase().trim();
  const searchWords = queryLower.split(/\s+/).filter(Boolean);

  return scripts
    .map(script => {
      const nameLower = script.name.toLowerCase();
      const descriptionLower = (script.description || "").toLowerCase();

      let score = 0;

      for (const word of searchWords) {
        if (nameLower.includes(word)) {
          score += 10;
        }
        if (descriptionLower.includes(word)) {
          score += 5;
        }
      }

      return { script, score };
    })
    .filter(({ score }) => score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, 20)
    .map(({ script }) => script);
}

export function formattedBadge(type: string) {
  switch (type) {
    case "vm":
      return <Badge className="text-blue-500/75 border-blue-500/75">VM</Badge>;
    case "ct":
      return <Badge className="text-yellow-500/75 border-yellow-500/75">LXC</Badge>;
    case "pve":
      return <Badge className="text-orange-500/75 border-orange-500/75">PVE</Badge>;
    case "addon":
      return <Badge className="text-green-500/75 border-green-500/75">ADDON</Badge>;
  }
  return null;
}

function getRandomScript(categories: Category[], previouslySelected: Set<string> = new Set()): Script | null {
  const allScripts = categories.flatMap(cat => cat.scripts || []);
  if (allScripts.length === 0)
    return null;

  const availableScripts = allScripts.filter(script => !previouslySelected.has(script.slug));
  if (availableScripts.length === 0) {
    return allScripts[Math.floor(Math.random() * allScripts.length)];
  }
  const idx = Math.floor(Math.random() * availableScripts.length);
  return availableScripts[idx];
}

function CommandMenu() {
  const [query, setQuery] = React.useState("");
  const [open, setOpen] = React.useState(false);
  const [links, setLinks] = React.useState<Category[]>([]);
  const [isLoading, setIsLoading] = React.useState(false);
  const [results, setResults] = React.useState<Script[]>([]);
  const [selectedScripts, setSelectedScripts] = React.useState<Set<string>>(new Set());
  const router = useRouter();

  const fetchSortedCategories = () => {
    setIsLoading(true);
    fetchCategories()
      .then((categories) => {
        setLinks(categories);
        setIsLoading(false);
      })
      .catch((error) => {
        setIsLoading(false);
        console.error(error);
      });
  };

  React.useEffect(() => {
    if (query.trim() === "") {
      fetchSortedCategories();
    }
    else {
      const scriptMap = new Map<string, Script>();

      for (const category of links) {
        for (const script of category.scripts || []) {
          if (!scriptMap.has(script.slug)) {
            scriptMap.set(script.slug, script);
          }
        }
      }

      const uniqueScripts = Array.from(scriptMap.values());
      const filteredResults = search(uniqueScripts, query);
      setResults(filteredResults);
    }
  }, [query]);

  React.useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "k" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        fetchSortedCategories();
        setOpen(open => !open);
      }
    };
    document.addEventListener("keydown", handleKeyDown);
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, []);

  const handleOpenRandomScript = async () => {
    if (links.length === 0) {
      setIsLoading(true);
      try {
        const categories = await fetchCategories();
        setLinks(categories);
        const randomScript = getRandomScript(categories, selectedScripts);
        if (randomScript) {
          setSelectedScripts(prev => new Set([...prev, randomScript.slug]));
          router.push(`/scripts?id=${randomScript.slug}`);
        }
      }
      finally {
        setIsLoading(false);
      }
    }
    else {
      const randomScript = getRandomScript(links, selectedScripts);
      if (randomScript) {
        setSelectedScripts(prev => new Set([...prev, randomScript.slug]));
        router.push(`/scripts?id=${randomScript.slug}`);
      }
    }
  };

  const getUniqueScriptsMap = React.useCallback(() => {
    const scriptMap = new Map<string, { script: Script; categoryName: string }>();
    for (const category of links) {
      for (const script of category.scripts) {
        if (!scriptMap.has(script.slug)) {
          scriptMap.set(script.slug, { script, categoryName: category.name });
        }
      }
    }
    return scriptMap;
  }, [links]);

  const getUniqueScriptsByCategory = React.useCallback(() => {
    const scriptMap = getUniqueScriptsMap();
    const categoryOrder = links.map(cat => cat.name);
    const grouped: Record<string, Script[]> = {};

    for (const name of categoryOrder) {
      grouped[name] = [];
    }

    for (const { script, categoryName } of scriptMap.values()) {
      if (grouped[categoryName]) {
        grouped[categoryName].push(script);
      }
      else {
        grouped[categoryName] = [script];
      }
    }

    Object.keys(grouped).forEach((cat) => {
      if (grouped[cat].length === 0)
        delete grouped[cat];
    });

    return grouped;
  }, [getUniqueScriptsMap, links]);

  const uniqueScriptsByCategory = getUniqueScriptsByCategory();

  return (
    <>
      <div className="flex gap-2">
        <Button
          variant="outline"
          className={cn(
            "relative h-9 w-full justify-start rounded-[0.5rem] bg-muted/50 text-sm font-normal text-muted-foreground shadow-none sm:pr-12 md:w-40 lg:w-64",
          )}
          onClick={() => {
            fetchSortedCategories();
            setOpen(true);
          }}
        >
          <span className="inline-flex">Search scripts...</span>
          <kbd className="pointer-events-none absolute right-[0.3rem] top-[0.45rem] hidden h-5 select-none items-center gap-1 rounded border bg-muted px-1.5 font-mono text-[10px] font-medium opacity-100 sm:flex">
            <span className="text-xs">⌘</span>
            K
          </kbd>
        </Button>

        <TooltipProvider>
          <Tooltip delayDuration={100}>
            <TooltipTrigger asChild>
              <Button
                variant="outline"
                size="icon"
                onClick={handleOpenRandomScript}
                disabled={isLoading}
                className="hidden lg:flex"
                aria-label="Open Random Script"
                tabIndex={0}
                onKeyDown={(e) => {
                  if (e.key === "Enter" || e.key === " ") {
                    handleOpenRandomScript();
                  }
                }}
              >
                <Sparkles className="size-4" />
                <span className="sr-only">Open Random Script</span>
              </Button>
            </TooltipTrigger>
            <TooltipContent>
              <p>Open Random Script</p>
            </TooltipContent>
          </Tooltip>
        </TooltipProvider>
      </div>

      <CommandDialog
        open={open}
        onOpenChange={(open) => {
          setOpen(open);
          if (open) {
            setQuery("");
            setResults([]);
          }
        }}
      >
        <DialogTitle className="sr-only">Search scripts</DialogTitle>
        <CommandInput
          placeholder="Search for a script..."
          onValueChange={setQuery}
          value={query}
        />
        <CommandList>
          <CommandEmpty>
            {isLoading ? (
              "Searching..."
            ) : (
              <div className="flex flex-col items-center justify-center py-6 text-center">
                <p className="text-sm text-muted-foreground">No scripts match your search.</p>
                <div className="mt-4">
                  <p className="text-xs text-muted-foreground mb-2">Want to add a new script?</p>
                  <Button variant="outline" size="sm" asChild>
                    <Link
                      href={`https://github.com/community-scripts/${basePath}/tree/main/docs/contribution/GUIDE.md`}
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      Documentation <ArrowRightIcon className="ml-2 h-4 w-4" />
                    </Link>
                  </Button>
                </div>
              </div>
            )}
          </CommandEmpty>

          {results.length > 0 ? (
            <CommandGroup heading="Search Results">
              {results.map(script => (
                <CommandItem
                  key={`script:${script.slug}`}
                  value={`${script.name} ${script.type} ${script.description || ""}`}
                  onSelect={() => {
                    setOpen(false);
                    router.push(`/scripts?id=${script.slug}`);
                  }}
                  tabIndex={0}
                  aria-label={`Open script ${script.name}`}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" || e.key === " ") {
                      setOpen(false);
                      router.push(`/scripts?id=${script.slug}`);
                    }
                  }}
                >
                  <div className="flex gap-2" onClick={() => setOpen(false)}>
                    <Image
                      src={script.logo || `/${basePath}/logo.png`}
                      onError={e => ((e.currentTarget as HTMLImageElement).src = `/${basePath}/logo.png`)}
                      unoptimized
                      width={16}
                      height={16}
                      alt=""
                      className="h-5 w-5"
                    />
                    <span>{script.name}</span>
                    <span>{formattedBadge(script.type)}</span>
                  </div>
                </CommandItem>
              ))}
            </CommandGroup>
          ) : ( // When no search results, show all scripts grouped by category
            Object.entries(uniqueScriptsByCategory).map(([categoryName, scripts]) => (
              <CommandGroup key={`category:${categoryName}`} heading={categoryName}>
                {scripts.map(script => (
                  <CommandItem
                    key={`script:${script.slug}`}
                    value={`${script.name} ${script.type} ${script.description || ""}`}
                    onSelect={() => {
                      setOpen(false);
                      router.push(`/scripts?id=${script.slug}`);
                    }}
                    tabIndex={0}
                    aria-label={`Open script ${script.name}`}
                    onKeyDown={(e) => {
                      if (e.key === "Enter" || e.key === " ") {
                        setOpen(false);
                        router.push(`/scripts?id=${script.slug}`);
                      }
                    }}
                  >
                    <div className="flex gap-2" onClick={() => setOpen(false)}>
                      <Image
                        src={script.logo || `/${basePath}/logo.png`}
                        onError={e => ((e.currentTarget as HTMLImageElement).src = `/${basePath}/logo.png`)}
                        unoptimized
                        width={16}
                        height={16}
                        alt=""
                        className="h-5 w-5"
                      />
                      <span>{script.name}</span>
                      <span>{formattedBadge(script.type)}</span>
                    </div>
                  </CommandItem>
                ))}
              </CommandGroup>
            ))
          )}
        </CommandList>
      </CommandDialog>
    </>
  );
}

export default CommandMenu;
