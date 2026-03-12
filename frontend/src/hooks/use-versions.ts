"use client";

import { useQuery } from "@tanstack/react-query";

import type { AppVersion, GitHubVersionsResponse } from "@/lib/types";

import { fetchVersions } from "@/lib/data";

export function useVersions() {
  return useQuery<AppVersion[]>({
    queryKey: ["versions"],
    queryFn: async () => {
      const response: GitHubVersionsResponse = await fetchVersions();
      return response.versions ?? [];
    },
  });
}
