"use client";

import React, { useState } from "react";
import { Filter } from "lucide-react";

import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export type QuickfilterType = "all" | "category" | "new" | "updated" | "dev";

interface QuickfilterBarProps {
  totalScripts: number;
  newCount?: number;
  updatedCount?: number;
  devCount?: number;
  selectedCategory?: string | null;
  onCategoryClick?: () => void;
  activeFilter?: QuickfilterType;
  onFilterChange?: (filter: QuickfilterType) => void;
}

const filters: { id: QuickfilterType; label: string; description: string }[] = [
  { id: "all", label: "All Scripts", description: "Browse all available scripts" },
  { id: "category", label: "By Category", description: "Browse scripts by category" },
  { id: "new", label: "New Arrivals", description: "Fresh additions" },
  { id: "updated", label: "Recently Updated", description: "Latest changes" },
  { id: "dev", label: "In Development", description: "Active development" },
];

export function QuickfilterBar({
  totalScripts,
  newCount = 0,
  updatedCount = 0,
  devCount = 0,
  selectedCategory,
  onCategoryClick,
  activeFilter: externalActiveFilter,
  onFilterChange,
}: QuickfilterBarProps) {
  const [internalActiveFilter, setInternalActiveFilter] = useState<QuickfilterType>("all");

  const activeFilter = externalActiveFilter ?? internalActiveFilter;
  const setActiveFilter = (filter: QuickfilterType) => {
    setInternalActiveFilter(filter);
    onFilterChange?.(filter);
  };

  const counts: Record<QuickfilterType, number | undefined> = {
    all: totalScripts,
    category: undefined,
    new: newCount,
    updated: updatedCount,
    dev: devCount,
  };

  const handleFilterClick = (filterId: QuickfilterType) => {
    if (filterId === "category" && onCategoryClick) {
      onCategoryClick();
    } else {
      setActiveFilter(filterId);
    }
  };

  return (
    <div className="mb-6">
      <div className="flex items-center gap-2 mb-3">
        <Filter className="h-4 w-4 text-muted-foreground" />
        <span className="text-sm font-medium text-muted-foreground">Quickfilter</span>
      </div>
      <div className="flex flex-wrap gap-2">
        {filters.map((filter) => {
          const isActive = activeFilter === filter.id;
          const count = counts[filter.id];

          return (
            <Button
              key={filter.id}
              variant={isActive ? "default" : "outline"}
              size="sm"
              onClick={() => handleFilterClick(filter.id)}
              className={cn(
                "transition-all",
                isActive && "bg-primary text-primary-foreground",
              )}
            >
              {filter.label}
              {count !== undefined && count > 0 && (
                <span
                  className={cn(
                    "ml-2 rounded-full px-1.5 py-0.5 text-xs",
                    isActive
                      ? "bg-primary-foreground/20 text-primary-foreground"
                      : "bg-muted text-muted-foreground",
                  )}
                >
                  {count}
                </span>
              )}
            </Button>
          );
        })}
      </div>
      {selectedCategory && (
        <div className="mt-3 flex items-center gap-2">
          <span className="text-sm text-muted-foreground">Category:</span>
          <Button
            variant="secondary"
            size="sm"
            onClick={() => setActiveFilter("all")}
          >
            {selectedCategory}
            <span className="ml-2 text-xs">×</span>
          </Button>
        </div>
      )}
    </div>
  );
}
