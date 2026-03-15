"use client";

import { Suspense, useEffect, useState, useMemo } from "react";
import { Loader2, Copy, Check, Terminal, Settings2, Server, Cpu, HardDrive, Network, Shield, Play } from "lucide-react";
import { useQueryState } from "nuqs";
import Image from "next/image";
import Link from "next/link";

import type { Category, Script } from "@/lib/types";
import { fetchCategories } from "@/lib/data";
import { Search } from "@/components/search";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Switch } from "@/components/ui/switch";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { basePath } from "@/config/site-config";
import {
  generateInstallCommand,
  validateConfig,
  getAvailableOS,
  getDefaultResources,
  getScriptTypeDisplay,
  type GeneratorConfig,
  DEFAULT_CONFIG,
} from "@/lib/generate-command";
import { cn } from "@/lib/utils";

function GeneratorContent() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [selectedScript, setSelectedScript] = useState<Script | null>(null);
  const [copied, setCopied] = useState(false);
  const [search, setSearch] = useQueryState("search");

  // Configuration state
  const [config, setConfig] = useState<GeneratorConfig>(DEFAULT_CONFIG);

  // Get all scripts from all categories
  const allScripts = useMemo(() => {
    if (!categories.length) return [];
    const scripts = categories.flatMap((category) => category.scripts || []);
    // Remove duplicates by slug
    const uniqueScripts = new Map<string, Script>();
    scripts.forEach((script) => {
      if (!uniqueScripts.has(script.slug)) {
        uniqueScripts.set(script.slug, script);
      }
    });
    return Array.from(uniqueScripts.values());
  }, [categories]);

  // Filter scripts by search
  const filteredScripts = useMemo(() => {
    if (!search) return allScripts;
    const searchLower = search.toLowerCase();
    return allScripts.filter(
      (script) =>
        script.name.toLowerCase().includes(searchLower) ||
        script.description.toLowerCase().includes(searchLower)
    );
  }, [allScripts, search]);

  // Available OS options for selected script
  const availableOS = useMemo(() => getAvailableOS(selectedScript), [selectedScript]);

  // Default resources for selected script
  const defaultResources = useMemo(() => getDefaultResources(selectedScript), [selectedScript]);

  // Load categories on mount
  useEffect(() => {
    fetchCategories()
      .then((data) => setCategories(data))
      .catch((error) => console.error(error));
  }, []);

  // Update config when script is selected
  useEffect(() => {
    if (selectedScript) {
      const defaults = getDefaultResources(selectedScript);
      const os = getAvailableOS(selectedScript)[0] || "";
      setConfig((prev) => ({
        ...prev,
        script: selectedScript,
        os,
        cpuCores: defaults.cpu || prev.cpuCores,
        ram: defaults.ram || prev.ram,
        diskSize: defaults.disk || prev.diskSize,
      }));
    }
  }, [selectedScript]);

  // Generate command
  const command = useMemo(() => generateInstallCommand(config), [config]);

  // Validation
  const validation = useMemo(() => validateConfig(config), [config]);

  // Copy command to clipboard
  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(command);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error("Failed to copy:", err);
    }
  };

  // Update config helper
  const updateConfig = <K extends keyof GeneratorConfig>(key: K, value: GeneratorConfig[K]) => {
    setConfig((prev) => ({ ...prev, [key]: value }));
  };

  return (
    <div className="container mx-auto px-4 py-8 mt-16">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-foreground mb-2">Unattended Script Generator</h1>
        <p className="text-muted-foreground">
          Generate installation commands for automated deployments with custom configurations
        </p>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Script Selection */}
        <Card className="border-rust/30">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-brass">
              <Server className="h-5 w-5" />
              Select Script
            </CardTitle>
            <CardDescription>
              Choose a script to configure for unattended installation
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <Search
              placeholder="Search scripts..."
              value={search || ""}
              onChange={(e) => setSearch(e.target.value || null)}
            />

            <div className="max-h-[400px] overflow-y-auto space-y-2">
              {filteredScripts.length === 0 ? (
                <div className="text-center py-8 text-muted-foreground">
                  No scripts found
                </div>
              ) : (
                filteredScripts.slice(0, 50).map((script) => (
                  <button
                    key={script.slug}
                    onClick={() => setSelectedScript(script)}
                    className={cn(
                      "w-full flex items-center gap-3 p-3 rounded-lg border transition-colors text-left",
                      selectedScript?.slug === script.slug
                        ? "border-brass bg-brass/10"
                        : "border-rust/30 hover:border-brass/50"
                    )}
                  >
                    <div className="flex h-12 w-12 min-w-12 items-center justify-center rounded-lg bg-accent p-1">
                      <Image
                        src={script.logo || `/${basePath}/logo.png`}
                        unoptimized
                        height={48}
                        width={48}
                        alt=""
                        className="h-10 w-10 object-contain"
                      />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="font-medium truncate">{script.name}</span>
                        <Badge variant="outline" className="text-xs border-copper/50">
                          {getScriptTypeDisplay(script.type)}
                        </Badge>
                      </div>
                      <p className="text-sm text-muted-foreground line-clamp-1">
                        {script.description}
                      </p>
                    </div>
                  </button>
                ))
              )}
            </div>
          </CardContent>
        </Card>

        {/* Configuration */}
        <Card className="border-rust/30">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-brass">
              <Settings2 className="h-5 w-5" />
              Configuration
            </CardTitle>
            <CardDescription>
              Customize the installation parameters
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Tabs defaultValue="basic" className="w-full">
              <TabsList className="grid w-full grid-cols-3">
                <TabsTrigger value="basic">Basic</TabsTrigger>
                <TabsTrigger value="network">Network</TabsTrigger>
                <TabsTrigger value="resources">Resources</TabsTrigger>
              </TabsList>

              {/* Basic Tab */}
              <TabsContent value="basic" className="space-y-4 mt-4">
                <div className="space-y-2">
                  <Label htmlFor="hostname" className="text-copper">Hostname</Label>
                  <Input
                    id="hostname"
                    placeholder="e.g., my-container"
                    value={config.hostname}
                    onChange={(e) => updateConfig("hostname", e.target.value)}
                    className="border-rust/30 focus:border-brass"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="os" className="text-copper">Operating System</Label>
                  <Select
                    value={config.os}
                    onValueChange={(value) => updateConfig("os", value)}
                    disabled={!selectedScript || availableOS.length === 0}
                  >
                    <SelectTrigger className="border-rust/30 focus:border-brass">
                      <SelectValue placeholder="Select OS" />
                    </SelectTrigger>
                    <SelectContent>
                      {availableOS.map((os) => (
                        <SelectItem key={os} value={os}>
                          {os}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="flex items-center justify-between">
                  <Label htmlFor="unprivileged" className="text-copper">Unprivileged Container</Label>
                  <Switch
                    id="unprivileged"
                    checked={config.unprivileged}
                    onCheckedChange={(checked) => updateConfig("unprivileged", checked)}
                  />
                </div>

                <div className="flex items-center justify-between">
                  <Label htmlFor="startAfter" className="text-copper">Start After Creation</Label>
                  <Switch
                    id="startAfter"
                    checked={config.startAfterCreation}
                    onCheckedChange={(checked) => updateConfig("startAfterCreation", checked)}
                  />
                </div>
              </TabsContent>

              {/* Network Tab */}
              <TabsContent value="network" className="space-y-4 mt-4">
                <div className="space-y-2">
                  <Label className="text-copper">Network Type</Label>
                  <div className="flex gap-2">
                    <Button
                      variant={config.networkType === "dhcp" ? "default" : "outline"}
                      size="sm"
                      onClick={() => updateConfig("networkType", "dhcp")}
                      className={cn(
                        "flex-1",
                        config.networkType === "dhcp"
                          ? "bg-brass text-background hover:bg-brass/90"
                          : "border-rust/30 hover:border-brass"
                      )}
                    >
                      DHCP
                    </Button>
                    <Button
                      variant={config.networkType === "static" ? "default" : "outline"}
                      size="sm"
                      onClick={() => updateConfig("networkType", "static")}
                      className={cn(
                        "flex-1",
                        config.networkType === "static"
                          ? "bg-brass text-background hover:bg-brass/90"
                          : "border-rust/30 hover:border-brass"
                      )}
                    >
                      Static
                    </Button>
                  </div>
                </div>

                {config.networkType === "static" && (
                  <>
                    <div className="space-y-2">
                      <Label htmlFor="ip" className="text-copper">IP Address</Label>
                      <Input
                        id="ip"
                        placeholder="e.g., 192.168.1.100"
                        value={config.ip}
                        onChange={(e) => updateConfig("ip", e.target.value)}
                        className="border-rust/30 focus:border-brass"
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="gateway" className="text-copper">Gateway</Label>
                      <Input
                        id="gateway"
                        placeholder="e.g., 192.168.1.1"
                        value={config.gateway}
                        onChange={(e) => updateConfig("gateway", e.target.value)}
                        className="border-rust/30 focus:border-brass"
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="dns" className="text-copper">DNS Servers (comma-separated)</Label>
                      <Input
                        id="dns"
                        placeholder="e.g., 8.8.8.8, 8.8.4.4"
                        value={config.dns.join(", ")}
                        onChange={(e) =>
                          updateConfig(
                            "dns",
                            e.target.value.split(",").map((s) => s.trim()).filter(Boolean)
                          )
                        }
                        className="border-rust/30 focus:border-brass"
                      />
                    </div>
                  </>
                )}

                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <Label htmlFor="ssh" className="text-copper">Enable SSH</Label>
                    <Switch
                      id="ssh"
                      checked={config.sshEnabled}
                      onCheckedChange={(checked) => updateConfig("sshEnabled", checked)}
                    />
                  </div>
                  {config.sshEnabled && (
                    <div className="space-y-2">
                      <Label htmlFor="sshPort" className="text-copper">SSH Port</Label>
                      <Input
                        id="sshPort"
                        type="number"
                        min={1}
                        max={65535}
                        value={config.sshPort}
                        onChange={(e) => updateConfig("sshPort", parseInt(e.target.value) || 22)}
                        className="border-rust/30 focus:border-brass"
                      />
                    </div>
                  )}
                </div>
              </TabsContent>

              {/* Resources Tab */}
              <TabsContent value="resources" className="space-y-4 mt-4">
                <div className="space-y-2">
                  <Label htmlFor="cpu" className="text-copper flex items-center gap-2">
                    <Cpu className="h-4 w-4" />
                    CPU Cores
                  </Label>
                  <Input
                    id="cpu"
                    type="number"
                    min={1}
                    placeholder={defaultResources.cpu?.toString() || "e.g., 2"}
                    value={config.cpuCores || ""}
                    onChange={(e) => updateConfig("cpuCores", e.target.value ? parseInt(e.target.value) : null)}
                    className="border-rust/30 focus:border-brass"
                  />
                  {defaultResources.cpu && (
                    <p className="text-xs text-muted-foreground">
                      Default: {defaultResources.cpu} cores
                    </p>
                  )}
                </div>

                <div className="space-y-2">
                  <Label htmlFor="ram" className="text-copper flex items-center gap-2">
                    <HardDrive className="h-4 w-4" />
                    RAM (MB)
                  </Label>
                  <Input
                    id="ram"
                    type="number"
                    min={128}
                    placeholder={defaultResources.ram?.toString() || "e.g., 512"}
                    value={config.ram || ""}
                    onChange={(e) => updateConfig("ram", e.target.value ? parseInt(e.target.value) : null)}
                    className="border-rust/30 focus:border-brass"
                  />
                  {defaultResources.ram && (
                    <p className="text-xs text-muted-foreground">
                      Default: {defaultResources.ram} MB
                    </p>
                  )}
                </div>

                <div className="space-y-2">
                  <Label htmlFor="disk" className="text-copper flex items-center gap-2">
                    <HardDrive className="h-4 w-4" />
                    Disk Size (GB)
                  </Label>
                  <Input
                    id="disk"
                    type="number"
                    min={1}
                    placeholder={defaultResources.disk?.toString() || "e.g., 8"}
                    value={config.diskSize || ""}
                    onChange={(e) => updateConfig("diskSize", e.target.value ? parseInt(e.target.value) : null)}
                    className="border-rust/30 focus:border-brass"
                  />
                  {defaultResources.disk && (
                    <p className="text-xs text-muted-foreground">
                      Default: {defaultResources.disk} GB
                    </p>
                  )}
                </div>
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>
      </div>

      {/* Generated Command */}
      <Card className="mt-6 border-rust/30">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-brass">
            <Terminal className="h-5 w-5" />
            Generated Command
          </CardTitle>
          <CardDescription>
            Copy and run this command in your Proxmox VE shell
          </CardDescription>
        </CardHeader>
        <CardContent>
          {!validation.valid && (
            <div className="mb-4 p-3 rounded-lg bg-corruption/10 border border-corruption/30">
              <ul className="text-sm text-corruption">
                {validation.errors.map((error, i) => (
                  <li key={i}>• {error}</li>
                ))}
              </ul>
            </div>
          )}

          <div className="relative">
            <Textarea
              value={command}
              readOnly
              className="font-mono text-sm bg-background border-rust/30 min-h-[120px] pr-12"
            />
            <Button
              size="sm"
              variant="outline"
              onClick={handleCopy}
              disabled={!validation.valid}
              className="absolute top-2 right-2 border-rust/30 hover:border-brass"
            >
              {copied ? (
                <>
                  <Check className="h-4 w-4 mr-1" />
                  Copied
                </>
              ) : (
                <>
                  <Copy className="h-4 w-4 mr-1" />
                  Copy
                </>
              )}
            </Button>
          </div>

          {selectedScript && (
            <div className="mt-4 flex items-center gap-2 text-sm text-muted-foreground">
              <Play className="h-4 w-4" />
              <span>
                Run this command in your Proxmox VE shell to deploy {selectedScript.name}
              </span>
            </div>
          )}
        </CardContent>
        <CardFooter className="flex justify-between">
          <Button
            variant="outline"
            onClick={() => {
              setSelectedScript(null);
              setConfig(DEFAULT_CONFIG);
              setSearch(null);
            }}
            className="border-rust/30 hover:border-brass"
          >
            Reset
          </Button>
          <Button
            asChild
            disabled={!selectedScript}
            className="bg-brass text-background hover:bg-brass/90"
          >
            <Link
              href={{
                pathname: "/scripts",
                query: { id: selectedScript?.slug },
              }}
            >
              View Script Details
            </Link>
          </Button>
        </CardFooter>
      </Card>
    </div>
  );
}

export default function GeneratorPage() {
  return (
    <Suspense
      fallback={
        <div className="flex h-screen w-full flex-col items-center justify-center gap-5 bg-background">
          <Loader2 className="h-10 w-10 animate-spin" />
        </div>
      }
    >
      <GeneratorContent />
    </Suspense>
  );
}
