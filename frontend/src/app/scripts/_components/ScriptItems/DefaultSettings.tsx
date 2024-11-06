import { Script } from "@/lib/types";

export default function DefaultSettings({ item }: { item: Script }) {
  const defaultSettings = item.install_methods.find(
    (method) => method.type === "default",
  );

  const defaultSettingsAvailable =
    defaultSettings?.resources.cpu !== null ||
    defaultSettings?.resources.ram !== null ||
    defaultSettings?.resources.hdd !== null;

  const defaultAlpineSettings = item.install_methods.find(
    (method) => method.type === "alpine",
  );

  const convertMBtoGB = (value: number) => {
    if (value >= 1024) {
      return (value / 1024).toFixed(0) + "GB";
    }
    return value + "MB";
  };

  return (
    <>
      {defaultSettingsAvailable && (
        <div>
          <h2 className="text-md font-semibold">Default settings</h2>
          <p className="text-sm text-muted-foreground">
            CPU: {defaultSettings?.resources.cpu}vCPU
          </p>
          <p className="text-sm text-muted-foreground">
            RAM: {convertMBtoGB(defaultSettings?.resources.ram ?? 0)}
          </p>
          <p className="text-sm text-muted-foreground">
            HDD: {defaultSettings?.resources.hdd}GB
          </p>
        </div>
      )}
      {defaultAlpineSettings && (
        <div>
          <h2 className="text-md font-semibold">Default Alpine settings</h2>
          <p className="text-sm text-muted-foreground">
            CPU: {defaultAlpineSettings?.resources.cpu}vCPU
          </p>
          <p className="text-sm text-muted-foreground">
            RAM: {convertMBtoGB(defaultAlpineSettings?.resources.ram ?? 0)}
          </p>
          <p className="text-sm text-muted-foreground">
            HDD: {defaultAlpineSettings?.resources.hdd}GB
          </p>
        </div>
      )}
    </>
  );
}
