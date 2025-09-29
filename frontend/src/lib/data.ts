import type { Category } from "./types";

export async function fetchCategories() {
  const response = await fetch(`/ProxmoxVE/api/categories`);
  if (!response.ok) {
    throw new Error(`Failed to fetch categories: ${response.statusText}`);
  }
  const categories: Category[] = await response.json();
  return categories;
}

export async function fetchVersions() {
  const response = await fetch(`/ProxmoxVE/api/versions`);
  if (!response.ok) {
    throw new Error(`Failed to fetch versions: ${response.statusText}`);
  }
  return response.json();
}
