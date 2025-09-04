import { useCallback, useEffect, useRef, useState } from "react";
import Image from "next/image";
import Link from "next/link";

import type { Category } from "@/lib/types";

import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion";
import { formattedBadge } from "@/components/command-menu";
import { basePath } from "@/config/site-config";
import { cn } from "@/lib/utils";

export default function ScriptAccordion({
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
  const [expandedItem, setExpandedItem] = useState<string | undefined>(undefined);
  const linkRefs = useRef<{ [key: string]: HTMLAnchorElement | null }>({});

  const handleAccordionChange = (value: string | undefined) => {
    setExpandedItem(value);
  };

  const handleSelected = useCallback(
    (slug: string) => {
      setSelectedScript(slug);
    },
    [setSelectedScript],
  );

  useEffect(() => {
    if (selectedScript) {
      let category;

      // If we have a selected category, try to find the script in that specific category
      if (selectedCategory) {
        category = items.find(
          cat => cat.name === selectedCategory && cat.scripts.some(script => script.slug === selectedScript),
        );
      }

      // Fallback: if no category is selected or script not found in selected category,
      // use the first category containing the script (backward compatibility)
      if (!category) {
        category = items.find(category => category.scripts.some(script => script.slug === selectedScript));
      }

      if (category) {
        setExpandedItem(category.name);
        handleSelected(selectedScript);
      }
    }
  }, [selectedScript, selectedCategory, items, handleSelected]);
  return (
    <Accordion
      type="single"
      value={expandedItem}
      onValueChange={handleAccordionChange}
      collapsible
      className="overflow-y-scroll max-h-[calc(100vh-225px)] overflow-x-hidden p-2"
    >
      {items.map(category => (
        <AccordionItem
          key={`${category.id}:category`}
          value={category.name}
          className={cn("sm:text-sm flex flex-col border-none", {
            "rounded-lg bg-accent/30": expandedItem === category.name,
          })}
        >
          <AccordionTrigger
            className={cn(
              "duration-250 rounded-lg transition ease-in-out hover:-translate-y-1 hover:scale-105 hover:bg-accent",
            )}
          >
            <div className="mr-2 flex w-full items-center justify-between">
              <span className="pl-2 text-left">
                {category.name}
                {" "}
              </span>
              <span className="rounded-full bg-gray-200 px-2 py-1 text-xs text-muted-foreground hover:no-underline dark:bg-blue-800/20">
                {category.scripts.length}
              </span>
            </div>
            {" "}
          </AccordionTrigger>
          <AccordionContent data-state={expandedItem === category.name ? "open" : "closed"} className="pt-0">
            {category.scripts
              .slice()
              .sort((a, b) => a.name.localeCompare(b.name))
              .map((script, index) => (
                <div key={index}>
                  <Link
                    href={{
                      pathname: "/scripts",
                      query: { id: script.slug, category: category.name },
                    }}
                    prefetch={false}
                    className={`flex cursor-pointer items-center justify-between gap-1 px-1 py-1 text-muted-foreground hover:rounded-lg hover:bg-accent/60 hover:dark:bg-accent/20 ${
                      selectedScript === script.slug
                        ? "rounded-lg bg-accent font-semibold dark:bg-accent/30 dark:text-white"
                        : ""
                    }`}
                    onClick={() => {
                      handleSelected(script.slug);
                      setSelectedCategory(category.name);
                    }}
                    ref={(el) => {
                      linkRefs.current[script.slug] = el;
                    }}
                  >
                    <div className="flex items-center">
                      <Image
                        src={script.logo || `/${basePath}/logo.png`}
                        height={16}
                        width={16}
                        unoptimized
                        onError={e => ((e.currentTarget as HTMLImageElement).src = `/${basePath}/logo.png`)}
                        alt={script.name}
                        className="mr-1 w-4 h-4 rounded-full"
                      />
                      <span className="flex items-center gap-2">{script.name}</span>
                    </div>
                    {formattedBadge(script.type)}
                  </Link>
                </div>
              ))}
          </AccordionContent>
        </AccordionItem>
      ))}
    </Accordion>
  );
}
