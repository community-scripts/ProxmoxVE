import type { VariantProps } from "class-variance-authority";

import { cva } from "class-variance-authority";
import { StarIcon } from "lucide-react";
import Link from "next/link";

import type { ButtonProps as ButtonPrimitiveProps } from "@/components/animate-ui/primitives/buttons/button";
import type { GithubStarsProps } from "@/components/animate-ui/primitives/animate/github-stars";

import {
  GithubStars,
  GithubStarsIcon,
  GithubStarsLogo,
  GithubStarsNumber,
  GithubStarsParticles,
} from "@/components/animate-ui/primitives/animate/github-stars";
import { Button as ButtonPrimitive } from "@/components/animate-ui/primitives/buttons/button";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex shrink-0 items-center justify-center gap-2 whitespace-nowrap rounded-md font-medium text-sm outline-none transition-[box-shadow,_color,_background-color,_border-color,_outline-color,_text-decoration-color,_fill,_stroke] focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 [&_svg:not([class*='size-'])]:size-4 [&_svg]:pointer-events-none [&_svg]:shrink-0",
  {
    variants: {
      variant: {
        default:
          "bg-primary text-primary-foreground shadow-xs hover:bg-primary/90",
        accent: "bg-accent text-accent-foreground shadow-xs hover:bg-accent/90",
        outline:
          "border bg-background shadow-xs hover:bg-accent hover:text-accent-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50",
        ghost:
          "hover:bg-accent hover:text-accent-foreground dark:hover:bg-accent/50",
      },
      size: {
        default: "h-9 px-4 py-2 has-[>svg]:px-3",
        sm: "h-8 gap-1.5 rounded-md px-3 has-[>svg]:px-2.5",
        lg: "h-10 rounded-md px-6 has-[>svg]:px-4",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);

const buttonStarVariants = cva("", {
  variants: {
    variant: {
      default:
        "fill-neutral-700 stroke-neutral-700 dark:fill-neutral-300 dark:stroke-neutral-300",
      accent:
        "fill-neutral-300 stroke-neutral-300 dark:fill-neutral-700 dark:stroke-neutral-700",
      outline:
        "fill-neutral-300 stroke-neutral-300 dark:fill-neutral-700 dark:stroke-neutral-700",
      ghost:
        "fill-neutral-300 stroke-neutral-300 dark:fill-neutral-700 dark:stroke-neutral-700",
    },
  },
  defaultVariants: {
    variant: "default",
  },
});

type GitHubStarsButtonProps = Omit<
  ButtonPrimitiveProps & GithubStarsProps,
  "asChild" | "children"
> &
  VariantProps<typeof buttonVariants>;

function GitHubStarsButton({
  className,
  username,
  repo,
  value,
  delay,
  inView,
  inViewMargin,
  inViewOnce,
  variant,
  size,
  ...props
}: GitHubStarsButtonProps) {
  return (
    <Link
      target="_blank"
      rel="noopener noreferrer"
      data-umami-event="github-stars"
      href={`https://github.com/${username}/${repo}`}
    >
      <GithubStars
        asChild
        username={username}
        repo={repo}
        value={value}
        delay={delay}
        inView={inView}
        inViewMargin={inViewMargin}
        inViewOnce={inViewOnce}
      >
        <ButtonPrimitive
          className={cn(buttonVariants({ variant, size, className }))}
          {...props}
        >
          <GithubStarsLogo />
          <GithubStarsNumber />
          <GithubStarsParticles className="text-yellow-500">
            <GithubStarsIcon
              icon={StarIcon}
              data-variant={variant}
              className={cn(buttonStarVariants({ variant }))}
              activeClassName="text-yellow-500"
              size={18}
            />
          </GithubStarsParticles>
        </ButtonPrimitive>
      </GithubStars>
    </Link>
  );
}

export { GitHubStarsButton, type GitHubStarsButtonProps };
