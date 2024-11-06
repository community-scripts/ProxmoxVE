import { basePath } from "@/config/siteConfig";
import { Category, Script } from "@/lib/types";
import { NextResponse } from "next/server";

export const dynamic = "force-static";

const fetchCategories = async () => {
  const response = await fetch(
    `https://raw.githubusercontent.com/community-scripts/${basePath}/refs/heads/main/json/metadata.json`,
  );
  const data = await response.json();
  return data.categories;
}

const fetchAllMetaDataFiles = async () => {
  const response = await fetch(
    `https://api.github.com/repos/community-scripts/${basePath}/contents/json`,
  );
  const files = await response.json();
  const scripts: Script[] = [];
  for (const file of files) {
    const response = await fetch(file.download_url);
    const script = await response.json();
    scripts.push(script);
  }
  return scripts;
}

export async function GET() {
  try {
    const categories: Category[] = await fetchCategories();
    const scripts: Script[] = await fetchAllMetaDataFiles();
    for (const category of categories) {
      category.scripts = scripts.filter((script) => script.categories.includes(category.id));
    }
    return NextResponse.json(categories);
  } catch (error) {
    console.error(error as Error);
    return NextResponse.json(
      { error: "Failed to fetch categories" },
      { status: 500 },
    );
  }
}
