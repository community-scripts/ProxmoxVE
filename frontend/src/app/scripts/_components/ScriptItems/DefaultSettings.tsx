import { Script } from "@/lib/types";

export default function DefaultSettings({ item }: { item: Script }) {
  const defaultSettings = item.install_methods.find(
    (method) => method.type === "default",
  );

  const defaultAlpineSettings = item.install_methods.find(
    (method) => method.type === "alpine",
  );

  return (
    <>
      {defaultSettings && (
        <div>
          <h2 className="text-md font-semibold">Default settings</h2>
          <p className="text-sm text-muted-foreground">
            CPU: {defaultSettings.resources.cpu}vCPU
          </p>
          <p className="text-sm text-muted-foreground">
            RAM: {defaultSettings.resources.ram}MB
          </p>
          <p className="text-sm text-muted-foreground">
            HDD: {defaultSettings.resources.hdd}GB
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
            RAM: {defaultAlpineSettings?.resources.ram}MB
          </p>
          <p className="text-sm text-muted-foreground">
            HDD: {defaultAlpineSettings?.resources.hdd}GB
          </p>
        </div>
      )}
    </>
  );
}
