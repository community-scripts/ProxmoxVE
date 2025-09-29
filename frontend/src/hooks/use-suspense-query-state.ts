"use client";

import type { SetStateAction } from "react";

import { useSearchParams } from "next/navigation";
import { useTransition } from "react";
import { useQueryState } from "nuqs";

type SuspenseQueryStateSetter<T> = (value: SetStateAction<T | null>) => void;
type SuspenseQueryStateTuple<T> = [T | null, SuspenseQueryStateSetter<T>];

export function useSuspenseQueryState<T extends string>(key: string): SuspenseQueryStateTuple<T> {
  const params = useSearchParams();
  const [, startTransition] = useTransition();
  const [value, setValue] = useQueryState<T | null>(key, { shallow: true, parse: value => value as T | null });

  if (!params) {
    throw new Error("useSuspenseQueryState must be used within a Next.js app router context.");
  }
  const setNextValue: SuspenseQueryStateSetter<T> = (nextValue) => {
    startTransition(() => {
      setValue(nextValue);
    });
  };

  return [value, setNextValue];
}
