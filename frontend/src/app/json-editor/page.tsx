"use client";

import type { z } from "zod";

import { CalendarIcon, Check, Clipboard, Download, LayoutGrid } from "lucide-react";
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
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { fetchCategories } from "@/lib/data";
import { cn } from "@/lib/utils";

import type { Script } from "./_schemas/schemas";

import InstallMethod from "./_components/install-method";
import { ScriptSchema } from "./_schemas/schemas";
import Categories from "./_components/categories";
import Note from "./_components/note";

const initialScript: Script = {
  name: "",
  slug: "",
  categories: [],
  date_created: "",
  interface_port: null,
  documentation: null,
  website: null,
  github: null,
  logo: null,
  description: "",
  install_methods: [],
  default_credentials: {
    username: null,
    password: null,
  },
  notes: [],
  platform: {
    desktop: false,
    mobile: false,
    web_extensions: false,
    hosting: false,
    ui_interface: false,
  } as any,
  deployment: {
    script: false,
    docker: false,
    docker_compose: false,
    helm: false,
    kubernetes: false,
    terraform: false,
    paths: {
      script: null,
      docker: null,
      docker_compose: null,
      helm: null,
      kubernetes: null,
      terraform: null,
    },
  } as any,
};

export default function JSONGenerator() {
  const [script, setScript] = useState<Script>(initialScript);
  const [isCopied, setIsCopied] = useState(false);
  const [isValid, setIsValid] = useState(false);
  const [categories, setCategories] = useState<Category[]>([]);
  const [zodErrors, setZodErrors] = useState<z.ZodError | null>(null);

  useEffect(() => {
    fetchCategories()
      .then(setCategories)
      .catch(error => console.error("Error fetching categories:", error));
  }, []);

  const updateScript = useCallback(<K extends keyof Script>(key: K, value: Script[K]) => {
    setScript((prev) => {
      const updated = { ...prev, [key]: value } as Script;

      const result = ScriptSchema.safeParse(updated);
      setIsValid(result.success);
      setZodErrors(result.success ? null : result.error);
      return updated;
    });
  }, []);


  const handleCopy = useCallback(() => {
    const jsonString = JSON.stringify(script, null, 2);

    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard
        .writeText(jsonString)
        .then(() => {
          setIsCopied(true);
          setTimeout(() => setIsCopied(false), 2000);
          toast.success("Copied metadata to clipboard");
        })
        .catch((err) => {
          console.error("Clipboard write failed, fallback:", err);

          const textArea = document.createElement("textarea");
          textArea.value = jsonString;
          textArea.style.position = "fixed";
          textArea.style.top = "0";
          textArea.style.left = "0";
          textArea.style.opacity = "0";
          document.body.appendChild(textArea);
          textArea.focus();
          textArea.select();

          try {
            const successful = document.execCommand("copy");
            if (successful) {
              toast.success("Copied metadata to clipboard");
              setIsCopied(true);
              setTimeout(() => setIsCopied(false), 2000);
            } else {
              toast.error("Unable to copy to clipboard");
            }
          } catch (err2) {
            toast.error("Clipboard copy failed");
            console.error("Fallback copy failed:", err2);
          }

          document.body.removeChild(textArea);
        });
    } else {
      const textArea = document.createElement("textarea");
      textArea.value = jsonString;
      textArea.style.position = "fixed";
      textArea.style.top = "0";
      textArea.style.left = "0";
      textArea.style.opacity = "0";
      document.body.appendChild(textArea);
      textArea.focus();
      textArea.select();

      try {
        const successful = document.execCommand("copy");
        if (successful) {
          toast.success("Copied metadata to clipboard");
          setIsCopied(true);
          setTimeout(() => setIsCopied(false), 2000);
        } else {
          toast.error("Unable to copy to clipboard");
        }
      } catch (err) {
        toast.error("Clipboard copy failed");
        console.error("Fallback copy failed:", err);
      }

      document.body.removeChild(textArea);
    }
  }, [script]);


  const handleDownload = useCallback(() => {
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

  const formattedDate = useMemo(() => {
    if (!script.date_created) return undefined;
    try {
      const d = new Date(script.date_created);
      if (Number.isNaN(d.getTime())) return undefined;
      return format(d, "PPP");
    } catch {
      return undefined;
    }
  }, [script.date_created]);

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
            {zodErrors.errors.map((error, index) => (
              <AlertDescription key={index} className="p-1 text-red-500">
                {error.path.join(".")}
                {" "}
                -
                {error.message}
              </AlertDescription>
            ))}
          </div>
        )}
      </Alert>
    ),
    [isValid, zodErrors],
  );

  const normalizeUrl = useCallback((value: string) => {
    const trimmed = value?.trim();
    return trimmed ? trimmed : null;
  }, []);

  const clampPort = useCallback((val: number | null) => {
    if (val === null) return null;
    if (!Number.isFinite(val)) return null;
    const n = Math.round(val);
    if (n < 1 || n > 65535) return null;
    return n;
  }, []);

  const manifestFileExamples: Record<string, string> = {
    script: "script.sh",
    docker: "Dockerfile",
    docker_compose: "docker-compose.yaml",
    helm: "helm.yaml",
    kubernetes: "k8s-deployment.yaml",
    terraform: "main.tf",
  };

  const buildExamplePath = (fileName: string) =>
    `/public/manifest/${script.slug || "app-name"}/${fileName}`;

  const toggleDeployment = (key: string, checked: boolean) => {
    const prevDep: any = (script as any).deployment || {};
    const prevPaths = prevDep.paths || {};
    const nextDep = {
      ...prevDep,
      [key]: checked,
      paths: {
        ...prevPaths,
        [key]: checked ? buildExamplePath(manifestFileExamples[key]) : null,
      },
    };
    updateScript("deployment" as keyof Script, nextDep as unknown as Script[keyof Script]);
  };

  return (
    <div className="flex min-h-[calc(100vh-4rem)] mt-20">
      <div className="w-1/2 p-4 overflow-y-auto">
        <h2 className="text-2xl font-bold mb-4">JSON Generator</h2>

        <form className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label>
                Name
                {" "}
                <span className="text-red-500">*</span>
              </Label>
              <Input placeholder="Example" value={script.name} onChange={e => updateScript("name", e.target.value)} />
            </div>
            <div>
              <Label>
                Slug
                {" "}
                <span className="text-red-500">*</span>
              </Label>
              <Input placeholder="example" value={script.slug} onChange={e => updateScript("slug", e.target.value)} />
            </div>
          </div>

          <div>
            <Label>Logo (optional)</Label>
            <Input
              placeholder="Full logo URL (leave blank to use default icon)"
              type="url"
              value={script.logo || ""}
              onChange={e => updateScript("logo", normalizeUrl(e.target.value))}
              onBlur={e => updateScript("logo", normalizeUrl(e.target.value))}
            />
          </div>

          <div>
            <Label>
              Description
              {" "}
              <span className="text-red-500">*</span>
            </Label>
            <Textarea
              placeholder="Example"
              value={script.description}
              onChange={e => updateScript("description", e.target.value)}
            />
          </div>

          <Categories script={script} setScript={setScript} categories={categories} />

          <div className="flex gap-2">
            <div className="flex flex-col gap-2 w-full">
              <Label>Date Created</Label>
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
                    selected={script.date_created ? new Date(script.date_created) : undefined}
                    onSelect={handleDateSelect}
                    initialFocus
                  />
                </PopoverContent>
              </Popover>
            </div>
          </div>

          {/* Interface Port */}
          <div>
            <Label>Interface Port</Label>
            <Input
              placeholder="e.g. 8080 (1 - 65535)"
              type="number"
              min={1}
              max={65535}
              value={script.interface_port ?? ""}
              onChange={e => {
                const v = e.target.value ? Number(e.target.value) : null;
                updateScript("interface_port", clampPort(v) as unknown as Script[keyof Script]);
              }}
            />
            <p className="text-sm text-muted-foreground mt-1">
              Optional — numeric port number (1–65535). Leave empty for no port.
            </p>
          </div>

          {/* URL fields */}
          <div className="space-y-2">
            <div>
              <Label>Website URL</Label>
              <Input
                placeholder="https://example.com"
                type="url"
                value={script.website || ""}
                onChange={e => updateScript("website", e.target.value || null)}
                onBlur={e => updateScript("website", normalizeUrl(e.target.value))}
              />
            </div>

            <div>
              <Label>Documentation URL</Label>
              <Input
                placeholder="https://example.com/docs"
                type="url"
                value={script.documentation || ""}
                onChange={e => updateScript("documentation", e.target.value || null)}
                onBlur={e => updateScript("documentation", normalizeUrl(e.target.value))}
              />
            </div>

            <div>
              <Label>Source Code URL</Label>
              <Input
                placeholder="https://github.com/your/repo"
                type="url"
                value={(script as any).github || ""}
                onChange={e => updateScript("github" as keyof Script, e.target.value || null)}
                onBlur={e => updateScript("github" as keyof Script, normalizeUrl(e.target.value))}
              />
            </div>
          </div>

          <InstallMethod script={script} setScript={setScript} setIsValid={setIsValid} setZodErrors={setZodErrors} />

          <div className="flex items-start justify-between mb-3">
              <div>
                <h3 className="text-lg font-semibold">Deployment</h3>
                <p className="text-sm text-muted-foreground">Script / Docker / Docker Compose / Helm / Kubernetes / Terraform</p>
              </div>
            </div>

            <div className="space-y-3">
              {["script", "docker", "docker_compose", "helm", "kubernetes", "terraform"].map(key => {
                const labelMap: Record<string, string> = {
                  script: "Script",
                  docker: "Docker",
                  docker_compose: "Docker Compose",
                  helm: "Helm",
                  kubernetes: "Kubernetes",
                  terraform: "Terraform",
                };

                const isOn = Boolean((script as any).deployment?.[key]);
                // always compute path from current slug (fallback "app-name")
                const pathValue = buildExamplePath(manifestFileExamples[key]);


                return (
                  <div key={key} className="p-2 rounded border flex flex-col gap-2">
                    <div className="flex items-center justify-between">
                      <div className="font-medium">{labelMap[key]}</div>
                      <Switch checked={isOn} onCheckedChange={(v) => toggleDeployment(key, Boolean(v))} />
                    </div>

                    {isOn && (
                      <div className="space-y-1">
                        <Label>Manifest path (read-only)</Label>
                        <Input value={pathValue} readOnly disabled />
                        <p className="text-xs text-muted-foreground">
                          Please create the manifest under <code className="bg-muted px-1 rounded">/public/manifest/&lt;app-name&gt;/&lt;manifest-filename&gt;</code>.
                        </p>
                      </div>
                    )}  
                  </div>
                );
              })}
            </div>

          <h3 className="text-xl font-semibold">Default Credentials</h3>
          <Input
            placeholder="Username"
            value={script.default_credentials.username || ""}
            onChange={e =>
              updateScript("default_credentials", {
                ...script.default_credentials,
                username: e.target.value || null,
              })
            }
          />
          <Input
            placeholder="Password"
            value={script.default_credentials.password || ""}
            onChange={e =>
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
        {validationAlert}

        {/* Logo Preview */}
        <div className="mt-4 mb-4 flex items-center justify-center">
          <div className="flex flex-col items-center gap-2">
            <Label className="text-sm text-muted-foreground">Logo Preview</Label>
            {script.logo && script.logo.trim() !== "" ? (
              <img
                src={script.logo}
                alt="Logo preview"
                className="h-24 w-24 rounded-xl bg-gradient-to-br from-accent/40 to-accent/60 object-contain p-3 shadow-lg"
                onError={(e) => {
                  e.currentTarget.style.display = 'none';
                  e.currentTarget.nextElementSibling?.classList.remove('hidden');
                }}
              />
            ) : null}
            <div className={cn(
              "flex h-24 w-24 items-center justify-center rounded-xl bg-gradient-to-br from-accent/40 to-accent/60 shadow-lg",
              script.logo && script.logo.trim() !== "" && "hidden"
            )}>
              <LayoutGrid className="h-12 w-12 text-muted-foreground" />
            </div>
          </div>
        </div>

        <div className="relative">
          <div className="absolute right-2 top-2 flex gap-1">
            <Button size="icon" variant="outline" onClick={handleCopy}>
              {isCopied ? <Check className="h-4 w-4" /> : <Clipboard className="h-4 w-4" />}
            </Button>
            <Button size="icon" variant="outline" onClick={handleDownload}>
              <Download className="h-4 w-4" />
            </Button>
          </div>

          <pre className="mt-4 p-4 bg-secondary rounded shadow overflow-x-scroll">
            {JSON.stringify(script, null, 2)}
          </pre>
        </div>
      </div>
    </div>
  );
}
