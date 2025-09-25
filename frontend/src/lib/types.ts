import type { AlertColors } from "@/config/site-config";

export type Script = {
  name: string;
  slug: string;
  categories: number[];
  date_created: string;
  type: "vm" | "ct" | "pve" | "addon";
  updateable: boolean;
  privileged: boolean;
  interface_port: number | null;
  documentation: string | null;
  website: string | null;
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
