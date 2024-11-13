"use client";

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
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
import { PlusCircle, Trash2 } from "lucide-react";
import { useEffect, useState } from "react";
import { z } from "zod";

const scriptSchema = z.object({
  name: z.string().min(1),
  slug: z.string().min(1),
  categories: z.array(z.number()),
  date_created: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  type: z.enum(["vm", "ct", "misc"]),
  updateable: z.boolean(),
  privileged: z.boolean(),
  interface_port: z.number().nullable(),
  documentation: z.string().nullable(),
  website: z.string().url().nullable(),
  logo: z.string().url().nullable(),
  description: z.string().min(1),
  install_methods: z.array(
    z.object({
      type: z.enum(["default", "alpine"]),
      script: z.string().min(1),
      resources: z.object({
        cpu: z.number().nullable(),
        ram: z.number().nullable(),
        hdd: z.number().nullable(),
        os: z.string().nullable(),
        version: z.number().nullable(),
      }),
    }),
  ),
  default_credentials: z.object({
    username: z.string().nullable(),
    password: z.string().nullable(),
  }),
  notes: z.array(
    z.object({
      text: z.string().min(1),
      type: z.string().min(1),
    }),
  ),
});

type Script = z.infer<typeof scriptSchema>;

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
    install_methods: [
      {
        type: "default",
        script: "",
        resources: {
          cpu: null,
          ram: null,
          hdd: null,
          os: null,
          version: null,
        },
      },
    ],
    default_credentials: {
      username: null,
      password: null,
    },
    notes: [
      {
        text: "",
        type: "",
      },
    ],
  });

  const [isValid, setIsValid] = useState(false);
  const [categories, setCategories] = useState<Category[]>([]);

  useEffect(() => {
    fetchCategories()
      .then((data: Category[]) => {
        setCategories(data);
      })
      .catch((error) => console.error("Error fetching categories:", error));
  }, []);

  const updateScript = (key: keyof Script, value: Script[keyof Script]) => {
    setScript((prev) => {
      const updated = { ...prev, [key]: value };
      const result = scriptSchema.safeParse(updated);
      setIsValid(result.success);
      return updated;
    });
  };

  const addInstallMethod = () => {
    setScript((prev) => ({
      ...prev,
      install_methods: [
        ...prev.install_methods,
        {
          type: "default",
          script: "",
          resources: {
            cpu: null,
            ram: null,
            hdd: null,
            os: null,
            version: null,
          },
        },
      ],
    }));
  };

  const updateInstallMethod = (
    index: number,
    key: keyof Script["install_methods"][number],
    value: Script["install_methods"][number][keyof Script["install_methods"][number]],
  ) => {
    setScript((prev) => {
      const updated = {
        ...prev,
        install_methods: prev.install_methods.map((method, i) =>
          i === index ? { ...method, [key]: value } : method,
        ),
      };
      const result = scriptSchema.safeParse(updated);
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
      const result = scriptSchema.safeParse(updated);
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
    <div className="flex h-screen">
      <div className="w-1/2 p-4 overflow-y-auto">
        <h2 className="text-2xl font-bold mb-4">JSON Generator</h2>
        <form className="space-y-4">
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
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Categories
            </label>
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
            <div className="mt-2 flex flex-wrap gap-2">
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
          <Input
            placeholder="Date Created (YYYY-MM-DD)"
            value={script.date_created}
            onChange={(e) => updateScript("date_created", e.target.value)}
          />
          <Select
            value={script.type}
            onValueChange={(value) => updateScript("type", value)}
          >
            <SelectTrigger>
              <SelectValue placeholder="Type" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="vm">VM</SelectItem>
              <SelectItem value="ct">CT</SelectItem>
              <SelectItem value="misc">Misc</SelectItem>
            </SelectContent>
          </Select>
          <div className="flex items-center space-x-2">
            <Switch
              checked={script.updateable}
              onCheckedChange={(checked) => updateScript("updateable", checked)}
            />
            <label>Updateable</label>
          </div>
          <div className="flex items-center space-x-2">
            <Switch
              checked={script.privileged}
              onCheckedChange={(checked) => updateScript("privileged", checked)}
            />
            <label>Privileged</label>
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
          <Input
            placeholder="Documentation URL"
            value={script.documentation || ""}
            onChange={(e) =>
              updateScript("documentation", e.target.value || null)
            }
          />
          <Input
            placeholder="Website URL"
            value={script.website || ""}
            onChange={(e) => updateScript("website", e.target.value || null)}
          />
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
              <Textarea
                placeholder="Script"
                value={method.script}
                onChange={(e) =>
                  updateInstallMethod(index, "script", e.target.value)
                }
              />
              <Input
                placeholder="CPU"
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
                placeholder="RAM"
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
                placeholder="HDD"
                type="number"
                value={method.resources.hdd || ""}
                onChange={(e) =>
                  updateInstallMethod(index, "resources", {
                    ...method.resources,
                    hdd: e.target.value ? Number(e.target.value) : null,
                  })
                }
              />
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
              <Button
                variant="destructive"
                onClick={() => removeInstallMethod(index)}
              >
                <Trash2 className="mr-2 h-4 w-4" /> Remove Install Method
              </Button>
            </div>
          ))}
          <Button onClick={addInstallMethod}>
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
              <Input
                placeholder="Note Type"
                value={note.type}
                onChange={(e) => updateNote(index, "type", e.target.value)}
              />
              <Button variant="destructive" onClick={() => removeNote(index)}>
                <Trash2 className="mr-2 h-4 w-4" /> Remove Note
              </Button>
            </div>
          ))}
          <Button onClick={addNote}>
            <PlusCircle className="mr-2 h-4 w-4" /> Add Note
          </Button>
        </form>
      </div>
      <div className="w-1/2 p-4 bg-gray-100 overflow-y-auto">
        <Alert className={isValid ? "bg-green-100" : "bg-red-100"}>
          <AlertTitle>{isValid ? "Valid JSON" : "Invalid JSON"}</AlertTitle>
          <AlertDescription>
            {isValid
              ? "The current JSON is valid according to the schema."
              : "The current JSON does not match the required schema."}
          </AlertDescription>
        </Alert>
        <pre className="mt-4 p-4 bg-white rounded shadow">
          {JSON.stringify(script, null, 2)}
        </pre>
      </div>
    </div>
  );
}
