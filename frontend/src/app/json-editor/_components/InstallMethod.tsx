import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { PlusCircle, Trash2 } from "lucide-react";
import { Input } from "@/components/ui/input";
import { z } from "zod";
import { InstallMethodSchema, ScriptSchema } from "../_schemas/schemas";

type Script = z.infer<typeof ScriptSchema>;

type InstallMethodProps = {
  script: Script;
  setScript: (value: Script | ((prevState: Script) => Script)) => void;
  setIsValid: (isValid: boolean) => void;
  setZodErrors: (zodErrors: z.ZodError | null) => void;
};

export default function InstallMethod({
  script,
  setScript,
  setIsValid,
  setZodErrors,
}: InstallMethodProps) {
  const addInstallMethod = () => {
    setScript((prev) => {
      const method = InstallMethodSchema.parse({
        type: "default",
        script: `/${prev.type}/${prev.slug}.sh`,
        resources: {
          cpu: null,
          ram: null,
          hdd: null,
          os: null,
          version: null,
        },
      });
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
      if (!result.success) {
        setZodErrors(result.error);
      } else {
        setZodErrors(null);
      }
      return updated;
    });
  };

  const removeInstallMethod = (index: number) => {
    setScript((prev) => ({
      ...prev,
      install_methods: prev.install_methods.filter((_, i) => i !== index),
    }));
  };

  return (
    <>
      <h3 className="text-xl font-semibold">Install Methods</h3>
      {script.install_methods.map((method, index) => (
        <div key={index} className="space-y-2 border p-4 rounded">
          <Select
            value={method.type}
            onValueChange={(value) => updateInstallMethod(index, "type", value)}
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
              onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
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
              onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
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
              onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
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
              onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
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
              onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
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
    </>
  );
}
