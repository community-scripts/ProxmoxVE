import { AppVersion } from "@/lib/types";

interface VersionBadgeProps {
  version: AppVersion;
}

export function VersionBadge({ version }: VersionBadgeProps) {
  return (
    <div className="flex items-center">
      <span className="font-medium text-sm">{version.version}</span>
    </div>
  );
}
