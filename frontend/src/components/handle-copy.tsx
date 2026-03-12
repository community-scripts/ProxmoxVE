import { ClipboardCheck } from "lucide-react";
import { toast } from "sonner";

export default function handleCopy(type: string, value: string) {
  navigator.clipboard.writeText(value);

  toast.success(`copied ${type} to clipboard`, {
    icon: <ClipboardCheck className="h-4 w-4" />,
  });
}
