import type { Script } from "./types";

export interface GeneratorConfig {
  script: Script | null;
  hostname: string;
  ip: string;
  gateway: string;
  dns: string[];
  cpuCores: number | null;
  ram: number | null;
  diskSize: number | null;
  os: string;
  networkType: "dhcp" | "static";
  sshEnabled: boolean;
  sshPort: number;
  unprivileged: boolean;
  startAfterCreation: boolean;
}

export const DEFAULT_CONFIG: GeneratorConfig = {
  script: null,
  hostname: "",
  ip: "",
  gateway: "",
  dns: [],
  cpuCores: null,
  ram: null,
  diskSize: null,
  os: "",
  networkType: "dhcp",
  sshEnabled: true,
  sshPort: 22,
  unprivileged: true,
  startAfterCreation: true,
};

/**
 * Generate the install command based on configuration
 */
export function generateInstallCommand(config: GeneratorConfig): string {
  if (!config.script) {
    return "# Select a script to generate the command";
  }

  const scriptPath = config.script.install_methods[0]?.script;
  if (!scriptPath) {
    return "# No install script available for this script";
  }

  const baseUrl = "https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/main";
  let command = `bash -c "$(wget -qLO - ${baseUrl}/${scriptPath})"`;

  // Build environment variables for unattended installation
  const envVars: string[] = [];

  // Hostname
  if (config.hostname) {
    envVars.push(`HOSTNAME="${config.hostname}"`);
  }

  // Network configuration (static only)
  if (config.networkType === "static") {
    if (config.ip) {
      envVars.push(`IP="${config.ip}"`);
    }
    if (config.gateway) {
      envVars.push(`GATEWAY="${config.gateway}"`);
    }
    if (config.dns.length > 0) {
      envVars.push(`DNS="${config.dns.join(",")}"`);
    }
  }

  // Resources
  if (config.cpuCores) {
    envVars.push(`CORES="${config.cpuCores}"`);
  }
  if (config.ram) {
    envVars.push(`RAM="${config.ram}"`);
  }
  if (config.diskSize) {
    envVars.push(`DISK_SIZE="${config.diskSize}"`);
  }

  // SSH configuration
  if (config.sshEnabled && config.sshPort !== 22) {
    envVars.push(`SSH_PORT="${config.sshPort}"`);
  }

  // Unprivileged container
  if (!config.unprivileged) {
    envVars.push(`UNPRIVILEGED="no"`);
  }

  // Start after creation
  if (!config.startAfterCreation) {
    envVars.push(`START="no"`);
  }

  // Prepend environment variables if any
  if (envVars.length > 0) {
    command = `${envVars.join(" ")} ${command}`;
  }

  return command;
}

/**
 * Generate a curl command for the script
 */
export function generateCurlCommand(config: GeneratorConfig): string {
  if (!config.script) {
    return "# Select a script to generate the command";
  }

  const scriptPath = config.script.install_methods[0]?.script;
  if (!scriptPath) {
    return "# No install script available for this script";
  }

  const baseUrl = "https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/main";
  return `curl -fsSL ${baseUrl}/${scriptPath} | bash`;
}

/**
 * Get available operating systems for a script
 */
export function getAvailableOS(script: Script | null): string[] {
  if (!script) return [];

  const osSet = new Set<string>();
  script.install_methods.forEach((method) => {
    if (method.resources?.os) {
      osSet.add(method.resources.os);
    }
  });

  return Array.from(osSet);
}

/**
 * Get default resources for a script
 */
export function getDefaultResources(script: Script | null): {
  cpu: number | null;
  ram: number | null;
  disk: number | null;
} {
  if (!script || !script.install_methods[0]?.resources) {
    return { cpu: null, ram: null, disk: null };
  }

  const resources = script.install_methods[0].resources;
  return {
    cpu: resources.cpu,
    ram: resources.ram,
    disk: resources.hdd,
  };
}

/**
 * Validate configuration
 */
export function validateConfig(config: GeneratorConfig): {
  valid: boolean;
  errors: string[];
} {
  const errors: string[] = [];

  if (!config.script) {
    errors.push("Please select a script");
  }

  if (config.hostname && !/^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$/.test(config.hostname)) {
    errors.push("Hostname must be alphanumeric with hyphens (no leading/trailing hyphens)");
  }

  if (config.networkType === "static") {
    if (!config.ip) {
      errors.push("IP address is required for static network configuration");
    } else if (!/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/.test(config.ip)) {
      errors.push("Invalid IP address format");
    }

    if (config.gateway && !/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/.test(config.gateway)) {
      errors.push("Invalid gateway address format");
    }
  }

  if (config.cpuCores && config.cpuCores < 1) {
    errors.push("CPU cores must be at least 1");
  }

  if (config.ram && config.ram < 128) {
    errors.push("RAM must be at least 128 MB");
  }

  if (config.diskSize && config.diskSize < 1) {
    errors.push("Disk size must be at least 1 GB");
  }

  if (config.sshPort && (config.sshPort < 1 || config.sshPort > 65535)) {
    errors.push("SSH port must be between 1 and 65535");
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

/**
 * Get script type display name
 */
export function getScriptTypeDisplay(type: string): string {
  switch (type) {
    case "ct":
      return "LXC Container";
    case "vm":
      return "Virtual Machine";
    case "pve":
      return "Proxmox VE";
    case "addon":
      return "Addon";
    case "turnkey":
      return "TurnKey";
    default:
      return type;
  }
}
