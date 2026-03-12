import type { VariantProps } from "class-variance-authority";

import { cva } from "class-variance-authority";
import * as React from "react";

import { cn } from "@/lib/utils";

const badgeVariants = cva(
  "inline-flex items-center rounded-full border px-1.5 py-0.1 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
  {
    variants: {
      variant: {
        default:
          "border-transparent  text-primary-foreground border-primary-foreground",
        secondary:
          "border-transparent  text-secondary-foreground border-secondary-foreground",
        destructive:
          "border-transparent  text-destructive-foreground border-destructive-foreground",
        outline: "text-foreground",
        success: "text-green-500 border-green-500",
        warning: "text-yellow-500 border-yellow-500",
        failure: "text-red-500 border-red-500",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  },
);

export type BadgeProps = {} & React.HTMLAttributes<HTMLDivElement> & VariantProps<typeof badgeVariants>;

function Badge({ className, variant, ...props }: BadgeProps) {
  return (
    <div className={cn(badgeVariants({ variant }), className)} {...props} />
  );
}

export { Badge, badgeVariants };
