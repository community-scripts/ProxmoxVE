"use client";

import { useState } from "react";
import { ChevronDown, Filter, X } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

export type FilterState = {
  platforms: Set<string>;
  deployments: Set<string>;
  hosting: Set<string>;
  ui: Set<string>;
};

type ScriptFiltersProps = {
  filters: FilterState;
  onFilterChange: (filters: FilterState) => void;
};

const platformOptions = [
  { id: "desktop-linux", label: "Linux", category: "platforms" },
  { id: "desktop-windows", label: "Windows", category: "platforms" },
  { id: "desktop-macos", label: "macOS", category: "platforms" },
  { id: "mobile-android", label: "Android", category: "platforms" },
  { id: "mobile-ios", label: "iOS", category: "platforms" },
  { id: "web_app", label: "Web App", category: "platforms" },
  { id: "browser_extension", label: "Browser Extension", category: "platforms" },
  { id: "cli_only", label: "CLI Only", category: "platforms" },
];

const deploymentOptions = [
  { id: "script", label: "Script" },
  { id: "docker", label: "Docker" },
  { id: "docker_compose", label: "Docker Compose" },
  { id: "helm", label: "Helm" },
  { id: "kubernetes", label: "Kubernetes" },
  { id: "terraform", label: "Terraform" },
];

const hostingOptions = [
  { id: "self_hosted", label: "Self-hosted" },
  { id: "managed_cloud", label: "Managed Cloud" },
];

const uiOptions = [
  { id: "cli", label: "CLI" },
  { id: "gui", label: "GUI" },
  { id: "web_ui", label: "Web UI" },
  { id: "api", label: "API" },
  { id: "tui", label: "TUI" },
];

