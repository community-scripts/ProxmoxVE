import { z } from "zod";

export const InstallMethodSchema = z.object({
  type: z.enum(["default", "alpine"], {
    errorMap: () => ({ message: "Type must be either 'default' or 'alpine'" })
  }),
  script: z.string().min(1, "Script content cannot be empty"),
  resources: z.object({
    cpu: z.number().nullable(),
    ram: z.number().nullable(),
    hdd: z.number().nullable(),
    os: z.string().nullable(),
    version: z.string().nullable(),
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
  type: z.enum(["vm", "ct", "misc", "turnkey"], {
    errorMap: () => ({ message: "Type must be either 'vm', 'ct', 'misc' or 'turnkey'" })
  }),
  updateable: z.boolean(),
  privileged: z.boolean(),
  interface_port: z.number().nullable(),
  documentation: z.string().nullable(),
  website: z.string().url().nullable(),
  logo: z.string().url().nullable(),
  description: z.string().min(1, "Description is required"),
  install_methods: z.array(InstallMethodSchema).min(1, "At least one install method is required"),
  default_credentials: z.object({
    username: z.string().nullable(),
    password: z.string().nullable(),
  }),
  notes: z.array(NoteSchema),
});

export type Script = z.infer<typeof ScriptSchema>;
