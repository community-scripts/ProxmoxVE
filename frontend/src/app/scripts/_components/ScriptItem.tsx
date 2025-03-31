
import { Separator } from "@/components/ui/separator";
import { extractDate } from "@/lib/time";
import { Script, AppVersion } from "@/lib/types";
import { fetchVersions } from "@/lib/data";

import { X } from "lucide-react";
import Image from "next/image";

import { getDisplayValueFromType } from "./ScriptInfoBlocks";
import Alerts from "./ScriptItems/Alerts";
import Buttons from "./ScriptItems/Buttons";
import DefaultPassword from "./ScriptItems/DefaultPassword";
import DefaultSettings from "./ScriptItems/DefaultSettings";
import Description from "./ScriptItems/Description";
import InstallCommand from "./ScriptItems/InstallCommand";
import InterFaces from "./ScriptItems/InterFaces";
import Tooltips from "./ScriptItems/Tooltips";
import { basePath } from "@/config/siteConfig";
import { useEffect, useState } from "react";


function ScriptItem({
  item,
  setSelectedScript,
}: {
  item: Script;
  setSelectedScript: (script: string | null) => void;
}) {
  const closeScript = () => {
    window.history.pushState({}, document.title, window.location.pathname);
    setSelectedScript(null);
  };
  const [versions, setVersions] = useState<AppVersion[]>([]);


  useEffect(() => {
    fetchVersions()
      .then((fetchedVersions) => {
        console.log("Fetched Versions: ", fetchedVersions);
        if (Array.isArray(fetchedVersions)) {
          setVersions(fetchedVersions);
        } else if (fetchedVersions && typeof fetchedVersions === "object") {
          setVersions([fetchedVersions]);
        } else {
          setVersions([]);
        }
      })
      .catch((error) => console.error("Error fetching versions:", error));
  }, []);

  const defaultInstallMethod = item.install_methods?.[0];
  const os = defaultInstallMethod?.resources?.os || "Proxmox Node";
  const version = defaultInstallMethod?.resources?.version || "";

  return (
    <div className="mr-7 mt-0 flex w-full min-w-fit">
      <div className="flex w-full min-w-fit">
        <div className="flex w-full flex-col">
          <div className="flex h-[36px] min-w-max items-center justify-between">
            <h2 className="text-lg font-semibold">Selected Script</h2>
            <X onClick={closeScript} className="cursor-pointer" />
          </div>
          <div className="rounded-lg border bg-accent/20 p-4">
            <div className="flex justify-between">
              <div className="flex">
                <Image
                  className="h-32 w-32 rounded-lg bg-accent/60 object-contain p-3 shadow-md"
                  src={item.logo || `/${basePath}/logo.png`}
                  width={400}
                  onError={(e) =>
                  ((e.currentTarget as HTMLImageElement).src =
                    `/${basePath}/logo.png`)
                  }
                  height={400}
                  alt={item.name}
                  unoptimized
                />
                <div className="ml-4 flex flex-col justify-between">
                  <div className="flex h-full w-full flex-col justify-between">
                    <div>
                      <h1 className="text-lg font-semibold">
                        {item.name} {getDisplayValueFromType(item.type)} 
                      </h1>
                      <p className="w-full text-sm text-muted-foreground">
                        Date added: {extractDate(item.date_created)}
                      </p>
                      <p className="text-sm text-muted-foreground">
                        Default OS: {os} {version}
                      </p>
                    </div>
                    <div className="flex min-w-[600px] flex-wrap gap-6 text-sm text-muted-foreground">

  {(() => {
    const getDisplayValueFromRAM = (ram: number) =>
      ram >= 1024 ? `${Math.floor(ram / 1024)}GB` : `${ram}MB`;

    const IconText = ({
      icon,
      label,
    }: {
      icon: React.ReactNode;
      label: string;
    }) => (
      <span className="flex items-center gap-1">
        {icon}
        {label}
      </span>
    );

    const CPUIcon = (
      <svg
        xmlns="http://www.w3.org/2000/svg"
        className="w-4 h-4"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        strokeWidth={2}
      >
        <rect x="9" y="9" width="6" height="6" />
        <path d="M3 9h2m14 0h2M3 15h2m14 0h2M9 3v2m6-2v2M9 19v2m6-2v2" />
      </svg>
    );

    const RAMIcon = (
      <svg
        xmlns="http://www.w3.org/2000/svg"
        className="w-4 h-4"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        strokeWidth={2}
      >
        <rect x="4" y="6" width="16" height="12" rx="2" ry="2" />
        <path d="M8 6v12M16 6v12" />
      </svg>
    );

    const HDDIcon = (
      <svg
        xmlns="http://www.w3.org/2000/svg"
        className="w-4 h-4"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        strokeWidth={2}
      >
        <path d="M4 4h16v16H4z" />
        <circle cx="8" cy="16" r="1" />
        <circle cx="16" cy="16" r="1" />
      </svg>
    );

    const ResourceDisplay = ({
      title,
      cpu,
      ram,
      hdd,
    }: {
      title: string;
      cpu: number;
      ram: number;
      hdd: number;
    }) => (
      <div className="flex items-center gap-2 flex-wrap">
        <span className="font-semibold text-foreground">{title}:</span>
        <IconText icon={CPUIcon} label={`CPU: ${cpu} vCPU`} />
        <span>|</span>
        <IconText icon={RAMIcon} label={`RAM: ${getDisplayValueFromRAM(ram)}`} />
        <span>|</span>
        <IconText icon={HDDIcon} label={`HDD: ${hdd} GB`} />
      </div>
    );

    const defaultSettings = item.install_methods.find(
      (method) => method.type === 'default'
    );
    const alpineSettings = item.install_methods.find(
      (method) => method.type === 'alpine'
    );

    return (
      <>
        {defaultSettings?.resources && (
          <ResourceDisplay
            title="Default"
            cpu={defaultSettings.resources.cpu}
            ram={defaultSettings.resources.ram ?? 0}
            hdd={defaultSettings.resources.hdd}
          />
        )}
        {alpineSettings?.resources && (
          <ResourceDisplay
            title="Alpine"
            cpu={alpineSettings.resources.cpu}
            ram={alpineSettings.resources.ram ?? 0}
            hdd={alpineSettings.resources.hdd}
          />
        )}
      </>
    );
  })()}
</div>


                    {(() => {
  if (versions.length === 0) {
    return <p>Loading versions...</p>
  }

  const cleanSlug = item.slug.replace(/[^a-z0-9]/gi, '').toLowerCase()

  const matched = versions.find((v) => {
    const cleanName = v.name.replace(/[^a-z0-9]/gi, '').toLowerCase()
    return cleanName === cleanSlug || cleanName.includes(cleanSlug)
  })

  if (!matched) return null

  return (
    <div className="flex items-center gap-2 text-sm text-muted-foreground mt-2">
      <span className="text-foreground">
        Version: {matched.version} ({extractDate(matched.date || '')})
      </span>
      <span
        title="Crawled version from newreleases.io"
        className="cursor-help rounded-full border border-green-500 px-2 py-0.5 text-xs font-semibold text-green-500"
      >
        Info
      </span>
    </div>
  )
})()}

                  </div>
                </div>
              </div>
              <div className="hidden flex-col justify-between gap-2 sm:flex">
                <InterFaces item={item} />
                <Buttons item={item} />
              </div>
            </div>
            <Separator className="mt-4" />
            <div>
              <div className="mt-4">
                <Description item={item} />
                <Alerts item={item} />
              </div>
              <div className="mt-4 rounded-lg border bg-accent/50">
                <div className="flex gap-3 px-4 py-2">
                  <h2 className="text-lg font-semibold">
                    How to {item.type == "misc" ? "use" : "install"}
                  </h2>
                  <Tooltips item={item} />
                </div>
                <Separator className="w-full"></Separator>
                <InstallCommand item={item} />
              </div>
            </div>
            <DefaultPassword item={item} />
          </div>
        </div>
      </div>
    </div>
  );
}

export default ScriptItem;
