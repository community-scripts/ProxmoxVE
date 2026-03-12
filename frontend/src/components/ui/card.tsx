import * as React from "react";

import { cn } from "@/lib/utils";

type CardVariant = "default" | "rust" | "corruption" | "mechanicus" | "forge";

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: CardVariant;
}

const cardVariants: Record<CardVariant, string> = {
  default: "rounded-lg border text-card-foreground shadow-sm",
  rust: "rounded-lg border text-card-foreground shadow-sm rust-border metal-surface",
  corruption: "rounded-lg border text-card-foreground shadow-sm noosphere-border corrupted-pulse",
  mechanicus: "rounded-lg border text-card-foreground shadow-sm rust-border metal-surface hover:shadow-[0_0_20px_hsl(28_70%_45%_/_0.2)] transition-all duration-300",
  forge: "rounded-lg border text-card-foreground shadow-sm border-copper-500/30 bg-gradient-to-br from-iron-900/50 to-iron-950/50 hover:border-copper-400/50 hover:shadow-[0_0_15px_hsl(25_70%_45%_/_0.3)] transition-all duration-300",
};

const Card = React.forwardRef<
  HTMLDivElement,
  CardProps
>(({ className, variant = "default", ...props }, ref) => (
  <div
    ref={ref}
    className={cn(cardVariants[variant], className)}
    {...props}
  />
));
Card.displayName = "Card";

const CardHeader = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn("flex flex-col space-y-1.5 p-4", className)}
    {...props}
  />
));
CardHeader.displayName = "CardHeader";

const CardTitle = React.forwardRef<
  HTMLParagraphElement,
  React.HTMLAttributes<HTMLHeadingElement>
>(({ className, ...props }, ref) => (
  <h3
    ref={ref}
    className={cn(
      "text-2xl font-semibold leading-none tracking-tight font-[family-name:var(--font-cinzel)]",
      className,
    )}
    {...props}
  />
));
CardTitle.displayName = "CardTitle";

const CardDescription = React.forwardRef<
  HTMLParagraphElement,
  React.HTMLAttributes<HTMLParagraphElement>
>(({ className, ...props }, ref) => (
  <p
    ref={ref}
    className={cn(
      "min-h-[40px] text-sm text-muted-foreground sm:min-h-[60px]",
      className,
    )}
    {...props}
  />
));
CardDescription.displayName = "CardDescription";

const CardContent = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("p-4 pt-0", className)} {...props} />
));
CardContent.displayName = "CardContent";

const CardFooter = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn("mt-auto items-center p-4 pt-0", className)}
    {...props}
  />
));
CardFooter.displayName = "CardFooter";

export {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
};
