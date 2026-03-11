"use client";

import React from "react";
import { FolderOpen } from "lucide-react";
import Link from "next/link";
import { useQueryState } from "nuqs";
import { Suspense, useEffect, useState } from "react";
import { Loader2 } from "lucide-react";

import type { Category, Script } from "@/lib/types";
import { fetchCategories } from "@/lib/data";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

function CategoriesContent() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useQueryState("category");

  useEffect(() => {
    fetchCategories()
      .then((data) => {
        setCategories(data);
      })
      .catch((error) => {
        console.error("Error fetching categories:", error);
      })
      .finally(() => {
        setLoading(false);
      });
  }, []);

  const getCategoryStats = (category: Category) => {
    const scripts = category.scripts || [];
    const totalScripts = scripts.length;
    const devScripts = scripts.filter((s: Script) => s.disable).length;
    return { totalScripts, devScripts };
  };

  if (loading) {
    return (
      <div className="flex h-[50vh] w-full flex-col items-center justify-center gap-5 bg-background px-4 md:px-6">
        <Loader2 className="h-10 w-10 animate-spin" />
      </div>
    );
  }

  const totalScripts = categories.reduce(
    (acc, cat) => acc + (cat.scripts?.length || 0),
    0,
  );

  return (
    <div className="mb-3">
      <div className="mt-20 px-4 xl:px-0">
        <div className="max-w-6xl mx-auto">
          {/* Header */}
          <div className="mb-8">
            <h1 className="text-3xl font-bold tracking-tight mb-2">Categories</h1>
            <p className="text-muted-foreground">
              {categories.length}
              {" "}
              categories ·
              {totalScripts}
              {" "}
              scripts total
            </p>
          </div>

          {/* Categories Grid */}
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {categories.map((category) => {
              const { totalScripts, devScripts } = getCategoryStats(category);
              return (
                <Link
                  key={category.id}
                  href={`/scripts?category=${category.id}`}
                  className="group"
                >
                  <Card className="h-full transition-all hover:border-primary/50 hover:shadow-md cursor-pointer">
                    <CardHeader className="pb-2">
                      <div className="flex items-center justify-between">
                        <CardTitle className="text-lg">{category.name}</CardTitle>
                        <FolderOpen className="h-5 w-5 text-muted-foreground group-hover:text-primary transition-colors" />
                      </div>
                    </CardHeader>
                    <CardContent>
                      <div className="flex items-center gap-2">
                        <Badge variant="secondary">
                          {totalScripts}
                          {" "}
                          {totalScripts === 1 ? "script" : "scripts"}
                        </Badge>
                        {devScripts > 0 && (
                          <Badge variant="outline" className="text-orange-500 border-orange-500/50">
                            {devScripts}
                            {" "}
                            in dev
                          </Badge>
                        )}
                      </div>
                    </CardContent>
                  </Card>
                </Link>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}

export default function CategoriesPage() {
  return (
    <Suspense
      fallback={(
        <div className="flex h-[50vh] w-full flex-col items-center justify-center gap-5 bg-background px-4 md:px-6">
          <Loader2 className="h-10 w-10 animate-spin" />
        </div>
      )}
    >
      <CategoriesContent />
    </Suspense>
  );
}
