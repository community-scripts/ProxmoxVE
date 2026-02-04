"use client";

import type { z } from "zod";

import { CalendarIcon, Check, Clipboard, Download } from "lucide-react";
import { useCallback, useEffect, useMemo, useState } from "react";
import { format } from "date-fns";
import { toast } from "sonner";

import type { Category } from "@/lib/types";

import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Calendar } from "@/components/ui/calendar";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { fetchCategories } from "@/lib/data";
import { cn } from "@/lib/utils";

import type { Script } from "./_schemas/schemas";

import InstallMethod from "./_components/install-method";
import { ScriptSchema } from "./_schemas/schemas";
import Categories from "./_components/categories";
import Note from "./_components/note";

import { nord } from "react-syntax-highlighter/dist/esm/styles/hljs";
import SyntaxHighlighter from "react-syntax-highlighter";
import { ScriptItem } from "../scripts/_components/script-item";

const initialScript: Script = {
  name: "",
  slug: "",
  categories: [],
  date_created: format(new Date(), "yyyy-MM-dd"),
  type: "ct",
  updateable: false,
  privileged: false,
  interface_port: null,
  documentation: null,
  config_path: "",
  website: null,
  logo: null,
  description: "",
  disable: undefined,
  disable_description: undefined,
  install_methods: [],
  default_credentials: {
    username: null,
    password: null,
  },
  notes: [],
};

