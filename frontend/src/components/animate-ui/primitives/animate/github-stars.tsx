"use client";

import type { HTMLMotionProps } from "motion/react";

import { motion } from "motion/react";
import * as React from "react";

import type { SlidingNumberProps } from "@/components/animate-ui/primitives/texts/sliding-number";
import type { ParticlesEffectProps } from "@/components/animate-ui/primitives/effects/particles";
import type { WithAsChild } from "@/components/animate-ui/primitives/animate/slot";
import type { UseIsInViewOptions } from "@/hooks/use-is-in-view";

import { Particles, ParticlesEffect } from "@/components/animate-ui/primitives/effects/particles";
import { SlidingNumber } from "@/components/animate-ui/primitives/texts/sliding-number";
import { Slot } from "@/components/animate-ui/primitives/animate/slot";
import { getStrictContext } from "@/lib/get-strict-context";
import { useIsInView } from "@/hooks/use-is-in-view";
import { cn } from "@/lib/utils";

type GithubStarsContextType = {
  stars: number;
  setStars: (stars: number) => void;
  currentStars: number;
  setCurrentStars: (stars: number) => void;
  isCompleted: boolean;
  isLoading: boolean;
};

const [GithubStarsProvider, useGithubStars] = getStrictContext<GithubStarsContextType>("GithubStarsContext");

type GithubStarsProps = WithAsChild<
  {
    children: React.ReactNode;
    username?: string;
    repo?: string;
    value?: number;
    delay?: number;
  } & UseIsInViewOptions
  & HTMLMotionProps<"div">
>;

function GithubStars({
  ref,
  children,
  username,
  repo,
  value,
  delay = 0,
  inView = false,
  inViewMargin = "0px",
  inViewOnce = true,
  asChild = false,
  ...props
}: GithubStarsProps) {
  const { ref: localRef, isInView } = useIsInView(ref as React.Ref<HTMLDivElement>, {
    inView,
    inViewOnce,
    inViewMargin,
  });

  const [stars, setStars] = React.useState(value ?? 0);
  const [currentStars, setCurrentStars] = React.useState(0);
  const [isLoading, setIsLoading] = React.useState(true);
  const isCompleted = React.useMemo(() => currentStars === stars, [currentStars, stars]);

  const Component = asChild ? Slot : motion.div;

  React.useEffect(() => {
    if (value !== undefined && username && repo)
      return;
    if (!isInView) {
      setStars(0);
      setIsLoading(true);
      return;
    }

    const timeout = setTimeout(() => {
      fetch(`https://api.github.com/repos/${username}/${repo}`)
        .then(response => response.json())
        .then((data) => {
          if (data && typeof data.stargazers_count === "number") {
            setStars(data.stargazers_count);
          }
        })
        .catch(console.error)
        .finally(() => setIsLoading(false));
    }, delay);

    return () => clearTimeout(timeout);
  }, [username, repo, value, isInView, delay]);

  return (
    <GithubStarsProvider
      value={{
        stars,
        currentStars,
        isCompleted,
        isLoading,
        setStars,
        setCurrentStars,
      }}
    >
      {!isLoading && (
        <Component ref={localRef} {...props}>
          {children}
        </Component>
      )}
    </GithubStarsProvider>
  );
}

type GithubStarsNumberProps = Omit<SlidingNumberProps, "number" | "fromNumber">;

function GithubStarsNumber({ padStart = true, ...props }: GithubStarsNumberProps) {
  const { stars, setCurrentStars } = useGithubStars();

  return (
    <SlidingNumber number={stars} fromNumber={0} onNumberChange={setCurrentStars} padStart={padStart} {...props} />
  );
}

type GithubStarsIconProps<T extends React.ElementType> = {
  icon: React.ReactElement<T>;
  color?: string;
  activeClassName?: string;
} & React.ComponentProps<T>;

function GithubStarsIcon<T extends React.ElementType>({
  icon: Icon,
  color = "currentColor",
  activeClassName,
  className,
  ...props
}: GithubStarsIconProps<T>) {
  const { stars, currentStars, isCompleted } = useGithubStars();
  const fillPercentage = (currentStars / stars) * 100;

  return (
    <div style={{ position: "relative" }}>
      <Icon aria-hidden="true" className={cn(className)} {...props} />
      <Icon
        aria-hidden="true"
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          fill: color,
          stroke: color,
          clipPath: `inset(${100 - (isCompleted ? fillPercentage : fillPercentage - 10)}% 0 0 0)`,
        }}
        className={cn(className, activeClassName)}
        {...props}
      />
    </div>
  );
}

type GithubStarsParticlesProps = ParticlesEffectProps & {
  children: React.ReactElement;
  size?: number;
};

function GithubStarsParticles({ children, size = 4, style, ...props }: GithubStarsParticlesProps) {
  const { isCompleted } = useGithubStars();

  return (
    <Particles animate={isCompleted}>
      {children}
      <ParticlesEffect
        style={{
          backgroundColor: "currentcolor",
          borderRadius: "50%",
          width: size,
          height: size,
          ...style,
        }}
        {...props}
      />
    </Particles>
  );
}

type GithubStarsLogoProps = React.SVGProps<SVGSVGElement>;

function GithubStarsLogo(props: GithubStarsLogoProps) {
  return (
    <svg role="img" viewBox="0 0 24 24" fill="currentColor" aria-label="GitHub" {...props}>
      <path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"></path>
    </svg>
  );
}

export {
  GithubStars,
  type GithubStarsContextType,
  GithubStarsIcon,
  type GithubStarsIconProps,
  GithubStarsLogo,
  type GithubStarsLogoProps,
  GithubStarsNumber,
  type GithubStarsNumberProps,
  GithubStarsParticles,
  type GithubStarsParticlesProps,
  type GithubStarsProps,
  useGithubStars,
};
