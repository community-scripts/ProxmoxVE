"use client";

export const dynamic = "force-static";

import ScriptItem from "@/app/scripts/_components/ScriptItem";
import { fetchCategories } from "@/lib/data";
import { Category, Script } from "@/lib/types";
import { Loader2 } from "lucide-react";
import { useQueryState } from "nuqs";
import { Suspense, useEffect, useState } from "react";
import {
  LatestScripts,
  MostViewedScripts,
} from "./_components/ScriptInfoBlocks";
import Sidebar from "./_components/Sidebar";

function ScriptContent() {
  const [selectedScript, setSelectedScript] = useQueryState("id");
  const [links, setLinks] = useState<Category[]>([]);
  const [item, setItem] = useState<Script>();

  useEffect(() => {
    if (selectedScript && links.length > 0) {
      const script = links
        .map((category) => category.scripts)
        .flat()
        .find((script) => script.slug === selectedScript);
      setItem(script);
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
      <div className="mt-20 flex sm:px-4 xl:px-0">
        <div className="hidden sm:flex">
          <Sidebar
            items={links}
            selectedScript={selectedScript}
            setSelectedScript={setSelectedScript}
          />
        </div>
        <div className="mx-7 w-full sm:mx-0 sm:ml-7">
          {selectedScript && item ? (
            <ScriptItem item={item} setSelectedScript={setSelectedScript} />
          ) : (
            <div className="flex w-full flex-col gap-5">
              <LatestScripts items={links} />
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
