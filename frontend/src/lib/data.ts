import { Category } from "./types";

const sortCategories = (categories: Category[]) => {
  return categories.sort((a, b) => {
    if (a.name === "Proxmox VE Tools") {
      return -1;
    } else if (b.name === "Proxmox VE Tools") {
      return 1;
    } else if (a.name === "Miscellaneous") {
      return 1;
    } else if (b.name === "Miscellaneous") {
      return -1;
    } else {
      return a.name.localeCompare(b.name);
    }
  });
};

export const fetchCategories = async (): Promise<Category[]> => {
  const response = await fetch("api/categories");
  const categories = await response.json();
  return sortCategories(categories);
};
