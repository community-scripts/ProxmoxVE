import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { basePath, mostPopularScripts } from "@/config/siteConfig";
import { extractDate } from "@/lib/time";
import { Category, Script } from "@/lib/types";
import { CalendarPlus } from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { useMemo, useState } from "react";

const ITEMS_PER_PAGE = 3;

export const getDisplayValueFromType = (type: string) => {
  switch (type) {
    case "ct":
      return "LXC";
    case "vm":
      return "VM";
    case "misc":
      return "";
    default:
      return "";
  }
};

export function LatestScripts({ items }: { items: Category[] }) {
  const [page, setPage] = useState(1);

  const latestScripts = useMemo(() => {
    if (!items) return [];
    const scripts = items.flatMap((category) => category.scripts || []);
    return scripts.sort(
      (a, b) =>
        new Date(b.date_created).getTime() - new Date(a.date_created).getTime(),
    );
  }, [items]);

  const goToNextPage = () => {
    setPage((prevPage) => prevPage + 1);
  };

  const goToPreviousPage = () => {
    setPage((prevPage) => prevPage - 1);
  };

  const startIndex = (page - 1) * ITEMS_PER_PAGE;
  const endIndex = page * ITEMS_PER_PAGE;

  if (!items) {
    return null;
  }

  return (
    <div className="">
      {latestScripts.length > 0 && (
        <div className="flex w-full items-center justify-between">
          <h2 className="text-lg font-semibold">Newest Scripts</h2>
          <div className="flex items-center justify-end gap-1">
            {page > 1 && (
              <div
                className="cursor-pointer select-none p-2 text-sm font-semibold"
                onClick={goToPreviousPage}
              >
                Previous
              </div>
            )}
            {endIndex < latestScripts.length && (
              <div
                onClick={goToNextPage}
                className="cursor-pointer select-none p-2 text-sm font-semibold"
              >
                {page === 1 ? "More.." : "Next"}
              </div>
            )}
          </div>
        </div>
      )}
      <div className="min-w flex w-full flex-row flex-wrap gap-4">
        {latestScripts.slice(startIndex, endIndex).map((script) => (
          <Card
            key={script.slug}
            className="min-w-[250px] flex-1 flex-grow bg-accent/30"
          >
            <CardHeader>
              <CardTitle className="flex items-center gap-3">
                <div className="flex h-16 w-16 items-center justify-center rounded-lg bg-accent p-1">
                  <Image
                    src={script.logo || `/${basePath}/logo.png`}
                    unoptimized
                    height={64}
                    width={64}
                    alt=""
                    onError={(e) =>
                      ((e.currentTarget as HTMLImageElement).src =
                        `/${basePath}/logo.png`)
                    }
                    className="h-11 w-11 object-contain"
                  />
                </div>
                <div className="flex flex-col">
                  <p className="text-lg line-clamp-1">
                    {script.name} {getDisplayValueFromType(script.type)}
                  </p>
                  <p className="text-sm text-muted-foreground flex items-center gap-1">
                    <CalendarPlus className="h-4 w-4" />
                    {extractDate(script.date_created)}
                  </p>
                </div>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <CardDescription className="line-clamp-3 text-card-foreground">
                {script.description}
              </CardDescription>
            </CardContent>
            <CardFooter className="">
              <Button asChild variant="outline">
                <Link
                  href={{
                    pathname: "/scripts",
                    query: { id: script.slug },
                  }}
                >
                  View Script
                </Link>
              </Button>
            </CardFooter>
          </Card>
        ))}
      </div>
    </div>
  );
}

export function MostViewedScripts({ items }: { items: Category[] }) {
  const mostViewedScripts = items.reduce((acc: Script[], category) => {
    const foundScripts = category.scripts.filter((script) =>
      mostPopularScripts.includes(script.name),
    );
    return acc.concat(foundScripts);
  }, []);

  return (
    <div className="">
      {mostViewedScripts.length > 0 && (
        <>
          <h2 className="text-lg font-semibold">Most Viewed Scripts</h2>
        </>
      )}
      <div className="min-w flex w-full flex-row flex-wrap gap-4">
        {mostViewedScripts.map((script) => (
          <Card
            key={script.slug}
            className="min-w-[250px] flex-1 flex-grow bg-accent/30"
          >
            <CardHeader>
              <CardTitle className="flex items-center gap-3">
                <div className="flex max-h-16 min-h-16 min-w-16 max-w-16 items-center justify-center rounded-lg bg-accent p-1">
                  <Image
                    unoptimized
                    src={script.logo || `/${basePath}/logo.png`}
                    height={64}
                    width={64}
                    alt=""
                    onError={(e) =>
                      ((e.currentTarget as HTMLImageElement).src =
                        `/${basePath}/logo.png`)
                    }
                    className="h-11 w-11 object-contain"
                  />
                </div>
                <div className="flex flex-col">
                  <p className="line-clamp-1 text-lg">
                    {script.name} {getDisplayValueFromType(script.type)}
                  </p>
                  <p className="flex items-center gap-1 text-sm text-muted-foreground">
                    <CalendarPlus className="h-4 w-4" />
                    {extractDate(script.date_created)}
                  </p>
                </div>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <CardDescription className="line-clamp-3 text-card-foreground break-words">
                {script.description}
              </CardDescription>
            </CardContent>
            <CardFooter className="">
              <Button asChild variant="outline">
                <Link
                  href={{
                    pathname: "/scripts",
                    query: { id: script.slug },
                  }}
                  prefetch={false}
                >
                  View Script
                </Link>
              </Button>
            </CardFooter>
          </Card>
        ))}
      </div>
    </div>
  );
}
