import { Monitor, Smartphone, Cloud, Boxes, Terminal, MousePointerClick } from "lucide-react";
import type { Script } from "@/lib/types";

interface PlatformRowProps {
  label: string;
  items: string[];
  icon: React.ReactNode;
}

function PlatformRow({ label, items, icon }: PlatformRowProps) {
  if (!items.length) return null;

  return (
    <div className="flex items-center gap-2 text-xs text-muted-foreground">
      {icon}
      <span className="w-16 shrink-0 text-[11px] uppercase tracking-wide text-muted-foreground">
        {label}
      </span>
      <div className="flex flex-wrap gap-1.5">
        {items.map((item) => (
          <span
            key={item}
            className="rounded-full border px-2 py-0.5 text-[10px] leading-none font-medium"
          >
            {item}
          </span>
        ))}
      </div>
    </div>
  );
}

export default function DefaultSettings({ item }: { item: Script }) {
  // Ambil install method default (atau pertama kalau nggak ada)
  const defaultMethod =
    item.install_methods.find((m) => m.type === "default") ?? item.install_methods[0];

  // platform disimpan di dalam install_methods[].platform (lihat JSON yang kamu kirim)
  const platform = (defaultMethod as any)?.platform;

  // Kalau belum didefinisikan, nggak usah render apa-apa
  if (!platform) return null;

  const desktop = [
    platform.desktop?.macos && "macOS",
    platform.desktop?.linux && "Linux",
    platform.desktop?.windows && "Windows",
  ].filter(Boolean) as string[];

  const mobile = [
    platform.mobile?.android && "Android",
    platform.mobile?.ios && "iOS",
  ].filter(Boolean) as string[];

  const hosting = [
    platform.hosting?.saas && "SaaS",
    platform.hosting?.self_hosted && "Self-hosted",
    platform.hosting?.managed_cloud && "Managed cloud",
  ].filter(Boolean) as string[];

  const deployment = [
    platform.deployment?.binary && "Script",
    platform.deployment?.docker && "Docker",
    platform.deployment?.docker_compose && "Docker Compose",
    (platform.deployment?.helm?.oci_artifact ||
      platform.deployment?.helm?.helm_repository) && "Helm",
    platform.deployment?.kubernetes && "Kubernetes",
    platform.deployment?.terraform && "Terraform",
  ].filter(Boolean) as string[];

  const ui = [
    platform.ui?.cli && "CLI",
    platform.ui?.tui && "TUI",
    platform.ui?.gui && "GUI",
    platform.ui?.web_ui && "Web UI",
    platform.ui?.api && "API",
  ].filter(Boolean) as string[];

  const interfaceIcon = platform.cli_only ? (
    <Terminal className="h-3 w-3 shrink-0" />
  ) : (
    <MousePointerClick className="h-3 w-3 shrink-0" />
  );

  return (
    <div className="flex flex-col space-y-2">
      <div className="text-[11px] font-semibold uppercase text-muted-foreground">
        Platform
      </div>

      <PlatformRow
        label="Desktop"
        items={desktop}
        icon={<Monitor className="h-3 w-3 shrink-0" />}
      />

      <PlatformRow
        label="Mobile"
        items={mobile}
        icon={<Smartphone className="h-3 w-3 shrink-0" />}
      />

      <PlatformRow
        label="Hosting"
        items={hosting}
        icon={<Cloud className="h-3 w-3 shrink-0" />}
      />

      <PlatformRow
        label="Deploy"
        items={deployment}
        icon={<Boxes className="h-3 w-3 shrink-0" />}
      />

      <PlatformRow
        label="Interface"
        items={ui}
        icon={interfaceIcon}
      />
    </div>
  );
}
