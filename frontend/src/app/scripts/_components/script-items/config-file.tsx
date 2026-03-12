import ConfigCopyButton from "@/components/ui/config-copy-button";

export default function ConfigFile({ configPath }: { configPath: string }) {
  return (
    <div className="px-4 pb-4">
      <ConfigCopyButton>{configPath}</ConfigCopyButton>
    </div>
  );
}
