import { basePath } from "@/config/siteConfig";
import { Category, Script } from "@/lib/types";
import { NextResponse } from "next/server";

export const dynamic = "force-static";

const fetchCategories = async (): Promise<Category[]> => {
  const response = await fetch(
    `https://raw.githubusercontent.com/community-scripts/${basePath}/refs/heads/main/json/metadata.json`,
  );
  const data = await response.json();
  return data.categories;
};

const fetchScripts = async (): Promise<Script[]> => {
  const response = await fetch(
    `https://api.github.com/repos/community-scripts/${basePath}/contents/json`,
  );
  const files: { download_url: string }[] = await response.json();
  const scripts = await Promise.all(
    files.map(async (file) : Promise<Script> => {
      const response = await fetch(file.download_url);
      const script = await response.json();
      return script;
    }),
  );
  return scripts;
};

export async function GET() {
  try {
    const categories = await fetchCategories();
    const scripts = await fetchScripts();
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
