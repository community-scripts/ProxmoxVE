import { Script } from "@/lib/types";

export default function DefaultSettings({ item }: { item: Script }) {
  const getDisplayValueFromRAM = (ram: number) =>
    ram >= 1024 ? `${Math.floor(ram / 1024)}GB` : `${ram}MB`;

  const ResourceDisplay = ({
    settings,
    title,
  }: {
    settings: (typeof item.install_methods)[0];
    title: string;
  }) => {
    const { cpu, ram, hdd } = settings.resources;
    return (
      <div>
        <h2 className="text-md font-semibold">{title}</h2>
        <p className="text-sm text-muted-foreground">CPU: {cpu}vCPU</p>
        <p className="text-sm text-muted-foreground">
          RAM: {getDisplayValueFromRAM(ram ?? 0)}
        </p>
        <p className="text-sm text-muted-foreground">HDD: {hdd}GB</p>
      </div>
    );
  };

  const defaultSettings = item.install_methods.find(
    (method) => method.type === "default",
  );
  const defaultAlpineSettings = item.install_methods.find(
    (method) => method.type === "alpine",
  );

  const hasDefaultSettings =
    defaultSettings?.resources &&
    Object.values(defaultSettings.resources).some(Boolean);

  return (
    <>
      {hasDefaultSettings && (
        <ResourceDisplay settings={defaultSettings} title="Default settings" />
      )}
      {defaultAlpineSettings && (
        <ResourceDisplay
          settings={defaultAlpineSettings}
          title="Default Alpine settings"
        />
      )}
    </>
  );
}
