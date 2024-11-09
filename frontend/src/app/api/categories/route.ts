import { Metadata, Script } from "@/lib/types";
import { promises as fs } from "fs";
import { NextResponse } from "next/server";
import path from "path";

export const dynamic = "force-static";

const jsonDir = "public/json";
const metadataFileName = "metadata.json";
const encoding = "utf-8";

const getMetadata = async () => {
  const filePath = path.resolve(jsonDir, metadataFileName);
  const fileContent = await fs.readFile(filePath, encoding);
  const metadata: Metadata = JSON.parse(fileContent);
  return metadata;
};

const getScripts = async () => {
  const filePaths = (await fs.readdir(jsonDir))
    .filter((fileName) => fileName !== metadataFileName)
    .map((fileName) => path.resolve(jsonDir, fileName));

  const scripts = await Promise.all(
    filePaths.map(async (filePath) => {
      const fileContent = await fs.readFile(filePath, encoding);
      const script: Script = JSON.parse(fileContent);
      return script;
    }),
  );
  return scripts;
};

export async function GET() {
  try {
    const metadata = await getMetadata();
    const scripts = await getScripts();

    const categories = metadata.categories
      .map((category) => {
        category.scripts = scripts.filter((script) =>
          script.categories.includes(category.id),
        );
        return category;
      })
      .sort((a, b) => a.sort_order - b.sort_order);

    return NextResponse.json(categories);
  } catch (error) {
    console.error(error as Error);
    return NextResponse.json(
      { error: "Failed to fetch categories" },
      { status: 500 },
    );
  }
}
