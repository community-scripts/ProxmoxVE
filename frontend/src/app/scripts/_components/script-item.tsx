"use client";

import { X, Monitor, Smartphone, Cloud, Boxes, Terminal, MousePointerClick, CalendarDays, Globe, BookOpenText, Code, Stars } from "lucide-react";
import { motion } from "framer-motion";
import { Suspense } from "react";
import Image from "next/image";

import type { AppVersion, Script } from "@/lib/types";

import { cleanSlug } from "@/lib/utils/resource-utils";
import { Separator } from "@/components/ui/separator";
import { useVersions } from "@/hooks/use-versions";
import { basePath } from "@/config/site-config";
import { extractDate } from "@/lib/time";

// import { getDisplayValueFromType } from "./script-info-blocks";
import DefaultPassword from "./script-items/default-password";
import InstallCommand from "./script-items/install-command";
import Description from "./script-items/description";
import ConfigFile from "./script-items/config-file";
import InterFaces from "./script-items/interfaces";
import Alerts from "./script-items/alerts";

type ScriptItemProps = {
  item: Script;
  setSelectedScript: (script: string | null) => void;
};

// ---- Helper Platform ----
type PlatformInfo = {
  desktop?: { linux?: boolean; windows?: boolean; macos?: boolean };
  mobile?: { android?: boolean; ios?: boolean };
  web_app?: boolean;
  browser_extension?: boolean;
  cli_only?: boolean;
  hosting?: { self_hosted?: boolean; saas?: boolean; managed_cloud?: boolean };
  deployment?: {
    script?: boolean;
    docker?: boolean;
    docker_compose?: boolean;
    helm ?: boolean;
    kubernetes?: boolean;
    terraform?: boolean;
  };
  ui?: { cli?: boolean; gui?: boolean; web_ui?: boolean; api?: boolean; tui?: boolean };
};

type InstallMethodWithPlatform = Script["install_methods"][0] & {
  platform?: PlatformInfo;
};

function SecondaryMeta({ item }: { item: Script }) {
  const parts: { label: string; href?: string; icon: React.ReactNode }[] = [];

  // 🗓 Added
  if (item.date_created) {
    parts.push({
      label: `Added ${extractDate(item.date_created)}`,
      icon: <CalendarDays className="h-4 w-4 text-muted-foreground" />,
    });
  }

  // 🌐 Website
  if (item.website) {
    parts.push({
      label: "Website",
      href: item.website,
      icon: <Globe className="h-4 w-4 text-muted-foreground" />,
    });
  }

  // 📖 Docs
  if (item.documentation) {
    parts.push({
      label: "Docs",
      href: item.documentation,
      icon: <BookOpenText className="h-4 w-4 text-muted-foreground" />,
    });
  }

  // 💻 Source code
  const sourceCode = (item as any).source_code;
  if (sourceCode) {
    parts.push({
      label: "Source code",
      href: sourceCode,
      icon: <Code className="h-4 w-4 text-muted-foreground" />,
    });
  }

  // ⭐ Github stars
  const githubStars = (item as any).github_stars;
  if (githubStars) {
    parts.push({
      label: githubStars,
      href: "",
      icon: <Stars className="h-4 w-4 text-muted-foreground" />,
    });
  }

  if (!parts.length) return null;

  return (
    <motion.div
      initial={{ opacity: 0, y: -3 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, ease: "easeOut" }}
      className="mt-1 mb-1 flex flex-wrap items-center gap-3 text-sm text-muted-foreground"
    >
      {parts.map((p, i) => (
        <div
          key={p.label}
          className="flex items-center gap-1.5 group transition-colors"
        >
          {i > 0 && <span className="mx-1 text-muted-foreground/60">•</span>}
          <span className="flex items-center gap-1.5">
            {p.icon}
            {p.href ? (
              <a
                href={p.href}
                target="_blank"
                rel="noopener noreferrer"
                className="rounded-md bg-accent/10 px-2 py-0.5 text-primary transition-all hover:bg-accent/20 hover:text-primary"
              >
                {p.label}
              </a>
            ) : (
              <span>{p.label}</span>
            )}
          </span>
        </div>
      ))}
    </motion.div>
  );
}