export default function JSONGenerator() {
  const [script, setScript] = useState<Script>(initialScript);
  const [isCopied, setIsCopied] = useState(false);
  const [isValid, setIsValid] = useState(false);
  const [categories, setCategories] = useState<Category[]>([]);
  const [currentTab, setCurrentTab] = useState<"json" | "preview">("json");
  const [zodErrors, setZodErrors] = useState<z.ZodError | null>(null);

  useEffect(() => {
    fetchCategories()
      .then(setCategories)
      .catch((error) => console.error("Error fetching categories:", error));
  }, []);

  useEffect(() => {
    if (!isValid && currentTab === "preview") {
      setCurrentTab("json");
      toast.error("Switched to JSON tab due to invalid configuration.");
    }
  }, [isValid, currentTab]);

  const updateScript = useCallback((key: keyof Script, value: Script[keyof Script]) => {
    setScript((prev) => {
      const updated = { ...prev, [key]: value };

      if (updated.slug && updated.type) {
        updated.install_methods = updated.install_methods.map((method) => {
          let scriptPath = "";

          if (updated.type === "pve") {
            scriptPath = `tools/pve/${updated.slug}.sh`;
          } else if (updated.type === "addon") {
            scriptPath = `tools/addon/${updated.slug}.sh`;
          } else if (method.type === "alpine") {
            scriptPath = `${updated.type}/alpine-${updated.slug}.sh`;
          } else {
            scriptPath = `${updated.type}/${updated.slug}.sh`;
          }

          return {
            ...method,
            script: scriptPath,
          };
        });
      }

      const result = ScriptSchema.safeParse(updated);
      setIsValid(result.success);
      setZodErrors(result.success ? null : result.error);
      return updated;
    });
  }, []);

  const handleCopy = useCallback(() => {
    if (!isValid) toast.warning("JSON schema is invalid. Copying anyway.");
    navigator.clipboard.writeText(JSON.stringify(script, null, 2));
    setIsCopied(true);
    setTimeout(() => setIsCopied(false), 2000);
    if (isValid) toast.success("Copied metadata to clipboard");
  }, [script]);

  const handleDownload = useCallback(() => {
    if (isValid === false) {
      toast.error("Cannot download invalid JSON");
      return;
    }
    const jsonString = JSON.stringify(script, null, 2);
    const blob = new Blob([jsonString], { type: "application/json" });
    const url = URL.createObjectURL(blob);

    const a = document.createElement("a");
    a.href = url;
    a.download = `${script.slug || "script"}.json`;
    document.body.appendChild(a);
    a.click();

    URL.revokeObjectURL(url);
    document.body.removeChild(a);
  }, [script]);

  const handleDateSelect = useCallback(
    (date: Date | undefined) => {
      updateScript("date_created", format(date || new Date(), "yyyy-MM-dd"));
    },
    [updateScript],
  );

  const formattedDate = useMemo(
    () => (script.date_created ? format(script.date_created, "PPP") : undefined),
    [script.date_created],
  );

  const validationAlert = useMemo(
    () => (
      <Alert className={cn("text-black", isValid ? "bg-green-100" : "bg-red-100")}>
        <AlertTitle>{isValid ? "Valid JSON" : "Invalid JSON"}</AlertTitle>
        <AlertDescription>
          {isValid
            ? "The current JSON is valid according to the schema."
            : "The current JSON does not match the required schema."}
        </AlertDescription>
        {zodErrors && (
          <div className="mt-2 space-y-1">
            {zodErrors.issues.map((error, index) => (
              <AlertDescription key={index} className="p-1 text-red-500">
                {error.path.join(".")} -{error.message}
              </AlertDescription>
            ))}
          </div>
        )}
      </Alert>
    ),
    [isValid, zodErrors],
  );

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
              <Input placeholder="Example" value={script.name} onChange={(e) => updateScript("name", e.target.value)} />
            </div>
            <div>
              <Label>
                Slug <span className="text-red-500">*</span>
              </Label>
              <Input placeholder="example" value={script.slug} onChange={(e) => updateScript("slug", e.target.value)} />
            </div>
          </div>
          <div>
            <Label>
              Logo
            </Label>
            <Input
              placeholder="Full logo URL"
              value={script.logo || ""}
              onChange={(e) => updateScript("logo", e.target.value || null)}
            />
          </div>
          <div>
            <Label>Config Path</Label>
            <Input
              placeholder="Path to config file"
              value={script.config_path || ""}
              onChange={(e) => updateScript("config_path", e.target.value || "")}
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
          <Categories script={script} setScript={setScript} categories={categories} />
          <div className="flex gap-2">
            <div className="flex flex-col gap-2 w-full">
              <Label>
                Date Created <span className="text-red-500">*</span>
              </Label>
              <Popover>
                <PopoverTrigger asChild className="flex-1">
                  <Button
                    variant="outline"
                    className={cn("pl-3 text-left font-normal w-full", !script.date_created && "text-muted-foreground")}
                  >
                    {formattedDate || <span>Pick a date</span>}
                    <CalendarIcon className="ml-auto h-4 w-4 opacity-50" />
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0" align="start">
                  <Calendar
                    mode="single"
                    selected={new Date(script.date_created)}
                    onSelect={handleDateSelect}
                    autoFocus
                  />
                </PopoverContent>
              </Popover>
            </div>
            <div className="flex flex-col gap-2 w-full">
              <Label>Type</Label>
              <Select value={script.type} onValueChange={(value) => updateScript("type", value)}>
                <SelectTrigger className="flex-1">
                  <SelectValue placeholder="Type" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ct">LXC Container</SelectItem>
                  <SelectItem value="vm">Virtual Machine</SelectItem>
                  <SelectItem value="pve">PVE-Tool</SelectItem>
                  <SelectItem value="addon">Add-On</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="w-full flex gap-5">
            <div className="flex items-center space-x-2">
              <Switch checked={script.updateable} onCheckedChange={(checked) => updateScript("updateable", checked)} />
              <label>Updateable</label>
            </div>
            <div className="flex items-center space-x-2">
              <Switch checked={script.privileged} onCheckedChange={(checked) => updateScript("privileged", checked)} />
              <label>Privileged</label>
            </div>
            <div className="flex items-center space-x-2">
              <Switch
                checked={script.disable || false}
                onCheckedChange={(checked) => updateScript("disable", checked)}
              />
              <label>Disabled</label>
            </div>
          </div>
          {script.disable && (
            <div>
              <Label>
                Disable Description <span className="text-red-500">*</span>
              </Label>
              <Textarea
                placeholder="Explain why this script is disabled..."
                value={script.disable_description || ""}
                onChange={(e) => updateScript("disable_description", e.target.value)}
              />
            </div>
          )}
          <Input
            placeholder="Interface Port"
            type="number"
            value={script.interface_port || ""}
            onChange={(e) => updateScript("interface_port", e.target.value ? Number(e.target.value) : null)}
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
              onChange={(e) => updateScript("documentation", e.target.value || null)}
            />
          </div>
          <InstallMethod script={script} setScript={setScript} setIsValid={setIsValid} setZodErrors={setZodErrors} />
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
          <Note script={script} setScript={setScript} setIsValid={setIsValid} setZodErrors={setZodErrors} />
        </form>
      </div>
      <div className="w-1/2 p-4 bg-background overflow-y-auto">
        <Tabs
          defaultValue="json"
          className="w-full"
          onValueChange={(value) => setCurrentTab(value as "json" | "preview")}
          value={currentTab}
        >
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="json">JSON</TabsTrigger>
            <TabsTrigger disabled={!isValid} value="preview">Preview</TabsTrigger>
          </TabsList>
          <TabsContent value="json" className="h-full w-full">
            {validationAlert}
            <div className="relative">
              <div className="absolute right-2 top-2 flex gap-1">
                <Button size="icon" variant="outline" onClick={handleCopy}>
                  {isCopied ? <Check className="h-4 w-4" /> : <Clipboard className="h-4 w-4" />}
                </Button>
                <Button size="icon" variant="outline" onClick={handleDownload}>
                  <Download className="h-4 w-4" />
                </Button>
              </div>

              <SyntaxHighlighter
                language="json"
                style={nord}
                className="mt-4 p-4 bg-secondary rounded shadow overflow-x-scroll"
              >
                {JSON.stringify(script, null, 2)}
              </SyntaxHighlighter>
            </div>
          </TabsContent>
          <TabsContent value="preview" className="h-full w-full">
            <ScriptItem item={script} />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}
