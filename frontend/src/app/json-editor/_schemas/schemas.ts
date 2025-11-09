import { z } from "zod";

export const InstallMethodSchema = z.object({
  platform: z.object({
    desktop: z.object({
      linux: z.boolean(),
      windows: z.boolean(),
      macos: z.boolean(),
    }),
    mobile: z.object({
      android: z.boolean(),
      ios: z.boolean(),
    }),
    web_app: z.boolean(),
    browser_extension: z.boolean(),
    cli_only: z.boolean(),
    hosting: z.object({
      self_hosted: z.boolean(),
      saas: z.boolean(),
      managed_cloud: z.boolean(),
    }),
    deployment: z.object({
      script: z.boolean(),
      docker: z.boolean(),
      docker_compose: z.boolean(),
      helm: z.boolean(),
      kubernetes: z.boolean(),
      terraform: z.boolean(),
    }),
    ui: z.object({
      cli: z.boolean(),
      gui: z.boolean(),
      web_ui: z.boolean(),
      api: z.boolean(),
      tui: z.boolean(),
    }),
  }),
});

const NoteSchema = z.object({
  text: z.string().min(1, "Note text cannot be empty"),
  type: z.string().min(1, "Note type cannot be empty"),
});

export const ScriptSchema = z.object({
  name: z.string().min(1, "Name is required"),
  slug: z.string().min(1, "Slug is required"),
  categories: z.array(z.number()),
  date_created: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Date must be in YYYY-MM-DD format").min(1, "Date is required"),
  type: z.enum(["vm", "ct", "pve", "addon", "turnkey"], {
    errorMap: () => ({ message: "Type must be either 'vm', 'ct', 'pve', 'addon' or 'turnkey'" }),
  }),
  updateable: z.boolean(),
  privileged: z.boolean(),
  interface_port: z.number().nullable(),
  documentation: z.string().nullable(),
  website: z.string().url().nullable(),
  logo: z.string().url().nullable(),
  config_path: z.string(),
  description: z.string().min(1, "Description is required"),
  install_methods: z.array(InstallMethodSchema).min(1, "At least one install method is required"),
  default_credentials: z.object({
    username: z.string().nullable(),
    password: z.string().nullable(),
  }),
  notes: z.array(NoteSchema),
});

export type Script = z.infer<typeof ScriptSchema>;
