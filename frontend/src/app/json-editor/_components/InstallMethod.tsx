import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { OperatingSystems } from "@/config/siteConfig";
import { PlusCircle, Trash2 } from "lucide-react";
import { memo, useCallback, useRef } from "react";
import { z } from "zod";
import { InstallMethodSchema, ScriptSchema, type Script } from "../_schemas/schemas";

type InstallMethodProps = {
  script: Script;
  setScript: (value: Script | ((prevState: Script) => Script)) => void;
  setIsValid: (isValid: boolean) => void;
  setZodErrors: (zodErrors: z.ZodError | null) => void;
};

function InstallMethod({
  script,
  setScript,
  setIsValid,
  setZodErrors,
}: InstallMethodProps) {
  const cpuRefs = useRef<(HTMLInputElement | null)[]>([]);
  const ramRefs = useRef<(HTMLInputElement | null)[]>([]);
  const hddRefs = useRef<(HTMLInputElement | null)[]>([]);

  const addInstallMethod = useCallback(() => {
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
  }, [setScript]);

  const updateInstallMethod = useCallback(
    (
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

              // Set OS to Alpine and reset version if type is alpine
              if (value === "alpine") {
                updatedMethod.resources.os = "Alpine";
                updatedMethod.resources.version = null;
              }
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
    },
    [setScript, setIsValid, setZodErrors],
  );

  const removeInstallMethod = useCallback(
    (index: number) => {
      setScript((prev) => ({
        ...prev,
        install_methods: prev.install_methods.filter((_, i) => i !== index),
      }));
    },
    [setScript],
  );

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
              ref={(el) => {
                cpuRefs.current[index] = el;
              }}
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
              ref={(el) => {
                ramRefs.current[index] = el;
              }}
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
              ref={(el) => {
                hddRefs.current[index] = el;
              }}
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
            <Select
              value={method.resources.os || undefined}
              onValueChange={(value) =>
                updateInstallMethod(index, "resources", {
                  ...method.resources,
                  os: value || null,
                  version: null, // Reset version when OS changes
                })
              }
              disabled={method.type === "alpine"}
            >
              <SelectTrigger>
                <SelectValue placeholder="OS" />
              </SelectTrigger>
              <SelectContent>
                {OperatingSystems.map((os) => (
                  <SelectItem key={os.name} value={os.name}>
                    {os.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Select
              value={method.resources.version || undefined}
              onValueChange={(value) =>
                updateInstallMethod(index, "resources", {
                  ...method.resources,
                  version: value || null,
                })
              }
              disabled={method.type === "alpine"}
            >
              <SelectTrigger>
                <SelectValue placeholder="Version" />
              </SelectTrigger>
              <SelectContent>
                {OperatingSystems.find(
                  (os) => os.name === method.resources.os,
                )?.versions.map((version) => (
                  <SelectItem key={version.slug} value={version.name}>
                    {version.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <Button
            variant="destructive"
            size="sm"
            type="button"
            onClick={() => removeInstallMethod(index)}
          >
            <Trash2 className="mr-2 h-4 w-4" /> Remove Install Method
          </Button>
        </div>
      ))}
      <Button
        type="button"
        size="sm"
        disabled={script.install_methods.length >= 2}
        onClick={addInstallMethod}
      >
        <PlusCircle className="mr-2 h-4 w-4" /> Add Install Method
      </Button>
    </>
  );
}

export default memo(InstallMethod);