function PlatformRow({
  label,
  items,
  icon,
}: {
  label: string;
  items: string[];
  icon: React.ReactNode;
}) {
  if (!items.length) return null;

  return (
    <div className="flex items-center gap-2 text-xs text-muted-foreground">
      {icon}
      <span className="w-16 shrink-0 text-[11px] uppercase tracking-wide text-muted-foreground">
        {label}
      </span>
      <div className="flex flex-wrap gap-1.5">
        {items.map((item) => (
          <span
            key={item}
            className="rounded-full border px-2 py-0.5 text-[10px] leading-none font-medium"
          >
            {item}
          </span>
        ))}
      </div>
    </div>
  );
}

function PlatformSummary({ method }: { method?: InstallMethodWithPlatform }) {
  const platform = method?.platform;
  if (!platform) return null;

  const desktop = [
    platform.desktop?.macos && "macOS",
    platform.desktop?.linux && "Linux",
    platform.desktop?.windows && "Windows",
  ].filter(Boolean) as string[];

  const mobile = [
    platform.mobile?.android && "Android",
    platform.mobile?.ios && "iOS",
  ].filter(Boolean) as string[];

  const hosting = [
    platform.hosting?.saas && "SaaS",
    platform.hosting?.self_hosted && "Self-hosted",
    platform.hosting?.managed_cloud && "Managed cloud",
  ].filter(Boolean) as string[];

  const deployment = [
    platform.deployment?.script && "Script",
    platform.deployment?.docker && "Docker",
    platform.deployment?.docker_compose && "Docker Compose",
    platform.deployment?.helm && "Helm",
    platform.deployment?.kubernetes && "Kubernetes",
    platform.deployment?.terraform && "Terraform",
  ].filter(Boolean) as string[];

  const ui = [
    platform.ui?.cli && "CLI",
    platform.ui?.tui && "TUI",
    platform.ui?.gui && "GUI",
    platform.ui?.web_ui && "Web UI",
    platform.ui?.api && "API",
  ].filter(Boolean) as string[];

  const interfaceIcon = platform.cli_only ? (
    <Terminal className="h-3 w-3 shrink-0" />
  ) : (
    <MousePointerClick className="h-3 w-3 shrink-0" />
  );

  if (!desktop.length && !mobile.length && !hosting.length && !deployment.length && !ui.length) {
    return null;
  }

  return (
    <div className="mt-3 flex flex-col space-y-2">
      <div className="text-[11px] font-semibold uppercase text-muted-foreground">
        Platform
      </div>
      <PlatformRow
        label="Desktop"
        items={desktop}
        icon={<Monitor className="h-3 w-3 shrink-0" />}
      />
      <PlatformRow
        label="Mobile"
        items={mobile}
        icon={<Smartphone className="h-3 w-3 shrink-0" />}
      />
      <PlatformRow
        label="Hosting"
        items={hosting}
        icon={<Cloud className="h-3 w-3 shrink-0" />}
      />
      <PlatformRow
        label="Deploy"
        items={deployment}
        icon={<Boxes className="h-3 w-3 shrink-0" />}
      />
      <PlatformRow label="Interface" items={ui} icon={interfaceIcon} />
    </div>
  );
}

function ScriptHeader({ item }: { item: Script }) {
  const defaultInstallMethod = item.install_methods?.[0] as InstallMethodWithPlatform | undefined;

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
                  {/* <span className="inline-flex items-center rounded-md bg-accent/30 px-2 py-1 text-sm">
                    {getDisplayValueFromType(item.type)}
                  </span> */}
                </h1>

                {/* META: Added • homepage • github repo */}
                <SecondaryMeta item={item} />
                <hr className="border-border/40 my-2" />
              </div>
            </div>

            <PlatformSummary method={defaultInstallMethod} />
          </div>
        </div>
      </div>
      <div className="flex flex-col gap-4 justify-between">
        <InterFaces item={item} />
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
          <h2 className="text-2xl font-semibold tracking-tight text-foreground/90">
            Selected Script
          </h2>
          <button
            onClick={closeScript}
            className="rounded-full p-2 text-muted-foreground hover:bg-card/50 transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="rounded-xl border border-border bg-accent/30 backdrop-blur-sm shadow-sm">
          <div className="p-6 space-y-6">
            <Suspense fallback={<div className="animate-pulse h-32 bg-accent/20 rounded-xl" />}>
              <ScriptHeader item={item} />
            </Suspense>

            <Description item={item} />
            <Alerts item={item} />

            <div className="mt-4 rounded-lg border shadow-sm">
              <div className="flex gap-3 px-4 py-2 bg-accent/25">
                <h2 className="text-lg font-semibold">
                  How to Install
                </h2>
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
          </div>
        </div>
      </div>
    </div>
  );
}
