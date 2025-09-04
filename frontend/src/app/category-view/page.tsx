"use client";

import { ChevronLeft, ChevronRight } from "lucide-react";
import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

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
      return <Badge className="text-blue-500/75 border-blue-500/75 badge">VM</Badge>;
    case "ct":
      return <Badge className="text-yellow-500/75 border-yellow-500/75 badge">LXC</Badge>;
    case "pve":
      return <Badge className="text-orange-500/75 border-orange-500/75 badge">PVE</Badge>;
    case "addon":
      return <Badge className="text-green-500/75 border-green-500/75 badge">ADDON</Badge>;
  }
  return null;
}

function CategoryView() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [selectedCategoryIndex, setSelectedCategoryIndex] = useState<number | null>(null);
  const [currentScripts, setCurrentScripts] = useState<any[]>([]);
  const [logoIndices, setLogoIndices] = useState<{ [key: string]: number }>({});
  const router = useRouter();

  useEffect(() => {
    const fetchCategories = async () => {
      try {
        // eslint-disable-next-line node/no-process-env
        const basePath = process.env.NODE_ENV === "production" ? "/ProxmoxVE" : "";
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
      }
      catch (error) {
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
    const categoryName = selectedCategoryIndex !== null ? categories[selectedCategoryIndex]?.name : null;
    const queryParams = new URLSearchParams({ id: scriptSlug });
    if (categoryName) {
      queryParams.append("category", categoryName);
    }
    router.push(`/scripts?${queryParams.toString()}`);
  };

  const navigateCategory = (direction: "prev" | "next") => {
    if (selectedCategoryIndex !== null) {
      const newIndex
        = direction === "prev"
          ? (selectedCategoryIndex - 1 + categories.length) % categories.length
          : (selectedCategoryIndex + 1) % categories.length;
      setSelectedCategoryIndex(newIndex);
      setCurrentScripts(categories[newIndex]?.scripts || []); // Update scripts for the new category
    }
  };

  const switchLogos = (categoryName: string, direction: "prev" | "next") => {
    setLogoIndices((prev) => {
      const currentIndex = prev[categoryName] || 0;
      const category = categories.find(cat => cat.name === categoryName);
      if (!category || !category.scripts)
        return prev;

      const totalLogos = category.scripts.length;
      const newIndex
        = direction === "prev"
          ? (currentIndex - MAX_LOGOS + totalLogos) % totalLogos
          : (currentIndex + MAX_LOGOS) % totalLogos;

      return { ...prev, [categoryName]: newIndex };
    });
  };

  const truncateDescription = (text: string) => {
    return text.length > MAX_DESCRIPTION_LENGTH ? `${text.slice(0, MAX_DESCRIPTION_LENGTH)}...` : text;
  };

  const renderResources = (script: any) => {
    const cpu = script.install_methods[0]?.resources.cpu;
    const ram = script.install_methods[0]?.resources.ram;
    const hdd = script.install_methods[0]?.resources.hdd;

    const resourceParts = [];
    if (cpu) {
      resourceParts.push(
        <span key="cpu">
          <b>CPU:</b>
          {" "}
          {cpu}
          vCPU
        </span>,
      );
    }
    if (ram) {
      resourceParts.push(
        <span key="ram">
          <b>RAM:</b>
          {" "}
          {ram}
          MB
        </span>,
      );
    }
    if (hdd) {
      resourceParts.push(
        <span key="hdd">
          <b>HDD:</b>
          {" "}
          {hdd}
          GB
        </span>,
      );
    }

    return resourceParts.length > 0
      ? (
          <div className="text-sm text-gray-400">
            {resourceParts.map((part, index) => (
              <React.Fragment key={index}>
                {part}
                {index < resourceParts.length - 1 && " | "}
              </React.Fragment>
            ))}
          </div>
        )
      : null;
  };

  return (
    <div className="p-6 mt-20">
      {categories.length === 0 && (
        <p className="text-center text-gray-500">No categories available. Please check the API endpoint.</p>
      )}
      {selectedCategoryIndex !== null
        ? (
            <div>
              {/* Header with Navigation */}
              <div className="flex items-center justify-between mb-6">
                <Button
                  variant="ghost"
                  onClick={() => navigateCategory("prev")}
                  className="p-2 transition-transform duration-300 hover:scale-105"
                >
                  <ChevronLeft className="h-6 w-6" />
                </Button>
                <h2 className="text-3xl font-semibold transition-opacity duration-300 hover:opacity-90">
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
              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
                {currentScripts
                  .sort((a, b) => a.name.localeCompare(b.name))
                  .map(script => (
                    <Card
                      key={script.name}
                      className="p-4 cursor-pointer hover:shadow-md transition-shadow duration-300"
                      onClick={() => handleScriptClick(script.slug)}
                    >
                      <CardContent className="flex flex-col gap-4">
                        <h3 className="text-lg font-bold script-text text-center hover:text-blue-600 transition-colors duration-300">
                          {script.name}
                        </h3>
                        <img
                          src={script.logo || defaultLogo}
                          alt={script.name || "Script logo"}
                          className="h-12 w-12 object-contain mx-auto"
                        />
                        <p className="text-sm text-gray-500 text-center">
                          <b>Created at:</b>
                          {" "}
                          {script.date_created || "No date available"}
                        </p>
                        <p
                          className="text-sm text-gray-700 hover:text-gray-900 text-center transition-colors duration-300"
                          title={script.description || "No description available."}
                        >
                          {truncateDescription(script.description || "No description available.")}
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
                  className="px-6 py-2 text-white bg-blue-600 hover:bg-blue-700 rounded-lg shadow-md transition-transform duration-300 hover:scale-105"
                >
                  Back to Categories
                </Button>
              </div>
            </div>
          )
        : (
            <div>
              {/* Categories Grid */}
              <div className="flex justify-between items-center mb-8">
                <h1 className="text-3xl font-semibold mb-4">Categories</h1>
                <p className="text-sm text-gray-500">
                  {categories.reduce((total, category) => total + (category.scripts?.length || 0), 0)}
                  {" "}
                  Total scripts
                </p>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-8">
                {categories.map((category, index) => (
                  <Card
                    key={category.name}
                    onClick={() => handleCategoryClick(index)}
                    className="cursor-pointer hover:shadow-lg flex flex-col items-center justify-center py-6 transition-shadow duration-300"
                  >
                    <CardContent className="flex flex-col items-center">
                      <h3 className="text-xl font-bold mb-4 category-title transition-colors duration-300 hover:text-blue-600">
                        {category.name}
                      </h3>
                      <div className="flex justify-center items-center gap-2 mb-4">
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
                        {category.scripts
                          && category.scripts
                            .slice(logoIndices[category.name] || 0, (logoIndices[category.name] || 0) + MAX_LOGOS)
                            .map((script, i) => (
                              <div key={i} className="flex flex-col items-center">
                                <img
                                  src={script.logo || defaultLogo}
                                  alt={script.name || "Script logo"}
                                  title={script.name}
                                  className="h-8 w-8 object-contain cursor-pointer"
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
                      <p className="text-sm text-gray-400 text-center">
                        {(category as any).description || "No description available."}
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
