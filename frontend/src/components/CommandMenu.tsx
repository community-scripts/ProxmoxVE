import {
  CommandDialog,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command";
import { fetchCategories } from "@/lib/data";
import { Category } from "@/lib/types";
import { cn } from "@/lib/utils";
import Image from "next/image";
import { useRouter } from "next/navigation";
import React from "react";
import { Badge } from "./ui/badge";
import { Button } from "./ui/button";
import { DialogTitle } from "./ui/dialog";
import { basePath } from "@/config/siteConfig";

export const formattedBadge = (type: string) => {
  switch (type) {
    case "vm":
      return <Badge className="text-blue-500/75 border-blue-500/75">VM</Badge>;
    case "ct":
      return (
        <Badge className="text-yellow-500/75 border-yellow-500/75">LXC</Badge>
      );
    case "misc":
      return <Badge className="text-green-500/75 border-green-500/75">MISC</Badge>;
  }
  return null;
};

export default function CommandMenu() {
  const [open, setOpen] = React.useState(false);
  const [links, setLinks] = React.useState<Category[]>([]);
  const router = useRouter();
  const [isLoading, setIsLoading] = React.useState(false);

  React.useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.key === "k" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        fetchSortedCategories();
        setOpen((open) => !open);
      }
    };

    document.addEventListener("keydown", down);
    return () => document.removeEventListener("keydown", down);
  }, []);

  const fetchSortedCategories = () => {
    setIsLoading(true);
    fetchCategories()
      .then((categories) => {
        setLinks(categories);
        setIsLoading(false);
      })
      .catch((error) => {
        setIsLoading(false);
        console.error(error);
      });
  };

  return (
    <>
      <Button
        variant="outline"
        className={cn(
          "relative h-9 w-full justify-start rounded-[0.5rem] bg-muted/50 text-sm font-normal text-muted-foreground shadow-none sm:pr-12 md:w-40 lg:w-64",
        )}
        onClick={() => {
          fetchSortedCategories();
          setOpen(true);
        }}
      >
        <span className="inline-flex">Search scripts...</span>
        <kbd className="pointer-events-none absolute right-[0.3rem] top-[0.45rem] hidden h-5 select-none items-center gap-1 rounded border bg-muted px-1.5 font-mono text-[10px] font-medium opacity-100 sm:flex">
          <span className="text-xs">⌘</span>K
        </kbd>
      </Button>
      <CommandDialog open={open} onOpenChange={setOpen}>
        <DialogTitle className="sr-only">Search scripts</DialogTitle>
        <CommandInput placeholder="Search for a script..." />
        <CommandList>
          <CommandEmpty>
            {isLoading ? "Loading..." : "No scripts found."}
          </CommandEmpty>
          {links.map((category) => (
            <CommandGroup
              key={`category:${category.name}`}
              heading={category.name}
            >
              {category.scripts.map((script) => (
                <CommandItem
                  key={`script:${script.slug}`}
                  value={`${script.slug}-${script.name}`}
                  onSelect={() => {
                    setOpen(false);
                    router.push(`/scripts?id=${script.slug}`);
                  }}
                >
                  <div className="flex gap-2" onClick={() => setOpen(false)}>
                    <Image
                      src={script.logo || `/${basePath}/logo.png`}
                      onError={(e) =>
                        ((e.currentTarget as HTMLImageElement).src =
                          `/${basePath}/logo.png`)
                      }
                      unoptimized
                      width={16}
                      height={16}
                      alt=""
                      className="h-5 w-5"
                    />
                    <span>{script.name}</span>
                    <span>{formattedBadge(script.type)}</span>
                  </div>
                </CommandItem>
              ))}
            </CommandGroup>
          ))}
        </CommandList>
      </CommandDialog>
    </>
  );
}
