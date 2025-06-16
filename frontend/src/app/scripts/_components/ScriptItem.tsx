"use client";

import { extractDate } from "@/lib/time";
import { AppVersion, Script } from "@/lib/types";

import { X } from "lucide-react";
import Image from "next/image";

import { Separator } from "@/components/ui/separator";
import { basePath } from "@/config/siteConfig";
import { useVersions } from "@/hooks/useVersions";
import { cleanSlug } from "@/lib/utils/resource-utils";
import { Suspense } from "react";
import { ResourceDisplay } from "./ResourceDisplay";
import { getDisplayValueFromType } from "./ScriptInfoBlocks";
import Alerts from "./ScriptItems/Alerts";
import Buttons from "./ScriptItems/Buttons";
import DefaultPassword from "./ScriptItems/DefaultPassword";
import Description from "./ScriptItems/Description";
import InstallCommand from "./ScriptItems/InstallCommand";
import InterFaces from "./ScriptItems/InterFaces";
import Tooltips from "./ScriptItems/Tooltips";
import ConfigFile from "./ScriptItems/ConfigFile";

interface ScriptItemProps {
  item: Script;
  setSelectedScript: (script: string | null) => void;
}

function ScriptHeader({ item }: { item: Script }) {
  const defaultInstallMethod = item.install_methods?.[0];
  const os = defaultInstallMethod?.resources?.os || "Proxmox Node";
  const version = defaultInstallMethod?.resources?.version || "";

  return (
    <div className="flex flex-col lg:flex-row gap-6 w-full">
      <div className="flex flex-col md:flex-row gap-6 flex-grow">
        <div className="flex-shrink-0">
          <Image
            className="h-32 w-32 rounded-xl bg-gradient-to-br from-accent/40 to-accent/60 object-contain p-3 shadow-lg transition-transform hover:scale-105"
            src={item.logo || `/${basePath}/logo.png`}
            width={400}
            onError={(e) => ((e.currentTarget as HTMLImageElement).src = `/${basePath}/logo.png`)}
            height={400}
            alt={item.name}
            unoptimized
          />
        </div>
        <div className="flex flex-col justify-between flex-grow space-y-4">
          <div className="space-y-2">
            <div className="flex items-start justify-between">
              <div>
                <h1 className="text-2xl font-semibold tracking-tight flex items-center gap-2">
                  {item.name}
                  <VersionInfo item={item} />
                  <span className="inline-flex items-center rounded-md bg-accent/30 px-2 py-1 text-sm">
                    {getDisplayValueFromType(item.type)}
                  </span>
                </h1>
                <div className="mt-1 flex items-center gap-3 text-sm text-muted-foreground">
                  <span>Added {extractDate(item.date_created)}</span>
                  <span>•</span>
                  <span className=" capitalize">
                    {os} {version}
                  </span>
                </div>
              </div>
              {/* <VersionInfo item={item} /> */}
            </div>
            <div className="flex flex-col gap-2 text-sm text-muted-foreground">
              {defaultInstallMethod?.resources && (
                <ResourceDisplay
                  title="Default"
                  cpu={defaultInstallMethod.resources.cpu}
                  ram={defaultInstallMethod.resources.ram}
                  hdd={defaultInstallMethod.resources.hdd}
                />
              )}
              {item.install_methods.find((method) => method.type === "alpine")?.resources && (
                <ResourceDisplay
                  title="Alpine"
                  {...item.install_methods.find((method) => method.type === "alpine")!.resources!}
                />
              )}
            </div>
          </div>
        </div>
      </div>
      <div className="flex flex-col gap-4 justify-between">
        <InterFaces item={item} />
        <div className="flex justify-end">
          <Buttons item={item} />
        </div>
      </div>
    </div>
  );
}

function VersionInfo({ item }: { item: Script }) {
  const { data: versions = [], isLoading } = useVersions();

  if (isLoading || versions.length === 0) {
    return <p className="text-sm text-muted-foreground">Loading versions...</p>;
  }

  const matchedVersion = versions.find((v: AppVersion) => {
    const cleanName = v.name.replace(/[^a-z0-9]/gi, "").toLowerCase();
    return cleanName === cleanSlug(item.slug) || cleanName.includes(cleanSlug(item.slug));
  });

  if (!matchedVersion) return null;

  return <span className="font-medium text-sm">{matchedVersion.version}</span>;
}

export function ScriptItem({ item, setSelectedScript }: ScriptItemProps) {
  const closeScript = () => {
    window.history.pushState({}, document.title, window.location.pathname);
    setSelectedScript(null);
  };

  return (
    <div className="w-full mx-auto">
      <div className="flex w-full flex-col">
        <div className="mb-3 flex items-center justify-between">
          <h2 className="text-2xl font-semibold tracking-tight text-foreground/90">Selected Script</h2>
          <button
            onClick={closeScript}
            className="rounded-full p-2 text-muted-foreground hover:bg-card/50 transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="rounded-xl border border-border bg-gradient-to-b from-card/30 to-background/50 backdrop-blur-sm shadow-sm">
          <div className="p-6 space-y-6">
            <Suspense fallback={<div className="animate-pulse h-32 bg-accent/20 rounded-xl" />}>
              <ScriptHeader item={item} />
            </Suspense>

            <Description item={item} />
            <Alerts item={item} />

            <div className="mt-4 rounded-lg border shadow-sm">
              <div className="flex gap-3 px-4 py-2 bg-accent/25">
                <h2 className="text-lg font-semibold">
                  How to {item.type === "pve" ? "use" : item.type === "addon" ? "apply" : "install"}
                </h2>
                <Tooltips item={item} />
              </div>
              <Separator />
              <div className="">
                <InstallCommand item={item} />
              </div>
              <Separator />
              <div className="flex gap-3 px-4 py-2 bg-accent/25">
                <h2 className="text-lg font-semibold">
                  Location of config file
                </h2>
              </div>
              <Separator />
              <div className="">
                <ConfigFile item={item} />
              </div>
            </div>

            <DefaultPassword item={item} />
          </div>
        </div>
      </div>
    </div>
  );
}
