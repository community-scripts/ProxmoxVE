import type { Script } from "@/lib/types";

import TextCopyBlock from "@/components/text-copy-block";

export default function Description({ item }: { item: Script }) {
  return (
    <div className="p-2">
      <h2 className="mb-2 max-w-prose font-semibold text-lg">Description</h2>
      <p className="text-muted-foreground text-sm">
        {TextCopyBlock(item.description)}
      </p>
    </div>
  );
}
