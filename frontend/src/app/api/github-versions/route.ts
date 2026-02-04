import { NextResponse } from "next/server";
import { promises as fs } from "node:fs";
import path from "node:path";

import type { GitHubVersionsResponse } from "@/lib/types";

export const dynamic = "force-static";

const jsonDir = "public/json";
const versionsFileName = "github-versions.json";
const encoding = "utf-8";

async function getVersions(): Promise<GitHubVersionsResponse> {
  const filePath = path.resolve(jsonDir, versionsFileName);
  const fileContent = await fs.readFile(filePath, encoding);
  const data: GitHubVersionsResponse = JSON.parse(fileContent);
  return data;
}

export async function GET() {
  try {
    const versions = await getVersions();
    return NextResponse.json(versions);
  }
  catch (error) {
    console.error(error);
    const err = error as globalThis.Error;
    return NextResponse.json({
      generated: "",
      versions: [],
      error: err.message || "An unexpected error occurred",
    }, {
      status: 500,
    });
  }
}
