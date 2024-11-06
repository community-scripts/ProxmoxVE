import TextCopyBlock from "@/components/TextCopyBlock";
import { Script } from "@/lib/types";
import { Info } from "lucide-react";

export default function Alerts({ item }: { item: Script }) {
  return (
    <>
      {item?.notes?.length > 0 &&
        item.notes.map((note: any, index: number) => (
          <div key={index} className="mt-4 flex flex-col gap-2">
            <p className="inline-flex items-center gap-2 rounded-lg border border-red-500/25 bg-destructive/25 p-2 pl-4 text-sm">
              <Info className="h-4 min-h-4 w-4 min-w-4" />
              <span>{TextCopyBlock(note.text)}</span>
            </p>
          </div>
        ))}
    </>
  );
}
