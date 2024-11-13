import { z } from "zod";

const InstallMethodSchema = z.object({
  type: z.enum(["default", "alpine"]),
  script: z.string().min(1),
  resources: z.object({
    cpu: z.number().nullable(),
    ram: z.number().nullable(),
    hdd: z.number().nullable(),
    os: z.string().nullable(),
    version: z.number().nullable(),
  }),
});

const NoteSchema = z.object({
  text: z.string().min(1),
  type: z.string().min(1),
});

export const ScriptSchema = z.object({
  name: z.string().min(1),
  slug: z.string().min(1),
  categories: z.array(z.number()),
  date_created: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  type: z.enum(["vm", "ct", "misc"]),
  updateable: z.boolean(),
  privileged: z.boolean(),
  interface_port: z.number().nullable(),
  documentation: z.string().nullable(),
  website: z.string().url().nullable(),
  logo: z.string().url().nullable(),
  description: z.string().min(1),
  install_methods: z.array(InstallMethodSchema),
  default_credentials: z.object({
    username: z.string().nullable(),
    password: z.string().nullable(),
  }),
  notes: z.array(NoteSchema),
});
