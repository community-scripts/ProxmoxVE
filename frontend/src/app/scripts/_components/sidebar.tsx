"use client";

import type { Category, Script } from "@/lib/types";

import { cn } from "@/lib/utils";

import ScriptAccordion from "./script-accordion";

type SidebarProps = {
  items: Category[];
  selectedScript: string | null;
  setSelectedScript: (script: string | null) => void;
  selectedCategory: string | null;
  setSelectedCategory: (category: string | null) => void;
  onItemSelect?: () => void;
  className?: string;
};

function Sidebar({
  items,
  selectedScript,
  setSelectedScript,
  selectedCategory,
  setSelectedCategory,
  onItemSelect,
  className,
}: SidebarProps) {
  const uniqueScripts = items.reduce((acc, category) => {
    for (const script of category.scripts) {
      if (!acc.some(s => s.name === script.name)) {
        acc.push(script);
      }
    }
    return acc;
  }, [] as Script[]);

  return (
    <div className={cn("flex w-full flex-col sm:min-w-[350px] sm:max-w-[350px]", className)}>
      <div className="flex items-end justify-between pb-4">
        <h1 className="text-xl font-bold">Categories</h1>
        <p className="text-xs italic text-muted-foreground">
          {uniqueScripts.length}
          {" "}
          Total scripts
        </p>
      </div>
      <div className="rounded-lg">
        <ScriptAccordion
          items={items}
          selectedScript={selectedScript}
          setSelectedScript={setSelectedScript}
          selectedCategory={selectedCategory}
          setSelectedCategory={setSelectedCategory}
          onItemSelect={onItemSelect}
        />
      </div>
    </div>
  );
}

export default Sidebar;
