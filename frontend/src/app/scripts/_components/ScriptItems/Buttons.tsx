import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { basePath } from "@/config/siteConfig";
import { Script } from "@/lib/types";
import { BookOpenText, Code, Globe, LinkIcon, RefreshCcw } from "lucide-react";

const generateInstallSourceUrl = (slug: string) => {
  const baseUrl = `https://raw.githubusercontent.com/community-scripts/${basePath}/main`;
  return `${baseUrl}/install/${slug}-install.sh`;
};

const generateSourceUrl = (slug: string, type: string) => {
  const baseUrl = `https://raw.githubusercontent.com/community-scripts/${basePath}/main`;
  return type === "vm" ? `${baseUrl}/vm/${slug}.sh` : `${baseUrl}/misc/${slug}.sh`;
};

const generateUpdateUrl = (slug: string) => {
  const baseUrl = `https://raw.githubusercontent.com/community-scripts/${basePath}/main`;
  return `${baseUrl}/ct/${slug}.sh`;
};

interface LinkItem {
  href: string;
  icon: React.ReactNode;
  text: string;
}

export default function Buttons({ item }: { item: Script }) {
  const isCtOrDefault = ["ct"].includes(item.type);
  const installSourceUrl = isCtOrDefault ? generateInstallSourceUrl(item.slug) : null;
  const updateSourceUrl = isCtOrDefault ? generateUpdateUrl(item.slug) : null;
  const sourceUrl = !isCtOrDefault ? generateSourceUrl(item.slug, item.type) : null;

  const links = [
    item.website && {
      href: item.website,
      icon: <Globe className="h-4 w-4" />,
      text: "Website",
    },
    item.documentation && {
      href: item.documentation,
      icon: <BookOpenText className="h-4 w-4" />,
      text: "Documentation",
    },
    installSourceUrl && {
      href: installSourceUrl,
      icon: <Code className="h-4 w-4" />,
      text: "Install Source",
    },
    updateSourceUrl && {
      href: updateSourceUrl,
      icon: <RefreshCcw className="h-4 w-4" />,
      text: "Update Source",
    },
    sourceUrl && {
      href: sourceUrl,
      icon: <Code className="h-4 w-4" />,
      text: "Source Code",
    },
  ].filter(Boolean) as LinkItem[];

  if (links.length === 0) return null;

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="secondary" className="flex items-center gap-2">
          <LinkIcon className="size-4" />
          Links
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        {links.map((link, index) => (
          <DropdownMenuItem key={index} asChild>
            <a href={link.href} target="_blank" rel="noopener noreferrer" className="flex items-center gap-2">
              <span className="text-muted-foreground size-4">{link.icon}</span>
              <span>{link.text}</span>
            </a>
          </DropdownMenuItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
