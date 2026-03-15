import type { Script } from "./types";

export type ScriptType = "ct" | "vm" | "pve" | "addon" | "turnkey";
export type StatusFilter = "all" | "active" | "deprecated";

export interface FilterState {
  search: string;
  types: ScriptType[];
  categoryIds: number[];
  status: StatusFilter;
  minCpu: number | null;
  maxCpu: number | null;
  minRam: number | null;
  maxRam: number | null;
}

export const DEFAULT_FILTER_STATE: FilterState = {
  search: "",
  types: [],
  categoryIds: [],
  status: "all",
  minCpu: null,
  maxCpu: null,
  minRam: null,
  maxRam: null,
};

/**
 * Filter scripts based on search text
 */
export function filterBySearch(scripts: Script[], search: string): Script[] {
  if (!search.trim()) return scripts;

  const searchLower = search.toLowerCase().trim();

  return scripts.filter((script) => {
    // Search in name
    if (script.name.toLowerCase().includes(searchLower)) return true;

    // Search in description
    if (script.description.toLowerCase().includes(searchLower)) return true;

    // Search in slug
    if (script.slug.toLowerCase().includes(searchLower)) return true;

    return false;
  });
}

/**
 * Filter scripts by type (ct, vm, pve, addon, turnkey)
 */
export function filterByType(scripts: Script[], types: ScriptType[]): Script[] {
  if (!types.length) return scripts;

  return scripts.filter((script) => types.includes(script.type as ScriptType));
}

/**
 * Filter scripts by category IDs
 */
export function filterByCategories(
  scripts: Script[],
  categoryIds: number[],
  allCategories: { id: number; scripts: Script[] }[]
): Script[] {
  if (!categoryIds.length) return scripts;

  // Get all script slugs from the selected categories
  const categoryScriptSlugs = new Set<string>();

  allCategories.forEach((category) => {
    if (categoryIds.includes(category.id)) {
      category.scripts.forEach((script) => {
        categoryScriptSlugs.add(script.slug);
      });
    }
  });

  return scripts.filter((script) => categoryScriptSlugs.has(script.slug));
}

/**
 * Filter scripts by status (active/deprecated)
 */
export function filterByStatus(
  scripts: Script[],
  status: StatusFilter
): Script[] {
  if (status === "all") return scripts;

  return scripts.filter((script) => {
    if (status === "active") return !script.disable;
    if (status === "deprecated") return script.disable;
    return true;
  });
}

/**
 * Filter scripts by CPU cores range
 */
export function filterByCpu(
  scripts: Script[],
  minCpu: number | null,
  maxCpu: number | null
): Script[] {
  if (minCpu === null && maxCpu === null) return scripts;

  return scripts.filter((script) => {
    // Get CPU from first install method
    const cpu = script.install_methods[0]?.resources?.cpu;
    if (cpu === null || cpu === undefined) return true; // Include if no CPU specified

    if (minCpu !== null && cpu < minCpu) return false;
    if (maxCpu !== null && cpu > maxCpu) return false;

    return true;
  });
}

/**
 * Filter scripts by RAM range (in MB)
 */
export function filterByRam(
  scripts: Script[],
  minRam: number | null,
  maxRam: number | null
): Script[] {
  if (minRam === null && maxRam === null) return scripts;

  return scripts.filter((script) => {
    // Get RAM from first install method
    const ram = script.install_methods[0]?.resources?.ram;
    if (ram === null || ram === undefined) return true; // Include if no RAM specified

    if (minRam !== null && ram < minRam) return false;
    if (maxRam !== null && ram > maxRam) return false;

    return true;
  });
}

/**
 * Apply all filters to scripts
 */
export function filterScripts(
  scripts: Script[],
  filters: FilterState,
  allCategories: { id: number; scripts: Script[] }[]
): Script[] {
  let result = [...scripts];

  // Apply search filter
  result = filterBySearch(result, filters.search);

  // Apply type filter
  result = filterByType(result, filters.types);

  // Apply category filter
  result = filterByCategories(result, filters.categoryIds, allCategories);

  // Apply status filter
  result = filterByStatus(result, filters.status);

  // Apply CPU filter
  result = filterByCpu(result, filters.minCpu, filters.maxCpu);

  // Apply RAM filter
  result = filterByRam(result, filters.minRam, filters.maxRam);

  return result;
}

/**
 * Check if any filters are active
 */
export function hasActiveFilters(filters: FilterState): boolean {
  return (
    filters.search.trim() !== "" ||
    filters.types.length > 0 ||
    filters.categoryIds.length > 0 ||
    filters.status !== "all" ||
    filters.minCpu !== null ||
    filters.maxCpu !== null ||
    filters.minRam !== null ||
    filters.maxRam !== null
  );
}

/**
 * Get count of active filters
 */
export function getActiveFilterCount(filters: FilterState): number {
  let count = 0;

  if (filters.search.trim()) count++;
  count += filters.types.length;
  count += filters.categoryIds.length;
  if (filters.status !== "all") count++;
  if (filters.minCpu !== null) count++;
  if (filters.maxCpu !== null) count++;
  if (filters.minRam !== null) count++;
  if (filters.maxRam !== null) count++;

  return count;
}

/**
 * Sort scripts by date (newest first)
 */
export function sortScriptsByDate(scripts: Script[]): Script[] {
  return [...scripts].sort(
    (a, b) => new Date(b.date_created).getTime() - new Date(a.date_created).getTime()
  );
}

/**
 * Sort scripts by name (alphabetically)
 */
export function sortScriptsByName(scripts: Script[]): Script[] {
  return [...scripts].sort((a, b) => a.name.localeCompare(b.name));
}

/**
 * Get unique operating systems from scripts
 */
export function getUniqueOperatingSystems(scripts: Script[]): string[] {
  const osSet = new Set<string>();

  scripts.forEach((script) => {
    script.install_methods.forEach((method) => {
      if (method.resources?.os) {
        osSet.add(method.resources.os);
      }
    });
  });

  return Array.from(osSet).sort();
}

/**
 * Get unique script types from scripts
 */
export function getUniqueTypes(scripts: Script[]): ScriptType[] {
  const types = new Set<ScriptType>();
  scripts.forEach((script) => {
    types.add(script.type as ScriptType);
  });
  return Array.from(types);
}
