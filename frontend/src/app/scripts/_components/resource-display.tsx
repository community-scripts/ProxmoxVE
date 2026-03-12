import { CPUIcon, HDDIcon, RAMIcon } from "@/components/icons/resource-icons";
import { getDisplayValueFromRAM } from "@/lib/utils/resource-utils";

type ResourceDisplayProps = {
  title: string;
  cpu: number | null;
  ram: number | null;
  hdd: number | null;
};

type IconTextProps = {
  icon: React.ReactNode;
  label: string;
};

function IconText({ icon, label }: IconTextProps) {
  return (
    <span className="inline-flex items-center gap-1.5 rounded-md bg-accent/20 px-2 py-1 text-sm">
      {icon}
      <span className="text-foreground/90">{label}</span>
    </span>
  );
}

export function ResourceDisplay({ title, cpu, ram, hdd }: ResourceDisplayProps) {
  const hasCPU = typeof cpu === "number" && cpu > 0;
  const hasRAM = typeof ram === "number" && ram > 0;
  const hasHDD = typeof hdd === "number" && hdd > 0;

  if (!hasCPU && !hasRAM && !hasHDD)
    return null;

  return (
    <div className="flex flex-wrap items-center gap-2">
      <span className="text-sm font-medium text-muted-foreground">{title}</span>
      <div className="flex flex-wrap gap-2">
        {hasCPU && <IconText icon={<CPUIcon />} label={`${cpu} vCPU`} />}
        {hasRAM && <IconText icon={<RAMIcon />} label={getDisplayValueFromRAM(ram!)} />}
        {hasHDD && <IconText icon={<HDDIcon />} label={`${hdd} GB`} />}
      </div>
    </div>
  );
}
