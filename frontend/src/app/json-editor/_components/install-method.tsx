import React, { memo, useCallback, useEffect } from "react";
import { Script } from "../_schemas/schemas";
import { InstallMethodSchema, ScriptSchema } from "../_schemas/schemas";

/**
 * Accessible compact checkbox-like toggle used across the UI.
 * Accepts checked, onChange, children and supports keyboard toggling (space/enter).
 */
const ToggleCheckbox = ({ checked, onChange, children }: any) => {
  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === " " || e.key === "Enter") {
      e.preventDefault();
      onChange(!checked);
    }
  };

  return (
    <div className="inline-flex items-center gap-2 text-sm">
      <button
        type="button"
        role="checkbox"
        aria-checked={!!checked}
        tabIndex={0}
        onKeyDown={handleKeyDown}
        onClick={() => onChange(!checked)}
        className={
          "inline-flex h-5 w-5 flex-none items-center justify-center rounded border transition " +
          (checked
            ? "bg-blue-600 border-blue-600 shadow-sm"
            : "bg-white border-gray-300 hover:border-gray-400")
        }
        aria-label={typeof children === "string" ? children : undefined}
      >
        <svg
          className={`h-3 w-3 transform ${checked ? "scale-100" : "scale-75 opacity-0"}`}
          viewBox="0 0 24 24"
          fill="none"
          stroke="white"
          strokeWidth="3"
          strokeLinecap="round"
          strokeLinejoin="round"
          aria-hidden="true"
        >
          <polyline points="20 6 9 17 4 12" />
        </svg>
      </button>

      <span className="select-none">{children}</span>
    </div>
  );
};

/**
 * Default install method shape (deployment removed).
 */
export const defaultInstallMethod = {
  platform: {
    desktop: { linux: false, windows: false, macos: false },
    mobile: { android: false, ios: false },
    web_app: false,
    browser_extension: false,
    cli_only: false,
    hosting: { self_hosted: false, managed_cloud: false },
    ui: { cli: false, gui: false, web_ui: false, api: false, tui: false },
  },
} as const;

type InstallMethodProps = {
  script: Script;
  setScript: (value: Script | ((prevState: Script) => Script)) => void;
  setIsValid: (isValid: boolean) => void;
  setZodErrors: (zodErrors: any) => void;
};

function shallowCopy<T>(obj: T) {
  return JSON.parse(JSON.stringify(obj)) as T;
}

