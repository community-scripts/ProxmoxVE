import { CircleHelp } from "lucide-react";
import React from "react";

import type { BadgeProps } from "@/components/ui/badge";
import type { Script } from "@/lib/types";

import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

type TooltipProps = {
  variant: BadgeProps["variant"];
  label: string;
  content?: string;
};

const TooltipBadge: React.FC<TooltipProps> = ({ variant, label, content }) => (
  <TooltipProvider>
    <Tooltip delayDuration={100}>
      <TooltipTrigger className={cn("flex items-center", !content && "cursor-default")}>
        <Badge variant={variant} className="flex items-center gap-1">
          {label}
          {" "}
          {content && <CircleHelp className="size-3" />}
        </Badge>
      </TooltipTrigger>
      {content && (
        <TooltipContent side="bottom" className="text-sm max-w-64">
          {content}
        </TooltipContent>
      )}
    </Tooltip>
  </TooltipProvider>
);

export default function Tooltips({ item }: { item: Script }) {
  return (
    <div className="flex items-center gap-2">
      {item.privileged && (
        <TooltipBadge variant="warning" label="Privileged" content="This script will be run in a privileged LXC" />
      )}
      {item.updateable && item.type !== "pve" && (
        <TooltipBadge
          variant="success"
          label="Updateable"
          content={`To Update ${item.name}, run the command below (or type update) in the LXC Console.`}
        />
      )}
      {!item.updateable && item.type !== "pve" && <TooltipBadge variant="failure" label="Not Updateable" />}
    </div>
  );
}
