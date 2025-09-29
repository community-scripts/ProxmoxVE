"use client";

import { useCallback, useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import { useQueryState } from "nuqs";
import { Menu } from "lucide-react";

import type { Category, Script } from "@/lib/types";

import { ScriptItem } from "@/app/scripts/_components/script-item";
import Sidebar from "@/app/scripts/_components/sidebar";
import { fetchCategories } from "@/lib/data";

import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from "../ui/sheet";
import { Button } from "../ui/button";

function MobileSidebar() {
  const [isOpen, setIsOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [categories, setCategories] = useState<Category[]>([]);
  const [lastViewedScript, setLastViewedScript] = useState<Script | undefined>(undefined);
  const pathname = usePathname();

  // Always call the hooks (React hooks can't be conditional)
  const [selectedScript, setSelectedScript] = useQueryState("id");
  const [selectedCategory, setSelectedCategory] = useQueryState("category");

  // For non-scripts pages, we'll manage state locally
  const [tempSelectedScript, setTempSelectedScript] = useState<string | null>(null);
  const [tempSelectedCategory, setTempSelectedCategory] = useState<string | null>(null);

  const isOnScriptsPage = pathname === "/scripts";
  const currentSelectedScript = isOnScriptsPage ? selectedScript : tempSelectedScript;
  const currentSelectedCategory = isOnScriptsPage ? selectedCategory : tempSelectedCategory;

  const loadCategories = useCallback(async () => {
    setIsLoading(true);
    try {
      const response = await fetchCategories();
      setCategories(response);
    }
    catch (error) {
      console.error(error);
    }
    finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadCategories();
  }, [loadCategories]);

  useEffect(() => {
    if (!currentSelectedScript || categories.length === 0) {
      return;
    }

    const scriptMatch = categories
      .flatMap(category => category.scripts)
      .find(script => script.slug === currentSelectedScript);

    setLastViewedScript(scriptMatch);
  }, [currentSelectedScript, categories]);

  const handleOpenChange = (openState: boolean) => {
    setIsOpen(openState);
  };

  const handleItemSelect = () => {
    setIsOpen(false);
  };

  const hasLinks = categories.length > 0;

  return (
    <Sheet open={isOpen} onOpenChange={handleOpenChange}>
      <SheetTrigger asChild>
        <Button
          variant="ghost"
          size="icon"
          aria-label="Open navigation menu"
          tabIndex={0}
          onKeyDown={(event) => {
            if (event.key === "Enter" || event.key === " ") {
              setIsOpen(true);
            }
          }}
        >
          <Menu className="size-5" aria-hidden="true" />
        </Button>
      </SheetTrigger>
      <SheetHeader className="border-b border-border px-6 pb-4 pt-2 sr-only">
        <SheetTitle className="sr-only">Categories</SheetTitle>
      </SheetHeader>
      <SheetContent side="left" className="flex w-full max-w-xs flex-col gap-4 overflow-hidden px-0 pb-6">
        <div className="flex h-full flex-col gap-4 overflow-y-auto">
          {isLoading && !hasLinks
            ? (
                <div className="flex w-full flex-col items-center justify-center gap-2 px-6 py-4 text-sm text-muted-foreground">
                  Loading categories...
                </div>
              )
            : (
                <div className="flex flex-col gap-4 px-4">
                  <Sidebar
                    items={categories}
                    selectedScript={currentSelectedScript}
                    setSelectedScript={isOnScriptsPage ? setSelectedScript : setTempSelectedScript}
                    selectedCategory={currentSelectedCategory}
                    setSelectedCategory={isOnScriptsPage ? setSelectedCategory : setTempSelectedCategory}
                    onItemSelect={handleItemSelect}
                  />
                </div>
              )}
          {currentSelectedScript && lastViewedScript
            ? (
                <div className="flex flex-col gap-3 px-4">
                  <p className="text-sm font-medium">Last Viewed</p>
                  <ScriptItem
                    item={lastViewedScript}
                    setSelectedScript={isOnScriptsPage ? setSelectedScript : setTempSelectedScript}
                  />
                </div>
              )
            : null}
        </div>
      </SheetContent>
    </Sheet>
  );
}

export default MobileSidebar;
