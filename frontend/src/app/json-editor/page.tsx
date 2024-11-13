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
import { CalendarIcon, Check, Clipboard, PlusCircle, Trash2 } from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { z } from "zod";
import { format } from "date-fns";
import { Label } from "@/components/ui/label";
import { AlertColors } from "@/config/siteConfig";
import { ScriptSchema } from "./_schemas/schemas";

type Script = z.infer<typeof ScriptSchema>;

export default function JSONGenerator() {
  const [script, setScript] = useState<Script>({
    name: "",
    slug: "",
    categories: [],
    date_created: "",
    type: "vm",
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
      return updated;
    });
  };

  const addInstallMethod = () => {
    setScript((prev) => {
      const method: {
        type: "default" | "alpine";
        script: string;
        resources: {
          cpu: number | null;
          ram: number | null;
          hdd: number | null;
          os: string | null;
          version: number | null;
        };
      } = {
        type: "default",
        script: `/${prev.type}/${prev.slug}.sh`,
        resources: {
          cpu: null,
          ram: null,
          hdd: null,
          os: null,
          version: null,
        },
      };
      return {
        ...prev,
        install_methods: [...prev.install_methods, method],
      };
    });
  };

  const updateInstallMethod = (
    index: number,
    key: keyof Script["install_methods"][number],
    value: Script["install_methods"][number][keyof Script["install_methods"][number]],
  ) => {
    setScript((prev) => {
      const updatedMethods = prev.install_methods.map((method, i) => {
        if (i === index) {
          const updatedMethod = { ...method, [key]: value };

          // Update script path if `type` of the install method changes
          if (key === "type") {
            updatedMethod.script =
              value === "alpine"
                ? `/${prev.type}/alpine-${prev.slug}.sh`
                : `/${prev.type}/${prev.slug}.sh`;
          }

          return updatedMethod;
        }
        return method;
      });

      const updated = {
        ...prev,
        install_methods: updatedMethods,
      };

      const result = ScriptSchema.safeParse(updated);
      setIsValid(result.success);
      return updated;
    });
  };

  const removeInstallMethod = (index: number) => {
    setScript((prev) => ({
      ...prev,
      install_methods: prev.install_methods.filter((_, i) => i !== index),
    }));
  };

  const addNote = () => {
    setScript((prev) => ({
      ...prev,
      notes: [...prev.notes, { text: "", type: "" }],
    }));
  };

  const updateNote = (
    index: number,
    key: keyof Script["notes"][number],
    value: string,
  ) => {
    setScript((prev) => {
      const updated = {
        ...prev,
        notes: prev.notes.map((note, i) =>
          i === index ? { ...note, [key]: value } : note,
        ),
      };
      const result = ScriptSchema.safeParse(updated);
      setIsValid(result.success);
      return updated;
    });
  };

  const removeNote = (index: number) => {
    setScript((prev) => ({
      ...prev,
      notes: prev.notes.filter((_, i) => i !== index),
    }));
  };

  const addCategory = (categoryId: number) => {
    setScript((prev) => ({
      ...prev,
      categories: [...new Set([...prev.categories, categoryId])],
    }));
  };

  const removeCategory = (categoryId: number) => {
    setScript((prev) => ({
      ...prev,
      categories: prev.categories.filter((id) => id !== categoryId),
    }));
  };

  return (
    <div className="flex h-screen mt-20">
      <div className="w-1/2 p-4 overflow-y-auto">
        <h2 className="text-2xl font-bold mb-4">JSON Generator</h2>
        <form className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <Input
              placeholder="Name"
              value={script.name}
              onChange={(e) => updateScript("name", e.target.value)}
            />
            <Input
              placeholder="Slug"
              value={script.slug}
              onChange={(e) => updateScript("slug", e.target.value)}
            />
          </div>
          <Input
            placeholder="Logo URL"
            value={script.logo || ""}
            onChange={(e) => updateScript("logo", e.target.value || null)}
          />
          <Textarea
            placeholder="Description"
            value={script.description}
            onChange={(e) => updateScript("description", e.target.value)}
          />
          <div>
            <Select onValueChange={(value) => addCategory(Number(value))}>
              <SelectTrigger>
                <SelectValue placeholder="Select a category" />
              </SelectTrigger>
              <SelectContent>
                {categories.map((category) => (
                  <SelectItem key={category.id} value={category.id.toString()}>
                    {category.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <div
              className={cn(
                "flex flex-wrap gap-2",
                script.categories.length !== 0 && "mt-2",
              )}
            >
              {script.categories.map((categoryId) => {
                const category = categories.find((c) => c.id === categoryId);
                return category ? (
                  <span
                    key={categoryId}
                    className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
                  >
                    {category.name}
                    <button
                      type="button"
                      className="ml-1 inline-flex text-blue-400 hover:text-blue-600"
                      onClick={() => removeCategory(categoryId)}
                    >
                      <span className="sr-only">Remove</span>
                      <svg
                        className="h-3 w-3"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                        xmlns="http://www.w3.org/2000/svg"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M6 18L18 6M6 6l12 12"
                        />
                      </svg>
                    </button>
                  </span>
                ) : null;
              })}
            </div>
          </div>
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
                  <SelectItem value="vm">Virtual Machine</SelectItem>
                  <SelectItem value="ct">LXC Container</SelectItem>
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
          <h3 className="text-xl font-semibold">Install Methods</h3>
          {script.install_methods.map((method, index) => (
            <div key={index} className="space-y-2 border p-4 rounded">
              <Select
                value={method.type}
                onValueChange={(value) =>
                  updateInstallMethod(index, "type", value)
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="Type" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="default">Default</SelectItem>
                  <SelectItem value="alpine">Alpine</SelectItem>
                </SelectContent>
              </Select>
              <div className="flex gap-2">
                <Input
                  placeholder="CPU in Cores"
                  type="number"
                  value={method.resources.cpu || ""}
                  onChange={(e) =>
                    updateInstallMethod(index, "resources", {
                      ...method.resources,
                      cpu: e.target.value ? Number(e.target.value) : null,
                    })
                  }
                />
                <Input
                  placeholder="RAM in MB"
                  type="number"
                  value={method.resources.ram || ""}
                  onChange={(e) =>
                    updateInstallMethod(index, "resources", {
                      ...method.resources,
                      ram: e.target.value ? Number(e.target.value) : null,
                    })
                  }
                />
                <Input
                  placeholder="HDD in GB"
                  type="number"
                  value={method.resources.hdd || ""}
                  onChange={(e) =>
                    updateInstallMethod(index, "resources", {
                      ...method.resources,
                      hdd: e.target.value ? Number(e.target.value) : null,
                    })
                  }
                />
              </div>
              <div className="flex gap-2">
                <Input
                  placeholder="OS"
                  value={method.resources.os || ""}
                  onChange={(e) =>
                    updateInstallMethod(index, "resources", {
                      ...method.resources,
                      os: e.target.value || null,
                    })
                  }
                />
                <Input
                  placeholder="Version"
                  type="number"
                  value={method.resources.version || ""}
                  onChange={(e) =>
                    updateInstallMethod(index, "resources", {
                      ...method.resources,
                      version: e.target.value ? Number(e.target.value) : null,
                    })
                  }
                />
              </div>
              <Button
                variant="destructive"
                size={"sm"}
                type="button"
                onClick={() => removeInstallMethod(index)}
              >
                <Trash2 className="mr-2 h-4 w-4" /> Remove Install Method
              </Button>
            </div>
          ))}
          <Button
            type="button"
            size={"sm"}
            disabled={script.install_methods.length >= 2}
            onClick={addInstallMethod}
          >
            <PlusCircle className="mr-2 h-4 w-4" /> Add Install Method
          </Button>
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
          <h3 className="text-xl font-semibold">Notes</h3>
          {script.notes.map((note, index) => (
            <div key={index} className="space-y-2 border p-4 rounded">
              <Input
                placeholder="Note Text"
                value={note.text}
                onChange={(e) => updateNote(index, "text", e.target.value)}
              />
              <Select
                value={note.type}
                onValueChange={(value: string) =>
                  updateNote(index, "type", value)
                }
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
