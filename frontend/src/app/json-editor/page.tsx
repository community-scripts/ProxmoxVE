"use client";

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Input } from "@/components/ui/input";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { fetchCategories } from "@/lib/data";
import { Category } from "@/lib/types";
import { cn } from "@/lib/utils";
import { AlertCircle, CalendarIcon, Check, Clipboard, PlusCircle, Trash2 } from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { z } from "zod";
import { format } from "date-fns";
import { Label } from "@/components/ui/label";
import { AlertColors } from "@/config/siteConfig";
import { InstallMethodSchema, ScriptSchema } from "./_schemas/schemas";
import InstallMethod from "./_components/InstallMethod";
import Note from "./_components/Note";
import Categories from "./_components/Categories";

type Script = z.infer<typeof ScriptSchema>;

export default function JSONGenerator() {
  const [script, setScript] = useState<Script>({
    name: "",
    slug: "",
    categories: [],
    date_created: "",
    type: "ct",
    updateable: false,
    privileged: false,
    interface_port: null,
    documentation: null,
    website: null,
    logo: null,
    description: "",
    install_methods: [],
    default_credentials: {
      username: null,
      password: null,
    },
    notes: [],
  });
  const [isCopied, setIsCopied] = useState(false);

  const [isValid, setIsValid] = useState(false);
  const [categories, setCategories] = useState<Category[]>([]);
  const [zodErrors, setZodErrors] = useState<z.ZodError | null>(null);

  useEffect(() => {
    fetchCategories()
      .then((data) => {
        setCategories(data);
      })
      .catch((error) => console.error("Error fetching categories:", error));
  }, []);

  const updateScript = (key: keyof Script, value: Script[keyof Script]) => {
    setScript((prev) => {
      const updated = { ...prev, [key]: value };

      // Update script paths for install methods if `type` or `slug` changed
      if (key === "type" || key === "slug") {
        updated.install_methods = updated.install_methods.map((method) => ({
          ...method,
          script:
            method.type === "alpine"
              ? `/${updated.type}/alpine-${updated.slug}.sh`
              : `/${updated.type}/${updated.slug}.sh`,
        }));
      }

      const result = ScriptSchema.safeParse(updated);
      setIsValid(result.success);
      if (!result.success) {
        setZodErrors(result.error);
      } else {
        setZodErrors(null);
      }
      return updated;
    });
  };

  return (
    <div className="flex h-screen mt-20">
      <div className="w-1/2 p-4 overflow-y-auto">
        <h2 className="text-2xl font-bold mb-4">JSON Generator</h2>
        <form className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label>
                Name <span className="text-red-500">*</span>
              </Label>
              <Input
                placeholder="Example"
                value={script.name}
                onChange={(e) => updateScript("name", e.target.value)}
              />
            </div>
            <div>
              <Label>
                Slug <span className="text-red-500">*</span>
              </Label>
              <Input
                placeholder="example"
                value={script.slug}
                onChange={(e) => updateScript("slug", e.target.value)}
              />
            </div>
          </div>
          <div>
            <Label>
              Logo <span className="text-red-500">*</span>
            </Label>
            <Input
              placeholder="Full logo URL"
              value={script.logo || ""}
              onChange={(e) => updateScript("logo", e.target.value || null)}
            />
          </div>
          <div>
            <Label>
              Description <span className="text-red-500">*</span>
            </Label>
            <Textarea
              placeholder="Example"
              value={script.description}
              onChange={(e) => updateScript("description", e.target.value)}
            />
          </div>
          <Categories
            script={script}
            setScript={setScript}
            categories={categories}
          />
          <div className="flex gap-2">
            <div className="flex flex-col gap-2 w-full">
              <Label>Date Created</Label>
              <Popover>
                <PopoverTrigger asChild className="flex-1">
                  <Button
                    variant={"outline"}
                    className={cn(
                      "pl-3 text-left font-normal w-full",
                      !script.date_created && "text-muted-foreground",
                    )}
                  >
                    {script.date_created ? (
                      format(script.date_created, "PPP")
                    ) : (
                      <span>Pick a date</span>
                    )}
                    <CalendarIcon className="ml-auto h-4 w-4 opacity-50" />
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0" align="start">
                  <Calendar
                    mode="single"
                    selected={new Date(script.date_created)}
                    onSelect={(date) =>
                      updateScript(
                        "date_created",
                        format(date || new Date(), "yyyy-MM-dd"),
                      )
                    }
                    initialFocus
                  />
                </PopoverContent>
              </Popover>
            </div>
            <div className="flex flex-col gap-2 w-full">
              <Label>Type</Label>
              <Select
                value={script.type}
                onValueChange={(value) => updateScript("type", value)}
              >
                <SelectTrigger className="flex-1">
                  <SelectValue placeholder="Type" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ct">LXC Container</SelectItem>
                  <SelectItem value="vm">Virtual Machine</SelectItem>
                  <SelectItem value="misc">Miscellaneous</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="w-full flex gap-5">
            <div className="flex items-center space-x-2">
              <Switch
                checked={script.updateable}
                onCheckedChange={(checked) =>
                  updateScript("updateable", checked)
                }
              />
              <label>Updateable</label>
            </div>
            <div className="flex items-center space-x-2">
              <Switch
                checked={script.privileged}
                onCheckedChange={(checked) =>
                  updateScript("privileged", checked)
                }
              />
              <label>Privileged</label>
            </div>
          </div>
          <Input
            placeholder="Interface Port"
            type="number"
            value={script.interface_port || ""}
            onChange={(e) =>
              updateScript(
                "interface_port",
                e.target.value ? Number(e.target.value) : null,
              )
            }
          />
          <div className="flex gap-2">
            <Input
              placeholder="Website URL"
              value={script.website || ""}
              onChange={(e) => updateScript("website", e.target.value || null)}
            />
            <Input
              placeholder="Documentation URL"
              value={script.documentation || ""}
              onChange={(e) =>
                updateScript("documentation", e.target.value || null)
              }
            />
          </div>
          <InstallMethod
            script={script}
            setScript={setScript}
            setIsValid={setIsValid}
            setZodErrors={setZodErrors}
          />
          <h3 className="text-xl font-semibold">Default Credentials</h3>
          <Input
            placeholder="Username"
            value={script.default_credentials.username || ""}
            onChange={(e) =>
              updateScript("default_credentials", {
                ...script.default_credentials,
                username: e.target.value || null,
              })
            }
          />
          <Input
            placeholder="Password"
            value={script.default_credentials.password || ""}
            onChange={(e) =>
              updateScript("default_credentials", {
                ...script.default_credentials,
                password: e.target.value || null,
              })
            }
          />
          <Note
            script={script}
            setScript={setScript}
            setIsValid={setIsValid}
            setZodErrors={setZodErrors}
          />
        </form>
      </div>
      <div className="w-1/2 p-4 bg-background overflow-y-auto">
        <Alert
          className={cn("text-black", isValid ? "bg-green-100" : "bg-red-100")}
        >
          <AlertTitle>{isValid ? "Valid JSON" : "Invalid JSON"}</AlertTitle>
          <AlertDescription>
            {isValid
              ? "The current JSON is valid according to the schema."
              : "The current JSON does not match the required schema."}
          </AlertDescription>
          {zodErrors && (
            <div className="mt-2 space-y-1">
              {zodErrors.errors.map((error, index) => (
                <AlertDescription key={index} className="p-1 text-red-500">
                  {error.path.join(".")} - {error.message}
                </AlertDescription>
              ))}
            </div>
          )}
        </Alert>
        <div className="relative">
          <Button
            className="absolute right-2 top-2"
            size="icon"
            variant="outline"
            onClick={() => {
              navigator.clipboard.writeText(JSON.stringify(script, null, 2));
              setIsCopied(true);
              setTimeout(() => setIsCopied(false), 2000);
              toast.success("Copied metadata to clipboard");
            }}
          >
            {isCopied ? (
              <Check className="h-4 w-4" />
            ) : (
              <Clipboard className="h-4 w-4" />
            )}
          </Button>
          <pre className="mt-4 p-4 bg-secondary rounded shadow overflow-x-scroll">
            {JSON.stringify(script, null, 2)}
          </pre>
        </div>
      </div>
    </div>
  );
}
