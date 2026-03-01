"use client";

import { X, HelpCircle } from "lucide-react";
import { Suspense } from "react";
import Image from "next/image";

import type { AppVersion } from "@/lib/types";
import type { Script } from "@/app/json-editor/_schemas/schemas";

import { Separator } from "@/components/ui/separator";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import { useVersions } from "@/hooks/use-versions";
import { basePath } from "@/config/site-config";
import { extractDate } from "@/lib/time";

import DisableDescription from "./script-items/disable-description";
import { getDisplayValueFromType } from "./script-info-blocks";
import DefaultPassword from "./script-items/default-password";
import InstallCommand from "./script-items/install-command";
import { ResourceDisplay } from "./resource-display";
import Description from "./script-items/description";
import ConfigFile from "./script-items/config-file";
import InterFaces from "./script-items/interfaces";
import Tooltips from "./script-items/tool-tips";
import Buttons from "./script-items/buttons";
import Alerts from "./script-items/alerts";

type ScriptItemProps = {
  item: Script;
};

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
            onError={e => ((e.currentTarget as HTMLImageElement).src = `/${basePath}/logo.png`)}
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
                  <span>
                    Added
                    {" "}
                    {extractDate(item.date_created)}
                  </span>
                  <span>•</span>
                  <span className=" capitalize">
                    {os}
                    {" "}
                    {version}
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
              {item.install_methods.find(method => method.type === "alpine")?.resources && (
                <ResourceDisplay
                  title="Alpine"
                  {...item.install_methods.find(method => method.type === "alpine")!.resources!}
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
    return null;
  }

  const matchedVersion = versions.find((v: AppVersion) => v.slug === item.slug);

  if (!matchedVersion)
    return null;

  return (
    <span className="font-medium text-sm flex items-center gap-1">
      {matchedVersion.version}
      {matchedVersion.pinned && (
        <TooltipProvider>
          <Tooltip>
            <TooltipTrigger asChild>
              <HelpCircle className="h-3.5 w-3.5 text-muted-foreground cursor-help" />
            </TooltipTrigger>
            <TooltipContent className="max-w-xs">
              <p>This version is pinned. We test each update for breaking changes before releasing new versions.</p>
            </TooltipContent>
          </Tooltip>
        </TooltipProvider>
      )}
    </span>
  );
}

export function ScriptItem({ item }: ScriptItemProps) {
  return (
    <div className="w-full mx-auto">
      <div className="flex w-full flex-col">
        <div className="rounded-xl border border-border bg-accent/30 backdrop-blur-sm shadow-sm">
          <div className="p-6 space-y-6">
            <Suspense fallback={<div className="animate-pulse h-32 bg-accent/20 rounded-xl" />}>
              <ScriptHeader item={item} />
            </Suspense>

            {item.disable && item.disable_description && (
              <DisableDescription item={item} />
            )}

            {!item.disable && (
              <>
                <Description item={item} />

                <Alerts item={item} />
                <div className="mt-4 rounded-lg border shadow-sm">
                  <div className="flex gap-3 px-4 py-2 bg-accent/25">
                    <h2 className="text-lg font-semibold">
                      How to
                      {" "}
                      {item.type === "pve" ? "use" : item.type === "addon" ? "apply" : "install"}
                    </h2>
                    <Tooltips item={item} />
                  </div>
                  <Separator />
                  <div className="">
                    <InstallCommand item={item} />
                  </div>
                  {item.config_path && (
                    <>
                      <Separator />
                      <div className="flex gap-3 px-4 py-2 bg-accent/25">
                        <h2 className="text-lg font-semibold">Location of config file</h2>
                      </div>
                      <Separator />
                      <div className="">
                        <ConfigFile configPath={item.config_path} />
                      </div>
                    </>
                  )}
                </div>

                <DefaultPassword item={item} />
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
