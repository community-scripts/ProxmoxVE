"use client";

import { useEffect, useState } from "react";
import { fetchCategories } from "@/lib/data";
import { Category, Script } from "@/lib/types";
import { ScriptItem } from "@/app/scripts/_components/ScriptItem";
import { Loader2, RefreshCw } from "lucide-react";

function getRandomScript(categories: Category[]): Script | null {
  const allScripts = categories.flatMap((cat) => cat.scripts || []);
  if (allScripts.length === 0) return null;
  const idx = Math.floor(Math.random() * allScripts.length);
  return allScripts[idx];
}

export default function RandomScriptPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [randomScript, setRandomScript] = useState<Script | null>(null);
  const [loading, setLoading] = useState(true);

  // Fetch categories/scripts on mount
  useEffect(() => {
    setLoading(true);
    fetchCategories()
      .then((cats) => {
        setCategories(cats);
        setRandomScript(getRandomScript(cats));
      })
      .finally(() => setLoading(false));
  }, []);

  // Handler to re-roll a new random script
  const reroll = () => {
    setRandomScript(getRandomScript(categories));
  };

  return (
    <div className="mb-3">
      <div className="mt-20 flex flex-col items-center sm:px-4 xl:px-0">
        <div className="w-full max-w-5xl flex flex-col items-center">
          <div className="w-full flex justify-between items-center mb-6">
            <h1 className="text-2xl font-semibold tracking-tight">Random Script</h1>
            <button
              onClick={reroll}
              className="flex items-center gap-2 rounded-lg bg-accent/30 px-4 py-2 text-base font-medium hover:bg-accent/50 transition-colors"
              title="Pick another random script"
              disabled={loading || categories.length === 0}
            >
              <RefreshCw className="h-5 w-5" />
              Re-Roll
            </button>
          </div>
          {loading ? (
            <div className="flex flex-col items-center justify-center w-full h-64">
              <Loader2 className="h-10 w-10 animate-spin" />
            </div>
          ) : randomScript ? (
            <ScriptItem item={randomScript} setSelectedScript={() => { }} />
          ) : (
            <div className="text-center text-muted-foreground">
              No scripts available.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
