import { Category } from "./types";

export const fetchCategories = async () => {
  const response = await fetch("api/categories");
  if (!response.ok) {
    throw new Error(`Failed to fetch categories: ${response.statusText}`);
  }
  const categories: Category[] = await response.json();
  return categories;
};
