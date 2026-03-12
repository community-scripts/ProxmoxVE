import type { VariantProps } from "class-variance-authority";

import { Slot, Slottable } from "@radix-ui/react-slot";
import { cva } from "class-variance-authority";
import * as React from "react";

import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive:
          "bg-destructive text-destructive-foreground hover:bg-destructive/90",
        outline:
          "border border-input bg-background hover:bg-accent hover:text-accent-foreground",
        secondary:
          "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
        expandIcon:
          "group relative text-primary-foreground bg-primary hover:bg-primary/90",
        ringHover:
          "bg-primary text-primary-foreground transition-all duration-300 hover:bg-primary/90 hover:ring-2 hover:ring-primary/90 hover:ring-offset-2",
        shine:
          "text-primary-foreground animate-shine bg-gradient-to-r from-primary via-primary/75 to-primary bg-[length:400%_100%] ",
        gooeyRight:
          "text-primary-foreground relative bg-primary z-0 overflow-hidden transition-all duration-500 before:absolute before:inset-0 before:-z-10 before:translate-x-[150%] before:translate-y-[150%] before:scale-[2.5] before:rounded-[100%] before:bg-gradient-to-r from-zinc-400 before:transition-transform before:duration-1000  hover:before:translate-x-[0%] hover:before:translate-y-[0%] ",
        gooeyLeft:
          "text-primary-foreground relative bg-primary z-0 overflow-hidden transition-all duration-500 after:absolute after:inset-0 after:-z-10 after:translate-x-[-150%] after:translate-y-[150%] after:scale-[2.5] after:rounded-[100%] after:bg-gradient-to-l from-zinc-400 after:transition-transform after:duration-1000  hover:after:translate-x-[0%] hover:after:translate-y-[0%] ",
        linkHover1:
          "relative after:absolute after:bg-primary after:bottom-2 after:h-[1px] after:w-2/3 after:origin-bottom-left after:scale-x-100 hover:after:origin-bottom-right hover:after:scale-x-0 after:transition-transform after:ease-in-out after:duration-300",
        linkHover2:
          "relative after:absolute after:bg-primary after:bottom-2 after:h-[1px] after:w-2/3 after:origin-bottom-right after:scale-x-0 hover:after:origin-bottom-left hover:after:scale-x-100 after:transition-transform after:ease-in-out after:duration-300",
        // Mechanicus-themed variants
        mechanicus:
          "bg-gradient-to-r from-rust-600 to-rust-700 text-rust-100 border border-brass-500/30 hover:from-rust-500 hover:to-rust-600 hover:border-brass-400/50 hover:shadow-[0_0_15px_hsl(28_70%_45%_/_0.3)] transition-all duration-300",
        brass:
          "bg-gradient-to-r from-brass-500 to-brass-600 text-brass-100 border border-brass-400/30 hover:from-brass-400 hover:to-brass-500 hover:shadow-[0_0_15px_hsl(43_70%_50%_/_0.3)] transition-all duration-300",
        corruption:
          "bg-gradient-to-r from-corruption-600 to-corruption-700 text-corruption-100 border border-corruption-500/30 hover:from-corruption-500 hover:to-corruption-600 hover:shadow-[0_0_15px_hsl(145_60%_40%_/_0.3)] hover:animate-corrupted-pulse transition-all duration-300",
        forge:
          "bg-gradient-to-r from-copper-600 to-copper-700 text-copper-100 border border-copper-500/30 hover:from-copper-500 hover:to-copper-600 hover:shadow-[0_0_20px_hsl(25_70%_45%_/_0.4)] transition-all duration-300",
        iron:
          "bg-gradient-to-r from-iron-700 to-iron-800 text-iron-100 border border-iron-500/30 hover:from-iron-600 hover:to-iron-700 hover:shadow-[0_0_10px_hsl(30_20%_30%_/_0.3)] transition-all duration-300",
      },
      size: {
        default: "h-10 px-4 py-2",
        sm: "h-9 rounded-md px-3",
        lg: "h-11 rounded-md px-8",
        icon: "h-9 w-9    ",
        null: "py-1 px-3 rouded-xs",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  },
);

type IconProps = {
  Icon: React.ElementType;
  iconPlacement: "left" | "right";
};

type IconRefProps = {
  Icon?: never;
  iconPlacement?: undefined;
};

export type ButtonProps = {
  asChild?: boolean;
} & React.ButtonHTMLAttributes<HTMLButtonElement> & VariantProps<typeof buttonVariants>;

export type ButtonIconProps = IconProps | IconRefProps;

const Button = React.forwardRef<
  HTMLButtonElement,
  ButtonProps & ButtonIconProps
>(
  (
    {
      className,
      variant,
      size,
      asChild = false,
      Icon,
      iconPlacement,
      ...props
    },
    ref,
  ) => {
    const Comp = asChild ? Slot : "button";
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      >
        {Icon && iconPlacement === "left" && (
          <div className="group-hover:translate-x-100 w-0 translate-x-[0%] pr-0 opacity-0 transition-all duration-200 group-hover:w-5 group-hover:pr-2 group-hover:opacity-100">
            <Icon />
          </div>
        )}
        <Slottable>{props.children}</Slottable>
        {Icon && iconPlacement === "right" && (
          <div className="w-0 translate-x-[100%] pl-0 opacity-0 transition-all duration-200 group-hover:w-5 group-hover:translate-x-0 group-hover:pl-2 group-hover:opacity-100">
            <Icon />
          </div>
        )}
      </Comp>
    );
  },
);
Button.displayName = "Button";

export { Button, buttonVariants };
