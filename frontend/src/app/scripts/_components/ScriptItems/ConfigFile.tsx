import CodeCopyButton from "@/components/ui/code-copy-button";
import { Script } from "@/lib/types";

export default function ConfigFile({ item }: { item: Script }) {
  return (
    <div className="px-4 pb-4">
      <CodeCopyButton>{item.config_path ? item.config_path : "No config path set"}</CodeCopyButton>
    </div>
  );
}
