import { Button } from "@/components/ui/button";
import { basePath } from "@/config/siteConfig";
import { Script } from "@/lib/types";
import { BookOpenText, Code, Globe, RefreshCcw } from "lucide-react";
import Link from "next/link";

const generateInstallSourceUrl = (slug: string) => {
  const baseUrl = `https://raw.githubusercontent.com/community-scripts/${basePath}/main`;
  return `${baseUrl}/install/${slug}-install.sh`;
};

const generateSourceUrl = (slug: string, type: string) => {
  const baseUrl = `https://raw.githubusercontent.com/community-scripts/${basePath}/main`;
  return type === "vm" ? `${baseUrl}/vm/${slug}.sh` : `${baseUrl}/misc/${slug}.sh`;
  return `${baseUrl}/misc/${slug}.sh`;
};

const generateUpdateUrl = (slug: string) => {
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
  const isCtOrDefault = ["ct"].includes(item.type);
  const installSourceUrl = isCtOrDefault ? generateInstallSourceUrl(item.slug) : null;
  const updateSourceUrl = isCtOrDefault ? generateUpdateUrl(item.slug) : null;
  const sourceUrl = !isCtOrDefault ? generateSourceUrl(item.slug, item.type) : null;

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
    installSourceUrl && {
      href: installSourceUrl,
      icon: <Code className="h-4 w-4" />, 
      text: "Install-Source",
    },
    updateSourceUrl && {
      href: updateSourceUrl,
      icon: <RefreshCcw className="h-4 w-4" />, 
      text: "Update-Source",
    },
    sourceUrl && {
      href: sourceUrl,
      icon: <Code className="h-4 w-4" />, 
      text: "Source Code",
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
