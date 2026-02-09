// import Error from "next/error";
import { NextResponse } from "next/server";
import { promises as fs } from "node:fs";
import path from "node:path";

export const dynamic = "force-static";

const jsonDir = "public/json";
const versionsFileName = "versions.json";
const encoding = "utf-8";

interface LegacyVersion {
  name: string;
  version: string;
  date: string;
}

async function getVersions() {
  const filePath = path.resolve(jsonDir, versionsFileName);
  const fileContent = await fs.readFile(filePath, encoding);
  const versions: LegacyVersion[] = JSON.parse(fileContent);

  const modifiedVersions = versions.map((version) => {
    let newName = version.name;
    newName = newName.toLowerCase().replace(/[^a-z0-9/]/g, "");
    return { ...version, name: newName, date: new Date(version.date) };
  });

  return modifiedVersions;
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
      name: err.name,
      message: err.message || "An unexpected error occurred",
      version: "No version found - Error",
    }, {
      status: 500,
    });
  }
}
