import type { AlertColors } from "@/config/site-config";

export type Script = {
  name: string;
  slug: string;
  categories: number[];
  date_created: string;
  type: "vm" | "ct" | "pve" | "addon" | "dc" | "helm";
  updateable: boolean;
  privileged: boolean;
  interface_port: number | null;
  documentation: string | null;
  website: string | null;
  github: string | null;
  logo: string | null;
  config_path: string;
  description: string;
  install_methods: {
    type: "default" | "alpine";
    script: string;
    resources: {
      cpu: number | null;
      ram: number | null;
      hdd: number | null;
      os: string | null;
      version: string | null;
    };
    platform: {
      desktop: {
        linux: boolean,
        windows: boolean,
        macos: boolean,
      },
      mobile: {
        android: boolean,
        ios: boolean,
      }
      web_app: boolean,
      browser_extension: boolean,
      cli_only: boolean,
      hosting: {
        self_hosted: boolean,
        saas: boolean,
        managed_cloud: boolean
      },
      deployment: {
        binary: boolean,
        docker: boolean,
        docker_compose: boolean,
        helm: {
          oci_artifact: boolean,
          helm_repository: boolean,
        },
        kubernetes: boolean,
        terraform: boolean
      },
      ui: {
        cli: boolean,
        gui: boolean,
        web_ui: boolean,
        api: boolean,
        tui: boolean
      }
    },
  }[];
  default_credentials: {
    username: string | null;
    password: string | null;
  };
  notes: [
    {
      text: string;
      type: keyof typeof AlertColors;
    },
  ];
  manifest_path?: {
    binary?: string | null;
    docker_compose?: string | null;
    kubernetes?: string | null;
    helm?: string | null;
    terraform?: string | null;
  };
};

export type Category = {
  name: string;
  id: number;
  sort_order: number;
  description: string;
  icon: string;
  scripts: Script[];
};

export type Metadata = {
  categories: Category[];
};

export type Version = {
  name: string;
  slug: string;
};

export type OperatingSystem = {
  name: string;
  versions: Version[];
};

export type AppVersion = {
  name: string;
  version: string;
  date: Date;
};
