"use client";

import React from "react";
import { Box, FolderCode, GitCommit, Users } from "lucide-react";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import NumberTicker from "@/components/ui/number-ticker";
import { fetchCategories } from "@/lib/data";

interface Stats {
  totalScripts: number;
  totalCategories: number;
  recentUpdates: number;
  contributors: number;
}

async function getStats(): Promise<Stats> {
  try {
    const categories = await fetchCategories();
    const totalScripts = categories.reduce((acc, cat) => acc + (cat.scripts?.length || 0), 0);
    const totalCategories = categories.length;
    // These would come from an API in a real implementation
    const recentUpdates = 42;
    const contributors = 15;
    return { totalScripts, totalCategories, recentUpdates, contributors };
  }
  catch {
    return { totalScripts: 0, totalCategories: 0, recentUpdates: 0, contributors: 0 };
  }
}

const statItems = [
  {
    title: "Total Scripts",
    icon: <Box className="h-4 w-4 text-muted-foreground" />,
    key: "totalScripts" as const,
  },
  {
    title: "Categories",
    icon: <FolderCode className="h-4 w-4 text-muted-foreground" />,
    key: "totalCategories" as const,
  },
  {
    title: "Recent Updates",
    icon: <GitCommit className="h-4 w-4 text-muted-foreground" />,
    key: "recentUpdates" as const,
  },
  {
    title: "Contributors",
    icon: <Users className="h-4 w-4 text-muted-foreground" />,
    key: "contributors" as const,
  },
];

export async function StatsSection() {
  const stats = await getStats();

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      {statItems.map(item => (
        <Card key={item.title}>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">{item.title}</CardTitle>
            {item.icon}
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              <NumberTicker value={stats[item.key]} />
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
