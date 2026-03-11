"use client";

import React from "react";
import { CalendarIcon, ExternalLink } from "lucide-react";
import Link from "next/link";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { getNewsItems } from "@/lib/news-data";
import { cn } from "@/lib/utils";

const typeColors: Record<string, string> = {
  announcement: "bg-primary/10 text-primary border-primary/20",
  update: "bg-green-500/10 text-green-600 dark:text-green-400 border-green-500/20",
  release: "bg-blue-500/10 text-blue-600 dark:text-blue-400 border-blue-500/20",
  news: "bg-orange-500/10 text-orange-600 dark:text-orange-400 border-orange-500/20",
};

export function NewsHighlight() {
  const newsItems = getNewsItems(3);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold tracking-tight">Latest News</h2>
        <Button variant="ghost" size="sm" asChild>
          <Link href="/community">
            View All
            <ExternalLink className="ml-2 h-4 w-4" />
          </Link>
        </Button>
      </div>
      <div className="grid gap-4 md:grid-cols-3">
        {newsItems.map((item) => (
          <Card key={item.id} className="flex flex-col">
            <CardHeader className="pb-2">
              <div className="flex items-center gap-2">
                <span
                  className={cn(
                    "rounded-full px-2 py-0.5 text-xs font-medium border",
                    typeColors[item.type] || typeColors.news,
                  )}
                >
                  {item.type}
                </span>
                <span className="text-xs text-muted-foreground flex items-center gap-1">
                  <CalendarIcon className="h-3 w-3" />
                  {new Date(item.date).toLocaleDateString("en-US", {
                    month: "short",
                    day: "numeric",
                    year: "numeric",
                  })}
                </span>
              </div>
              <CardTitle className="text-lg mt-2">{item.title}</CardTitle>
            </CardHeader>
            <CardContent className="flex-1">
              <CardDescription className="line-clamp-3">{item.content}</CardDescription>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
