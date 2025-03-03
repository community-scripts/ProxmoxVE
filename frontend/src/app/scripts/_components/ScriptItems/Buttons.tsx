import { Button } from "@/components/ui/button";
import { basePath } from "@/config/siteConfig";
import { Script } from "@/lib/types";
import { BookOpenText, Code, Globe, RefreshCcw } from "lucide-react";
import Link from "next/link";

const generateSourceUrl = (slug: string, type: string) => {
  const baseUrl = `https://raw.githubusercontent.com/community-scripts/${basePath}/main`;
  return type === "ct"
    ? `${baseUrl}/install/${slug}-install.sh`
    : `${baseUrl}/misc/${slug}.sh`;
};

const generateUpdateUrl = (slug: string, type: string) => {
  if (type !== "ct") return null;
  const baseUrl = `https://raw.githubusercontent.com/community-scripts/${basePath}/main`;
  return `${baseUrl}/ct/${slug}.sh`;
};

interface ButtonLinkProps {
  href: string;
  icon: React.ReactNode;
  text: string;
}

const ButtonLink = ({ href, icon, text }: ButtonLinkProps) => (
  <Button variant="secondary" asChild>
    <Link target="_blank" href={href}>
      <span className="flex items-center gap-2">
        {icon}
        {text}
      </span>
    </Link>
  </Button>
);

export default function Buttons({ item }: { item: Script }) {
  const sourceUrl = generateSourceUrl(item.slug, item.type);
  const updateUrl = generateUpdateUrl(item.slug, item.type);

  const buttons = [
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
    {
      href: sourceUrl,
      icon: <Code className="h-4 w-4" />,
      text: item.type === "ct" || item.type === "default" ? "Install-Source" : "Source Code",
    },
    updateUrl && {
      href: updateUrl,
      icon: <RefreshCcw className="h-4 w-4" />,
      text: "Update-Source",
    },
  ].filter(Boolean) as ButtonLinkProps[];

  return (
    <div className="flex flex-wrap justify-end gap-2">
      {buttons.map((props, index) => (
        <ButtonLink key={index} {...props} />
      ))}
    </div>
  );
}