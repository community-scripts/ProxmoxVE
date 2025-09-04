"use client";

import type { Category, Script } from "@/lib/types";

import ScriptAccordion from "./script-accordion";

function Sidebar({
  items,
  selectedScript,
  setSelectedScript,
  selectedCategory,
  setSelectedCategory,
}: {
  items: Category[];
  selectedScript: string | null;
  setSelectedScript: (script: string | null) => void;
  selectedCategory: string | null;
  setSelectedCategory: (category: string | null) => void;
}) {
  const uniqueScripts = items.reduce((acc, category) => {
    for (const script of category.scripts) {
      if (!acc.some(s => s.name === script.name)) {
        acc.push(script);
      }
    }
    return acc;
  }, [] as Script[]);

  return (
    <div className="flex min-w-[350px] flex-col sm:max-w-[350px]">
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
        />
      </div>
    </div>
  );
}

export default Sidebar;
