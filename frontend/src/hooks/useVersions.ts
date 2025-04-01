"use client";

import { fetchVersions } from "@/lib/data";
import { AppVersion } from "@/lib/types";
import { useQuery } from "@tanstack/react-query";

export function useVersions() {
  return useQuery<AppVersion[]>({
    queryKey: ["versions"],
    queryFn: async () => {
      const fetchedVersions = await fetchVersions();
      if (Array.isArray(fetchedVersions)) {
        return fetchedVersions;
      }
      if (fetchedVersions && typeof fetchedVersions === "object") {
        return [fetchedVersions];
      }
      return [];
    },
  });
}
