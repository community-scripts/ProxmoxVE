import type { VariantProps } from "class-variance-authority";

import { cva } from "class-variance-authority";

import { cn } from "@/lib/utils";

const badgeVariants = cva(
  "inline-flex items-center rounded-full border px-1.5 py-0.1 font-semibold text-xs transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
  {
    variants: {
      variant: {
        default:
          "border-primary-foreground border-transparent text-primary-foreground",
        secondary:
          "border-secondary-foreground border-transparent text-secondary-foreground",
        destructive:
          "border-destructive-foreground border-transparent text-destructive-foreground",
        outline: "text-foreground",
        success: "border-green-500 text-green-500",
        warning: "border-yellow-500 text-yellow-500",
        failure: "border-red-500 text-red-500",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
);

export type BadgeProps = {} & React.HTMLAttributes<HTMLDivElement> &
  VariantProps<typeof badgeVariants>;

function Badge({ className, variant, ...props }: BadgeProps) {
  return (
    <div className={cn(badgeVariants({ variant }), className)} {...props} />
  );
}

export { Badge, badgeVariants };
