import { AlertCircle, NotepadText } from "lucide-react";

import type { Script } from "@/lib/types";

import TextCopyBlock from "@/components/text-copy-block";
import { AlertColors } from "@/config/site-config";
import { cn } from "@/lib/utils";

type NoteProps = {
  text: string;
  type: keyof typeof AlertColors;
};

export default function Alerts({ item }: { item: Script }) {
  return (
    <>
      {item?.notes?.length > 0
        && item.notes.map((note: NoteProps, index: number) => (
          <div key={index} className="mt-4 flex flex-col shadow-sm gap-2">
            <p
              className={cn(
                "inline-flex items-center gap-2 rounded-lg border p-2 pl-4 text-sm",
                AlertColors[note.type],
              )}
            >
              {note.type === "info"
                ? (
                    <NotepadText className="h-4 min-h-4 w-4 min-w-4" />
                  )
                : (
                    <AlertCircle className="h-4 min-h-4 w-4 min-w-4" />
                  )}
              <span>{TextCopyBlock(note.text)}</span>
            </p>
          </div>
        ))}
    </>
  );
}
