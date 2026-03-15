"use client";

import React from "react";
import { FolderOpen, Search as SearchIcon } from "lucide-react";
import Link from "next/link";
import { useQueryState } from "nuqs";
import { Suspense, useEffect, useState, useMemo } from "react";
import { Loader2 } from "lucide-react";

import type { Category, Script } from "@/lib/types";
import { fetchCategories } from "@/lib/data";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Search } from "@/components/search";

function CategoriesContent() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useQueryState("category");
  const [search, setSearch] = useQueryState("search");

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

  // Filter categories by search
  const filteredCategories = useMemo(() => {
    if (!search) return categories;

    const searchLower = search.toLowerCase();
    return categories.filter((category) => {
      // Search in category name
      if (category.name.toLowerCase().includes(searchLower)) return true;

      // Search in category description
      if (category.description?.toLowerCase().includes(searchLower)) return true;

      // Search in script names within category
      const hasMatchingScript = category.scripts?.some(
        (script) =>
          script.name.toLowerCase().includes(searchLower) ||
          script.description.toLowerCase().includes(searchLower)
      );

      return hasMatchingScript;
    });
  }, [categories, search]);

  // Calculate total scripts
  const totalScripts = categories.reduce(
    (acc, cat) => acc + (cat.scripts?.length || 0),
    0
  );

  // Calculate matching scripts in filtered categories
  const matchingScripts = useMemo(() => {
    if (!search) return totalScripts;

    return filteredCategories.reduce((acc, cat) => {
      const matchingInCategory = cat.scripts?.filter(
        (script) =>
          script.name.toLowerCase().includes(search.toLowerCase()) ||
          script.description.toLowerCase().includes(search.toLowerCase())
      ).length || 0;
      return acc + matchingInCategory;
    }, 0);
  }, [filteredCategories, search, totalScripts]);

  if (loading) {
    return (
      <div className="flex h-[50vh] w-full flex-col items-center justify-center gap-5 bg-background px-4 md:px-6">
        <Loader2 className="h-10 w-10 animate-spin" />
      </div>
    );
  }

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

          {/* Search */}
          <div className="mb-6">
            <Search
              placeholder="Search categories or scripts..."
              className="w-full max-w-md"
            />
          </div>

          {/* Search Results Info */}
          {search && (
            <div className="mb-4 flex items-center gap-2 text-sm text-muted-foreground">
              <SearchIcon className="h-4 w-4" />
              <span>
                Found {filteredCategories.length} categories
                {matchingScripts > 0 && ` with ${matchingScripts} matching scripts`}
              </span>
            </div>
          )}

          {/* Categories Grid */}
          {filteredCategories.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-center">
              <SearchIcon className="h-12 w-12 text-muted-foreground/50 mb-4" />
              <h3 className="text-lg font-semibold text-foreground/80">No categories found</h3>
              <p className="text-muted-foreground">Try adjusting your search</p>
            </div>
          ) : (
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              {filteredCategories.map((category) => {
                const { totalScripts, devScripts } = getCategoryStats(category);
                return (
                  <Link
                    key={category.id}
                    href={{
                      pathname: "/scripts",
                      query: search ? { category: category.id, search } : { category: category.id },
                    }}
                    className="group"
                  >
                    <Card className="h-full transition-all hover:border-brass/50 hover:shadow-md cursor-pointer border-rust/30">
                      <CardHeader className="pb-2">
                        <div className="flex items-center justify-between">
                          <CardTitle className="text-lg text-foreground/90 group-hover:text-brass transition-colors">
                            {category.name}
                          </CardTitle>
                          <FolderOpen className="h-5 w-5 text-muted-foreground group-hover:text-brass transition-colors" />
                        </div>
                      </CardHeader>
                      <CardContent>
                        <div className="flex items-center gap-2 flex-wrap">
                          <Badge variant="secondary" className="bg-accent">
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
                        {category.description && (
                          <p className="mt-2 text-sm text-muted-foreground line-clamp-2">
                            {category.description}
                          </p>
                        )}
                      </CardContent>
                    </Card>
                  </Link>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default function CategoriesPage() {
  return (
    <Suspense
      fallback={
        <div className="flex h-[50vh] w-full flex-col items-center justify-center gap-5 bg-background px-4 md:px-6">
          <Loader2 className="h-10 w-10 animate-spin" />
        </div>
      }
    >
      <CategoriesContent />
    </Suspense>
  );
}
