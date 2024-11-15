import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { AlertColors } from "@/config/siteConfig";
import { cn } from "@/lib/utils";
import { PlusCircle, Trash2 } from "lucide-react";
import { z } from "zod";
import { ScriptSchema } from "../_schemas/schemas";

type Script = z.infer<typeof ScriptSchema>;

type NoteProps = {
  script: Script;
  setScript: (script: Script) => void;
  setIsValid: (isValid: boolean) => void;
  setZodErrors: (zodErrors: z.ZodError | null) => void;
};
export default function Note({
  script,
  setScript,
  setIsValid,
  setZodErrors,
}: NoteProps) {
  const addNote = () => {
    const newScript: Script = {
      ...script,
      notes: [...script.notes, { text: "", type: "" }],
    };
    setScript(newScript);
  };

  const updateNote = (
    index: number,
    key: keyof Script["notes"][number],
    value: string,
  ) => {
    const updated: Script = {
      ...script,
      notes: script.notes.map((note: Script["notes"][number], i: number) =>
        i === index ? { ...note, [key]: value } : note,
      ),
    };
    const result = ScriptSchema.safeParse(updated);
    setIsValid(result.success);
    if (!result.success) {
      setZodErrors(result.error);
    } else {
      setZodErrors(null);
    }
    setScript(updated);
  };

  const removeNote = (index: number) => {
    const newScript: Script = {
      ...script,
      notes: script.notes.filter((_: Script["notes"][number], i: number) => i !== index),
    };
    setScript(newScript);
  };

  return (
    <>
      <h3 className="text-xl font-semibold">Notes</h3>
      {script.notes.map((note, index) => (
        <div key={index} className="space-y-2 border p-4 rounded">
          <Input
            placeholder="Note Text"
            value={note.text}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => updateNote(index, "text", e.target.value)}
          />
          <Select
            value={note.type}
            onValueChange={(value: string) => updateNote(index, "type", value)}
          >
            <SelectTrigger className="flex-1">
              <SelectValue placeholder="Type" />
            </SelectTrigger>
            <SelectContent>
              {Object.keys(AlertColors).map((type) => (
                <SelectItem key={type} value={type}>
                  <span className="flex items-center gap-2">
                    {type.charAt(0).toUpperCase() + type.slice(1)}{" "}
                    <div
                      className={cn(
                        "size-4 rounded-full border",
                        AlertColors[type as keyof typeof AlertColors],
                      )}
                    />
                  </span>
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Button
            size={"sm"}
            variant="destructive"
            type="button"
            onClick={() => removeNote(index)}
          >
            <Trash2 className="mr-2 h-4 w-4" /> Remove Note
          </Button>
        </div>
      ))}
      <Button type="button" size={"sm"} onClick={addNote}>
        <PlusCircle className="mr-2 h-4 w-4" /> Add Note
      </Button>
    </>
  );
}