function InstallMethod({ script, setScript, setIsValid, setZodErrors }: InstallMethodProps) {
  // Ensure there is always one install method object present (safe fallback logging)
  useEffect(() => {
    if (!script.install_methods || script.install_methods.length === 0) {
      setScript((prev) => {
        const parsed = InstallMethodSchema.safeParse(defaultInstallMethod);
        if (!parsed.success) {
          // avoid calling .format() — log errors & message
          // eslint-disable-next-line no-console
          console.error("defaultInstallMethod validation failed:", parsed.error.errors, parsed.error.message);

          // fallback: insert raw default so UI can initialize, but surface zod errors
          const fallback = defaultInstallMethod as unknown as any;
          const updatedFallback = { ...prev, install_methods: [fallback] };
          const result = ScriptSchema.safeParse(updatedFallback);
          setIsValid(result.success);
          setZodErrors(parsed.error);
          return updatedFallback;
        }

        const updated = { ...prev, install_methods: [parsed.data] };
        const result = ScriptSchema.safeParse(updated);
        setIsValid(result.success);
        setZodErrors(result.success ? null : result.error);
        return updated;
      });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [script.install_methods?.length]);

  const updatePlatform = useCallback(
    (path: string[], value: any) => {
      setScript((prev) => {
        const methods = shallowCopy(prev.install_methods);
        if (!methods || methods.length === 0) {
          const parsed = InstallMethodSchema.parse(defaultInstallMethod);
          methods.splice(0, 0, parsed);
        }
        let cur: any = methods[0].platform;
        for (let i = 0; i < path.length - 1; i++) cur = cur[path[i]];
        cur[path[path.length - 1]] = value;

        const updated = { ...prev, install_methods: methods };
        const result = ScriptSchema.safeParse(updated);
        setIsValid(result.success);
        setZodErrors(result.success ? null : result.error);
        return updated;
      });
    },
    [setScript, setIsValid, setZodErrors],
  );

  // Toggle top-level platform keys (like web_app, browser_extension, cli_only)
  const togglePlatformKeys = useCallback(
    (keys: string[]) => {
      setScript((prev) => {
        const methods = shallowCopy(prev.install_methods);
        if (!methods || methods.length === 0) {
          const parsed = InstallMethodSchema.parse(defaultInstallMethod);
          methods.splice(0, 0, parsed);
        }
        const platform: any = methods[0].platform;

        const existingKeys = keys.filter((k) => Object.prototype.hasOwnProperty.call(platform, k));
        const allSelected = existingKeys.every((k) => !!platform[k]);
        const target = !allSelected;
        for (const k of existingKeys) platform[k] = target;

        const updated = { ...prev, install_methods: methods };
        const result = ScriptSchema.safeParse(updated);
        setIsValid(result.success);
        setZodErrors(result.success ? null : result.error);
        return updated;
      });
    },
    [setScript, setIsValid, setZodErrors],
  );

  // Toggle group for nested objects (desktop, mobile, hosting, ui)
  const toggleGroup = useCallback(
    (groupPath: string[]) => {
      setScript((prev) => {
        const methods = shallowCopy(prev.install_methods);
        if (!methods || methods.length === 0) {
          const parsed = InstallMethodSchema.parse(defaultInstallMethod);
          methods.splice(0, 0, parsed);
        }
        let group: any = methods[0].platform;
        for (let i = 0; i < groupPath.length; i++) group = group[groupPath[i]];

        if (group && typeof group === "object") {
          const values = Object.values(group);
          const allSelected = values.every(Boolean);
          const target = !allSelected;
          for (const k of Object.keys(group)) group[k] = target;
        }

        const updated = { ...prev, install_methods: methods };
        const result = ScriptSchema.safeParse(updated);
        setIsValid(result.success);
        setZodErrors(result.success ? null : result.error);
        return updated;
      });
    },
    [setScript, setIsValid, setZodErrors],
  );

  const method = script.install_methods && script.install_methods.length > 0 ? script.install_methods[0] : null;

  return (
    <div>
      <div className="flex flex-col gap-4">
        {!method && (
          <div className="mt-2 p-2 text-sm text-gray-600">Initializing install method...</div>
        )}

        {method && (
          <>
            {/* GROUP: Platforms (Desktop / Mobile / Web & Extensions) */}
            <div>
              {/* Desktop */}
              <div className="pt-3">
                <div className="flex items-center justify-between">
                  <div>
                    <div className="font-medium">Desktop</div>
                    <div className="text-xs text-gray-500">Select desktop targets</div>
                  </div>
                  <div>
                    <button
                      type="button"
                      onClick={() => toggleGroup(["desktop"])}
                      className="text-xs text-blue-600 hover:underline"
                    >
                      Select all / Clear
                    </button>
                  </div>
                </div>

                <div className="mt-3 flex gap-4 flex-wrap">
                  <ToggleCheckbox
                    checked={!!method.platform?.desktop?.linux}
                    onChange={(v: boolean) => updatePlatform(["desktop", "linux"], v)}
                  >
                    Linux
                  </ToggleCheckbox>

                  <ToggleCheckbox
                    checked={!!method.platform?.desktop?.windows}
                    onChange={(v: boolean) => updatePlatform(["desktop", "windows"], v)}
                  >
                    Windows
                  </ToggleCheckbox>

                  <ToggleCheckbox
                    checked={!!method.platform?.desktop?.macos}
                    onChange={(v: boolean) => updatePlatform(["desktop", "macos"], v)}
                  >
                    macOS
                  </ToggleCheckbox>
                </div>
              </div>

              {/* Mobile */}
              <div className="pt-3">
                <div className="flex items-center justify-between">
                  <div>
                    <div className="font-medium">Mobile</div>
                    <div className="text-xs text-gray-500">Native mobile platforms</div>
                  </div>
                  <div>
                    <button
                      type="button"
                      onClick={() => toggleGroup(["mobile"])}
                      className="text-xs text-blue-600 hover:underline"
                    >
                      Select all / Clear
                    </button>
                  </div>
                </div>

                <div className="mt-3 flex gap-4">
                  <ToggleCheckbox
                    checked={!!method.platform?.mobile?.android}
                    onChange={(v: boolean) => updatePlatform(["mobile", "android"], v)}
                  >
                    Android
                  </ToggleCheckbox>

                  <ToggleCheckbox
                    checked={!!method.platform?.mobile?.ios}
                    onChange={(v: boolean) => updatePlatform(["mobile", "ios"], v)}
                  >
                    iOS
                  </ToggleCheckbox>
                </div>
              </div>

              {/* Web & Extensions */}
              <div className="pt-3">
                <div className="flex items-center justify-between">
                  <div>
                    <div className="font-medium">Web & Extensions</div>
                    <div className="text-xs text-gray-500">Web app, browser extension, CLI-only</div>
                  </div>
                  <div>
                    <button
                      type="button"
                      onClick={() => togglePlatformKeys(["web_app", "browser_extension", "cli_only"])}
                      className="text-xs text-blue-600 hover:underline"
                    >
                      Select all / Clear
                    </button>
                  </div>
                </div>

                <div className="mt-3 flex gap-4 flex-wrap">
                  <ToggleCheckbox
                    checked={!!method.platform?.web_app}
                    onChange={(v: boolean) => updatePlatform(["web_app"], v)}
                  >
                    Web App
                  </ToggleCheckbox>

                  <ToggleCheckbox
                    checked={!!method.platform?.browser_extension}
                    onChange={(v: boolean) => updatePlatform(["browser_extension"], v)}
                  >
                    Browser Extension
                  </ToggleCheckbox>

                  <ToggleCheckbox
                    checked={!!method.platform?.cli_only}
                    onChange={(v: boolean) => updatePlatform(["cli_only"], v)}
                  >
                    CLI Only
                  </ToggleCheckbox>
                </div>
              </div>
            </div>

            {/* GROUP: Hosting */}
            <div className="pt-3">
              <div className="flex items-center justify-between">
                <div>
                  <div className="font-medium text-base">Hosting</div>
                  <div className="text-xs text-gray-500">Self-hosted / Managed Cloud</div>
                </div>

                <div>
                  <button
                    type="button"
                    onClick={() => toggleGroup(["hosting"])}
                    className="text-xs text-blue-600 hover:underline"
                  >
                    Select all / Clear
                  </button>
                </div>
              </div>

              <div className="mt-3 flex gap-4 flex-wrap">
                <ToggleCheckbox
                  checked={!!method.platform?.hosting?.self_hosted}
                  onChange={(v: boolean) => updatePlatform(["hosting", "self_hosted"], v)}
                >
                  Self-hosted
                </ToggleCheckbox>

                <ToggleCheckbox
                  checked={!!method.platform?.hosting?.managed_cloud}
                  onChange={(v: boolean) => updatePlatform(["hosting", "managed_cloud"], v)}
                >
                  Managed Cloud
                </ToggleCheckbox>
              </div>
            </div>

            {/* GROUP: UI / Interface */}
            <div className="pt-3">
              <div className="flex items-center justify-between">
                <div>
                  <div className="font-medium text-base">UI / Interface</div>
                  <div className="text-xs text-gray-500">CLI, GUI, Web UI, API, or TUI</div>
                </div>

                <div>
                  <button
                    type="button"
                    onClick={() => toggleGroup(["ui"])}
                    className="text-xs text-blue-600 hover:underline"
                  >
                    Select all / Clear
                  </button>
                </div>
              </div>

              <div className="mt-3 flex gap-4 flex-wrap">
                <ToggleCheckbox
                  checked={!!method.platform?.ui?.cli}
                  onChange={(v: boolean) => updatePlatform(["ui", "cli"], v)}
                >
                  CLI
                </ToggleCheckbox>

                <ToggleCheckbox
                  checked={!!method.platform?.ui?.gui}
                  onChange={(v: boolean) => updatePlatform(["ui", "gui"], v)}
                >
                  GUI
                </ToggleCheckbox>

                <ToggleCheckbox
                  checked={!!method.platform?.ui?.web_ui}
                  onChange={(v: boolean) => updatePlatform(["ui", "web_ui"], v)}
                >
                  Web UI
                </ToggleCheckbox>

                <ToggleCheckbox
                  checked={!!method.platform?.ui?.api}
                  onChange={(v: boolean) => updatePlatform(["ui", "api"], v)}
                >
                  API
                </ToggleCheckbox>

                <ToggleCheckbox
                  checked={!!method.platform?.ui?.tui}
                  onChange={(v: boolean) => updatePlatform(["ui", "tui"], v)}
                >
                  TUI
                </ToggleCheckbox>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

export default memo(InstallMethod);
