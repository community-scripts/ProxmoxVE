import { AlertColors } from "@/config/siteConfig";

export type Script = {
  name: string;
  slug: string;
  categories: number[];
  date_created: string;
  type: "vm" | "ct" | "misc";
  updateable: boolean;
  privileged: boolean;
  interface_port: number | null;
  documentation: string | null;
  website: string | null;
  logo: string | null;
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
  scripts: Script[];
};

export type Metadata = {
  categories: Category[];
};

export interface Version {
  name: string;
  slug: string;
}

export interface OperatingSystem {
  name: string;
  versions: Version[];
}