"use client";

import { ChevronLeft, ChevronRight } from "lucide-react";
import { Fragment, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";

import type { Category } from "@/lib/types";

import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

const defaultLogo = "/default-logo.png"; // Fallback logo path
const MAX_DESCRIPTION_LENGTH = 100; // Set max length for description
const MAX_LOGOS = 5; // Max logos to display at once

function formattedBadge(type: string) {
  switch (type) {
    case "vm":
      return (
        <Badge className="badge border-blue-500/75 text-blue-500/75">VM</Badge>
      );
    case "ct":
      return (
        <Badge className="badge border-yellow-500/75 text-yellow-500/75">
          LXC
        </Badge>
      );
    case "pve":
      return (
        <Badge className="badge border-orange-500/75 text-orange-500/75">
          PVE
        </Badge>
      );
    case "addon":
      return (
        <Badge className="badge border-green-500/75 text-green-500/75">
          ADDON
        </Badge>
      );
  }
  return null;
}

function CategoryView() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [selectedCategoryIndex, setSelectedCategoryIndex] = useState<
    number | null
  >(null);
  const [currentScripts, setCurrentScripts] = useState<any[]>([]);
  const [logoIndices, setLogoIndices] = useState<{ [key: string]: number }>({});
  const router = useRouter();

  useEffect(() => {
    const fetchCategories = async () => {
      try {
        const basePath =
          process.env.NODE_ENV === "production" ? "/ProxmoxVE" : "";
        const response = await fetch(`${basePath}/api/categories`);
        if (!response.ok) {
          throw new Error("Failed to fetch categories");
        }
        const data = await response.json();
        setCategories(data);

        // Initialize logo indices
        const initialLogoIndices: { [key: string]: number } = {};
        data.forEach((category: any) => {
          initialLogoIndices[category.name] = 0;
        });
        setLogoIndices(initialLogoIndices);
      } catch (error) {
        console.error("Error fetching categories:", error);
      }
    };

    fetchCategories();
  }, []);

  const handleCategoryClick = (index: number) => {
    setSelectedCategoryIndex(index);
    setCurrentScripts(categories[index]?.scripts || []); // Update scripts for the selected category
  };

  const handleBackClick = () => {
    setSelectedCategoryIndex(null);
    setCurrentScripts([]); // Clear scripts when going back
  };

  const handleScriptClick = (scriptSlug: string) => {
    // Include category context when navigating to scripts
    const categoryName =
      selectedCategoryIndex !== null
        ? categories[selectedCategoryIndex]?.name
        : null;
    const queryParams = new URLSearchParams({ id: scriptSlug });
    if (categoryName) {
      queryParams.append("category", categoryName);
    }
    router.push(`/scripts?${queryParams.toString()}`);
  };

  const navigateCategory = (direction: "prev" | "next") => {
    if (selectedCategoryIndex !== null) {
      const newIndex =
        direction === "prev"
          ? (selectedCategoryIndex - 1 + categories.length) % categories.length
          : (selectedCategoryIndex + 1) % categories.length;
      setSelectedCategoryIndex(newIndex);
      setCurrentScripts(categories[newIndex]?.scripts || []); // Update scripts for the new category
    }
  };

  const switchLogos = (categoryName: string, direction: "prev" | "next") => {
    setLogoIndices((prev) => {
      const currentIndex = prev[categoryName] || 0;
      const category = categories.find((cat) => cat.name === categoryName);
      if (!category || !category.scripts) return prev;

      const totalLogos = category.scripts.length;
      const newIndex =
        direction === "prev"
          ? (currentIndex - MAX_LOGOS + totalLogos) % totalLogos
          : (currentIndex + MAX_LOGOS) % totalLogos;

      return { ...prev, [categoryName]: newIndex };
    });
  };

  const truncateDescription = (text: string) => {
    return text.length > MAX_DESCRIPTION_LENGTH
      ? `${text.slice(0, MAX_DESCRIPTION_LENGTH)}...`
      : text;
  };

  const renderResources = (script: any) => {
    const cpu = script.install_methods[0]?.resources.cpu;
    const ram = script.install_methods[0]?.resources.ram;
    const hdd = script.install_methods[0]?.resources.hdd;

    const resourceParts = [];
    if (cpu) {
      resourceParts.push(
        <span key="cpu">
          <b>CPU:</b> {cpu}
          vCPU
        </span>
      );
    }
    if (ram) {
      resourceParts.push(
        <span key="ram">
          <b>RAM:</b> {ram}
          MB
        </span>
      );
    }
    if (hdd) {
      resourceParts.push(
        <span key="hdd">
          <b>HDD:</b> {hdd}
          GB
        </span>
      );
    }

    return resourceParts.length > 0 ? (
      <div className="text-gray-400 text-sm">
        {resourceParts.map((part, index) => (
          <Fragment key={index}>
            {part}
            {index < resourceParts.length - 1 && " | "}
          </Fragment>
        ))}
      </div>
    ) : null;
  };

  return (
    <div className="mt-20 p-6">
      {categories.length === 0 && (
        <p className="text-center text-gray-500">
          No categories available. Please check the API endpoint.
        </p>
      )}
      {selectedCategoryIndex !== null ? (
        <div>
          {/* Header with Navigation */}
          <div className="mb-6 flex items-center justify-between">
            <Button
              variant="ghost"
              onClick={() => navigateCategory("prev")}
              className="p-2 transition-transform duration-300 hover:scale-105"
            >
              <ChevronLeft className="h-6 w-6" />
            </Button>
            <h2 className="font-semibold text-3xl transition-opacity duration-300 hover:opacity-90">
              {categories[selectedCategoryIndex].name}
            </h2>
            <Button
              variant="ghost"
              onClick={() => navigateCategory("next")}
              className="p-2 transition-transform duration-300 hover:scale-105"
            >
              <ChevronRight className="h-6 w-6" />
            </Button>
          </div>

          {/* Scripts Grid */}
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 md:grid-cols-3">
            {currentScripts
              .sort((a, b) => a.name.localeCompare(b.name))
              .map((script) => (
                <Card
                  key={script.name}
                  className="cursor-pointer p-4 transition-shadow duration-300 hover:shadow-md"
                  onClick={() => handleScriptClick(script.slug)}
                >
                  <CardContent className="flex flex-col gap-4">
                    <h3 className="script-text text-center font-bold text-lg transition-colors duration-300 hover:text-blue-600">
                      {script.name}
                    </h3>
                    <Image
                      src={script.logo || defaultLogo}
                      alt={script.name || "Script logo"}
                      className="mx-auto h-12 w-12 object-contain"
                    />
                    <p className="text-center text-gray-500 text-sm">
                      <b>Created at:</b>{" "}
                      {script.date_created || "No date available"}
                    </p>
                    <p
                      className="text-center text-gray-700 text-sm transition-colors duration-300 hover:text-gray-900"
                      title={script.description || "No description available."}
                    >
                      {truncateDescription(
                        script.description || "No description available."
                      )}
                    </p>
                    {renderResources(script)}
                  </CardContent>
                </Card>
              ))}
          </div>

          {/* Back to Categories Button */}
          <div className="mt-8 text-center">
            <Button
              variant="default"
              onClick={handleBackClick}
              className="rounded-lg bg-blue-600 px-6 py-2 text-white shadow-md transition-transform duration-300 hover:scale-105 hover:bg-blue-700"
            >
              Back to Categories
            </Button>
          </div>
        </div>
      ) : (
        <div>
          {/* Categories Grid */}
          <div className="mb-8 flex items-center justify-between">
            <h1 className="mb-4 font-semibold text-3xl">Categories</h1>
            <p className="text-gray-500 text-sm">
              {categories.reduce(
                (total, category) => total + (category.scripts?.length || 0),
                0
              )}{" "}
              Total scripts
            </p>
          </div>
          <div className="grid grid-cols-1 gap-8 sm:grid-cols-2 md:grid-cols-3">
            {categories.map((category, index) => (
              <Card
                key={category.name}
                onClick={() => handleCategoryClick(index)}
                className="flex cursor-pointer flex-col items-center justify-center py-6 transition-shadow duration-300 hover:shadow-lg"
              >
                <CardContent className="flex flex-col items-center">
                  <h3 className="category-title mb-4 font-bold text-xl transition-colors duration-300 hover:text-blue-600">
                    {category.name}
                  </h3>
                  <div className="mb-4 flex items-center justify-center gap-2">
                    <Button
                      variant="ghost"
                      onClick={(e) => {
                        e.stopPropagation();
                        switchLogos(category.name, "prev");
                      }}
                      className="p-1 transition-transform duration-300 hover:scale-110"
                    >
                      <ChevronLeft className="h-4 w-4" />
                    </Button>
                    {category.scripts &&
                      category.scripts
                        .slice(
                          logoIndices[category.name] || 0,
                          (logoIndices[category.name] || 0) + MAX_LOGOS
                        )
                        .map((script, i) => (
                          <div key={i} className="flex flex-col items-center">
                            <Image
                              src={script.logo || defaultLogo}
                              alt={script.name || "Script logo"}
                              title={script.name}
                              className="h-8 w-8 cursor-pointer object-contain"
                              onClick={(e) => {
                                e.stopPropagation();
                                handleScriptClick(script.slug);
                              }}
                            />
                            {formattedBadge(script.type)}
                          </div>
                        ))}
                    <Button
                      variant="ghost"
                      onClick={(e) => {
                        e.stopPropagation();
                        switchLogos(category.name, "next");
                      }}
                      className="p-1 transition-transform duration-300 hover:scale-110"
                    >
                      <ChevronRight className="h-4 w-4" />
                    </Button>
                  </div>
                  <p className="text-center text-gray-400 text-sm">
                    {(category as any).description ||
                      "No description available."}
                  </p>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

export default CategoryView;
