import { AlertCircle } from "lucide-react";

import type { Script } from "@/lib/types";

import TextParseLinks from "@/components/text-parse-links";
import { AlertColors } from "@/config/site-config";
import { cn } from "@/lib/utils";

export default function DisableDescription({ item }: { item: Script }) {
  return (
    <div className="mt-4 flex flex-col shadow-sm gap-2">
      <div
        className={cn(
          "flex items-start gap-3 rounded-lg border p-4 text-sm",
          AlertColors.warning,
        )}
      >
        <AlertCircle className="h-5 min-h-5 w-5 min-w-5 mt-0.5" />
        <div className="flex flex-col gap-2">
          <h3 className="font-semibold text-base">Script Disabled</h3>
          <p>{TextParseLinks(item.disable_description!)}</p>
        </div>
      </div>
    </div>
  );
}
