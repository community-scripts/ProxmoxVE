import PocketBase from "pocketbase";
import { Category } from "./types";

export const pb = new PocketBase(process.env.NEXT_PUBLIC_POCKETBASE_URL);
export const pbBackup = new PocketBase(
  process.env.NEXT_PUBLIC_POCKETBASE_URL_BACKUP,
);

export const getImageURL = (recordId: string, fileName: string) => {
  return `${process.env.NEXT_PUBLIC_POCKETBASE_URL}/${recordId}/${fileName}`;
};

const sortCategories = (categories: Category[]) => {
  const sortedCategories = categories.sort((a, b) => {
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

  return sortedCategories;
};

export const fetchCategories = async () => {
  const categories = await fetch(`api/categories`).then((response) => response.json());
  return sortCategories(categories)
}
