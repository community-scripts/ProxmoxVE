"use client";

import { useState, useCallback } from "react";
import { useQueryState } from "nuqs";
import { Filter, X, ChevronDown, ChevronUp } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";
import type { Category, Script } from "@/lib/types";

type ScriptType = "ct" | "vm" | "pve" | "addon" | "turnkey";
type StatusFilter = "all" | "active" | "deprecated";

interface AdvancedFilterProps {
  categories: Category[];
  className?: string;
}

const SCRIPT_TYPES: { value: ScriptType; label: string }[] = [
  { value: "ct", label: "LXC Container" },
  { value: "vm", label: "Virtual Machine" },
  { value: "pve", label: "Proxmox VE" },
  { value: "addon", label: "Addon" },
  { value: "turnkey", label: "TurnKey" },
];

const STATUS_OPTIONS: { value: StatusFilter; label: string }[] = [
  { value: "all", label: "All Scripts" },
  { value: "active", label: "Active Only" },
  { value: "deprecated", label: "Deprecated Only" },
];

export function AdvancedFilter({ categories, className }: AdvancedFilterProps) {
  const [isExpanded, setIsExpanded] = useState(false);

  // URL state for filters
  const [types, setTypes] = useQueryState("types");
  const [categoryIds, setCategoryIds] = useQueryState("categories");
  const [status, setStatus] = useQueryState("status");
  const [minCpu, setMinCpu] = useQueryState("minCpu");
  const [maxCpu, setMaxCpu] = useQueryState("maxCpu");
  const [minRam, setMinRam] = useQueryState("minRam");
  const [maxRam, setMaxRam] = useQueryState("maxRam");

  // Parse current values
  const selectedTypes = types?.split(",").filter(Boolean) as ScriptType[] || [];
  const selectedCategoryIds = categoryIds?.split(",").filter(Boolean).map(Number) || [];
  const currentStatus = (status as StatusFilter) || "all";

  // Count active filters
  const activeFilterCount =
    selectedTypes.length +
    selectedCategoryIds.length +
    (status && status !== "all" ? 1 : 0) +
    (minCpu ? 1 : 0) +
    (maxCpu ? 1 : 0) +
    (minRam ? 1 : 0) +
    (maxRam ? 1 : 0);

  const toggleType = useCallback((type: ScriptType) => {
    const newTypes = selectedTypes.includes(type)
      ? selectedTypes.filter((t) => t !== type)
      : [...selectedTypes, type];
    setTypes(newTypes.length > 0 ? newTypes.join(",") : null);
  }, [selectedTypes, setTypes]);

  const toggleCategory = useCallback((categoryId: number) => {
    const newCategoryIds = selectedCategoryIds.includes(categoryId)
      ? selectedCategoryIds.filter((id) => id !== categoryId)
      : [...selectedCategoryIds, categoryId];
    setCategoryIds(newCategoryIds.length > 0 ? newCategoryIds.join(",") : null);
  }, [selectedCategoryIds, setCategoryIds]);

  const clearAllFilters = useCallback(() => {
    setTypes(null);
    setCategoryIds(null);
    setStatus(null);
    setMinCpu(null);
    setMaxCpu(null);
    setMinRam(null);
    setMaxRam(null);
  }, [setTypes, setCategoryIds, setStatus, setMinCpu, setMaxCpu, setMinRam, setMaxRam]);

  return (
    <div className={cn("space-y-4", className)}>
      {/* Filter Toggle Button */}
      <div className="flex items-center justify-between">
        <Button
          variant="outline"
          onClick={() => setIsExpanded(!isExpanded)}
          className="border-rust/30 hover:border-brass"
        >
          <Filter className="mr-2 h-4 w-4" />
          Advanced Filters
          {activeFilterCount > 0 && (
            <Badge variant="secondary" className="ml-2 bg-copper/20 text-copper">
              {activeFilterCount}
            </Badge>
          )}
          {isExpanded ? (
            <ChevronUp className="ml-2 h-4 w-4" />
          ) : (
            <ChevronDown className="ml-2 h-4 w-4" />
          )}
        </Button>

        {activeFilterCount > 0 && (
          <Button
            variant="ghost"
            size="sm"
            onClick={clearAllFilters}
            className="text-muted-foreground hover:text-foreground"
          >
            <X className="mr-1 h-4 w-4" />
            Clear Filters
          </Button>
        )}
      </div>

      {/* Expanded Filter Panel */}
      {isExpanded && (
        <div className="grid gap-6 rounded-lg border border-rust/30 bg-card/50 p-4 md:grid-cols-2 lg:grid-cols-4">
          {/* Script Type Filter */}
          <div className="space-y-2">
            <Label className="text-copper">Script Type</Label>
            <div className="flex flex-wrap gap-2">
              {SCRIPT_TYPES.map((type) => (
                <Badge
                  key={type.value}
                  variant={selectedTypes.includes(type.value) ? "default" : "outline"}
                  className={cn(
                    "cursor-pointer transition-colors",
                    selectedTypes.includes(type.value)
                      ? "bg-brass text-background hover:bg-brass/90"
                      : "border-rust/30 hover:border-brass"
                  )}
                  onClick={() => toggleType(type.value)}
                >
                  {type.label}
                </Badge>
              ))}
            </div>
          </div>

          {/* Category Filter */}
          <div className="space-y-2">
            <Label className="text-copper">Categories</Label>
            <div className="max-h-32 overflow-y-auto">
              <div className="flex flex-wrap gap-2">
                {categories.map((category) => (
                  <Badge
                    key={category.id}
                    variant={selectedCategoryIds.includes(category.id) ? "default" : "outline"}
                    className={cn(
                      "cursor-pointer transition-colors",
                      selectedCategoryIds.includes(category.id)
                        ? "bg-brass text-background hover:bg-brass/90"
                        : "border-rust/30 hover:border-brass"
                    )}
                    onClick={() => toggleCategory(category.id)}
                  >
                    {category.name}
                  </Badge>
                ))}
              </div>
            </div>
          </div>

          {/* Status Filter */}
          <div className="space-y-2">
            <Label className="text-copper">Status</Label>
            <Select
              value={currentStatus}
              onValueChange={(value) => setStatus(value === "all" ? null : value)}
            >
              <SelectTrigger className="border-rust/30 focus:border-brass">
                <SelectValue placeholder="Select status" />
              </SelectTrigger>
              <SelectContent>
                {STATUS_OPTIONS.map((option) => (
                  <SelectItem key={option.value} value={option.value}>
                    {option.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {/* Resource Filters */}
          <div className="space-y-3">
            <Label className="text-copper">Resources</Label>

            {/* CPU Range */}
            <div className="flex items-center gap-2">
              <Input
                type="number"
                placeholder="Min CPU"
                value={minCpu || ""}
                onChange={(e) => setMinCpu(e.target.value || null)}
                className="h-8 w-20 border-rust/30 focus:border-brass"
                min={1}
              />
              <span className="text-muted-foreground">-</span>
              <Input
                type="number"
                placeholder="Max CPU"
                value={maxCpu || ""}
                onChange={(e) => setMaxCpu(e.target.value || null)}
                className="h-8 w-20 border-rust/30 focus:border-brass"
                min={1}
              />
              <span className="text-xs text-muted-foreground">cores</span>
            </div>

            {/* RAM Range */}
            <div className="flex items-center gap-2">
              <Input
                type="number"
                placeholder="Min RAM"
                value={minRam || ""}
                onChange={(e) => setMinRam(e.target.value || null)}
                className="h-8 w-20 border-rust/30 focus:border-brass"
                min={128}
              />
              <span className="text-muted-foreground">-</span>
              <Input
                type="number"
                placeholder="Max RAM"
                value={maxRam || ""}
                onChange={(e) => setMaxRam(e.target.value || null)}
                className="h-8 w-20 border-rust/30 focus:border-brass"
                min={128}
              />
              <span className="text-xs text-muted-foreground">MB</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
