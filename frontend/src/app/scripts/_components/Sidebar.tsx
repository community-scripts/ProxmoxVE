"use client";

import { Category } from "@/lib/types";
import ScriptAccordion from "./ScriptAccordion";

const Sidebar = ({
  items,
  selectedScript,
  setSelectedScript,
}: {
  items: Category[];
  selectedScript: string | null;
  setSelectedScript: (script: string | null) => void;
}) => {
  return (
    <div className="flex min-w-72 flex-col sm:max-w-72">
      <div className="flex items-end justify-between pb-4">
        <h1 className="text-xl font-bold">Categories</h1>
        <p className="text-xs italic text-muted-foreground">
          {items.reduce((acc, category) => acc + category.scripts.length, 0)}{" "}
          Total scripts
        </p>
      </div>
      <div className="rounded-lg">
        <ScriptAccordion
          items={items}
          selectedScript={selectedScript}
          setSelectedScript={setSelectedScript}
        />
      </div>
    </div>
  );
};

export default Sidebar;