export function ScriptFilters({ filters, onFilterChange }: ScriptFiltersProps) {
  const [openDropdown, setOpenDropdown] = useState<string | null>(null);

  const toggleFilter = (category: keyof FilterState, value: string) => {
    const newFilters = { ...filters };
    const filterSet = new Set(newFilters[category]);

    if (filterSet.has(value)) {
      filterSet.delete(value);
    } else {
      filterSet.add(value);
    }

    newFilters[category] = filterSet;
    onFilterChange(newFilters);
  };

  const removeFilter = (category: keyof FilterState, value: string) => {
    const newFilters = { ...filters };
    const filterSet = new Set(newFilters[category]);
    filterSet.delete(value);
    newFilters[category] = filterSet;
    onFilterChange(newFilters);
  };

  const clearAllFilters = () => {
    onFilterChange({
      platforms: new Set(),
      deployments: new Set(),
      hosting: new Set(),
      ui: new Set(),
    });
  };

  const totalActiveFilters =
    filters.platforms.size +
    filters.deployments.size +
    filters.hosting.size +
    filters.ui.size;

  const getActiveFilters = (): { category: keyof FilterState; value: string; label: string }[] => {
    const active: { category: keyof FilterState; value: string; label: string }[] = [];

    filters.platforms.forEach(value => {
      const option = platformOptions.find(opt => opt.id === value);
      if (option) active.push({ category: "platforms", value, label: option.label });
    });

    filters.deployments.forEach(value => {
      const option = deploymentOptions.find(opt => opt.id === value);
      if (option) active.push({ category: "deployments", value, label: option.label });
    });

    filters.hosting.forEach(value => {
      const option = hostingOptions.find(opt => opt.id === value);
      if (option) active.push({ category: "hosting", value, label: option.label });
    });

    filters.ui.forEach(value => {
      const option = uiOptions.find(opt => opt.id === value);
      if (option) active.push({ category: "ui", value, label: option.label });
    });

    return active;
  };

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        {/* Platform Filter */}
        <DropdownMenu open={openDropdown === "platforms"} onOpenChange={(open) => setOpenDropdown(open ? "platforms" : null)}>
          <DropdownMenuTrigger asChild>
            <Button
              variant={filters.platforms.size > 0 ? "default" : "outline"}
              size="sm"
              className={`h-9 ${filters.platforms.size > 0 ? 'ring-2 ring-primary/20 shadow-md font-semibold' : ''}`}
            >
              <Filter className="h-3.5 w-3.5 mr-2" />
              Platform
              {filters.platforms.size > 0 && (
                <Badge variant="secondary" className="ml-2 h-5 w-5 rounded-full p-0 flex items-center justify-center bg-background/90 text-foreground font-bold">
                  {filters.platforms.size}
                </Badge>
              )}
              <ChevronDown className="h-3.5 w-3.5 ml-2" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="start" className="w-56 bg-popover/95 backdrop-blur-sm border-2">
            <DropdownMenuLabel>Platform</DropdownMenuLabel>
            <DropdownMenuSeparator />
            {platformOptions.map(option => (
              <DropdownMenuCheckboxItem
                key={option.id}
                checked={filters.platforms.has(option.id)}
                onCheckedChange={() => toggleFilter("platforms", option.id)}
              >
                {option.label}
              </DropdownMenuCheckboxItem>
            ))}
          </DropdownMenuContent>
        </DropdownMenu>

        {/* Deployment Filter */}
        <DropdownMenu open={openDropdown === "deployments"} onOpenChange={(open) => setOpenDropdown(open ? "deployments" : null)}>
          <DropdownMenuTrigger asChild>
            <Button
              variant={filters.deployments.size > 0 ? "default" : "outline"}
              size="sm"
              className={`h-9 ${filters.deployments.size > 0 ? 'ring-2 ring-primary/20 shadow-md font-semibold' : ''}`}
            >
              <Filter className="h-3.5 w-3.5 mr-2" />
              Deployment
              {filters.deployments.size > 0 && (
                <Badge variant="secondary" className="ml-2 h-5 w-5 rounded-full p-0 flex items-center justify-center bg-background/90 text-foreground font-bold">
                  {filters.deployments.size}
                </Badge>
              )}
              <ChevronDown className="h-3.5 w-3.5 ml-2" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="start" className="w-56 bg-popover/95 backdrop-blur-sm border-2">
            <DropdownMenuLabel>Deployment Method</DropdownMenuLabel>
            <DropdownMenuSeparator />
            {deploymentOptions.map(option => (
              <DropdownMenuCheckboxItem
                key={option.id}
                checked={filters.deployments.has(option.id)}
                onCheckedChange={() => toggleFilter("deployments", option.id)}
              >
                {option.label}
              </DropdownMenuCheckboxItem>
            ))}
          </DropdownMenuContent>
        </DropdownMenu>

        {/* Hosting Filter */}
        <DropdownMenu open={openDropdown === "hosting"} onOpenChange={(open) => setOpenDropdown(open ? "hosting" : null)}>
          <DropdownMenuTrigger asChild>
            <Button
              variant={filters.hosting.size > 0 ? "default" : "outline"}
              size="sm"
              className={`h-9 ${filters.hosting.size > 0 ? 'ring-2 ring-primary/20 shadow-md font-semibold' : ''}`}
            >
              <Filter className="h-3.5 w-3.5 mr-2" />
              Hosting
              {filters.hosting.size > 0 && (
                <Badge variant="secondary" className="ml-2 h-5 w-5 rounded-full p-0 flex items-center justify-center bg-background/90 text-foreground font-bold">
                  {filters.hosting.size}
                </Badge>
              )}
              <ChevronDown className="h-3.5 w-3.5 ml-2" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="start" className="w-56 bg-popover/95 backdrop-blur-sm border-2">
            <DropdownMenuLabel>Hosting Type</DropdownMenuLabel>
            <DropdownMenuSeparator />
            {hostingOptions.map(option => (
              <DropdownMenuCheckboxItem
                key={option.id}
                checked={filters.hosting.has(option.id)}
                onCheckedChange={() => toggleFilter("hosting", option.id)}
              >
                {option.label}
              </DropdownMenuCheckboxItem>
            ))}
          </DropdownMenuContent>
        </DropdownMenu>

        {/* UI Filter */}
        <DropdownMenu open={openDropdown === "ui"} onOpenChange={(open) => setOpenDropdown(open ? "ui" : null)}>
          <DropdownMenuTrigger asChild>
            <Button
              variant={filters.ui.size > 0 ? "default" : "outline"}
              size="sm"
              className={`h-9 ${filters.ui.size > 0 ? 'ring-2 ring-primary/20 shadow-md font-semibold' : ''}`}
            >
              <Filter className="h-3.5 w-3.5 mr-2" />
              Interface
              {filters.ui.size > 0 && (
                <Badge variant="secondary" className="ml-2 h-5 w-5 rounded-full p-0 flex items-center justify-center bg-background/90 text-foreground font-bold">
                  {filters.ui.size}
                </Badge>
              )}
              <ChevronDown className="h-3.5 w-3.5 ml-2" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="start" className="w-56 bg-popover/95 backdrop-blur-sm border-2">
            <DropdownMenuLabel>User Interface</DropdownMenuLabel>
            <DropdownMenuSeparator />
            {uiOptions.map(option => (
              <DropdownMenuCheckboxItem
                key={option.id}
                checked={filters.ui.has(option.id)}
                onCheckedChange={() => toggleFilter("ui", option.id)}
              >
                {option.label}
              </DropdownMenuCheckboxItem>
            ))}
          </DropdownMenuContent>
        </DropdownMenu>

        {/* Clear All Filters */}
        {totalActiveFilters > 0 && (
          <Button
            variant="ghost"
            size="sm"
            onClick={clearAllFilters}
            className="h-9 text-muted-foreground hover:text-foreground"
          >
            Clear all ({totalActiveFilters})
          </Button>
        )}
      </div>

      {/* Active Filters as Badges */}
      {totalActiveFilters > 0 && (
        <div className="flex flex-wrap gap-2">
          {getActiveFilters().map(({ category, value, label }) => (
            <Badge
              key={`${category}-${value}`}
              variant="default"
              className="pl-3 pr-2 py-1.5 text-xs font-medium shadow-sm ring-1 ring-primary/10"
            >
              {label}
              <button
                onClick={() => removeFilter(category, value)}
                className="ml-2 rounded-full hover:bg-background/20 p-0.5 transition-colors"
              >
                <X className="h-3 w-3" />
              </button>
            </Badge>
          ))}
        </div>
      )}
    </div>
  );
}
