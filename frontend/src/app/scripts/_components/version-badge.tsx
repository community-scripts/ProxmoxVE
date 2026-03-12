import type { AppVersion } from "@/lib/types";

type VersionBadgeProps = {
  version: AppVersion;
};

export function VersionBadge({ version }: VersionBadgeProps) {
  return (
    <div className="flex items-center">
      <span className="font-medium text-sm">{version.version}</span>
    </div>
  );
}
