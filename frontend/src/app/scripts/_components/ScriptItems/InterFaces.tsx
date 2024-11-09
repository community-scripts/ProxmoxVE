import handleCopy from "@/components/handleCopy";
import { buttonVariants } from "@/components/ui/button";
import { Script } from "@/lib/types";
import { cn } from "@/lib/utils";
import { ClipboardIcon } from "lucide-react";

const CopyButton = ({
  label,
  value,
}: {
  label: string;
  value: string | number;
}) => (
  <span
    className={cn(
      buttonVariants({ size: "sm", variant: "secondary" }),
      "flex items-center gap-2",
    )}
  >
    {value}
    <ClipboardIcon
      onClick={() => handleCopy(label, String(value))}
      className="size-4 cursor-pointer"
    />
  </span>
);

export default function InterFaces({ item }: { item: Script }) {
  return (
    <div className="flex flex-col gap-2">
      {item.interface_port !== null ? (
        <div className="flex items-center justify-end">
          <h2 className="mr-2 text-end text-lg font-semibold">
            {"Default Interface:"}
          </h2>{" "}
          <CopyButton label="default interface" value={item.interface_port} />
        </div>
      ) : null}
    </div>
  );
}
