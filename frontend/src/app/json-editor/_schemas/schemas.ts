import { z } from "zod";

/** Deployment object (optional inside each install method now) */
export const DeploymentSchema = z.object({
  script: z.boolean().optional(),
  docker: z.boolean().optional(),
  docker_compose: z.boolean().optional(),
  helm: z.boolean().optional(),
  kubernetes: z.boolean().optional(),
  terraform: z.boolean().optional(),
}).partial();

/** Hosting (flags) */
export const HostingSchema = z
  .object({
    self_hosted: z.boolean().optional(),
    saas: z.boolean().optional(),
    managed_cloud: z.boolean().optional(),
  })
  .partial();

/** UI (flags) */
export const UiSchema = z
  .object({
    cli: z.boolean().optional(),
    gui: z.boolean().optional(),
    web_ui: z.boolean().optional(),
    api: z.boolean().optional(),
    tui: z.boolean().optional(),
  })
  .partial();

/** Platform object: now includes hosting and ui nested (to match your UI code) */
export const PlatformSchema = z
  .object({
    desktop: z
      .object({
        linux: z.boolean().optional(),
        windows: z.boolean().optional(),
        macos: z.boolean().optional(),
      })
      .optional(),
    mobile: z
      .object({
        android: z.boolean().optional(),
        ios: z.boolean().optional(),
      })
      .optional(),
    web_app: z.boolean().optional(),
    browser_extension: z.boolean().optional(),
    cli_only: z.boolean().optional(),

    // nested hosting + ui to match install-method.tsx usage (method.platform.hosting / method.platform.ui)
    hosting: HostingSchema.optional(),
    ui: UiSchema.optional(),
  })
  .partial();

/** Single install method shape
 *  platform is optional, deployment is optional (we keep top-level deployment optional
 *  because your page.tsx also keeps a top-level script.deployment object)
 */
export const InstallMethodSchema = z.object({
  platform: PlatformSchema.optional(),
  deployment: DeploymentSchema.optional(),
});

/** Main Script schema */
export const ScriptSchema = z.object({
  name: z.string().min(1, "Name is required"),
  slug: z.string().min(1, "Slug is required"),
  categories: z.array(z.number()).min(1, "At least one category is required"),
  date_created: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, "Date must be in YYYY-MM-DD format")
    .min(1, "Date is required"),
  interface_port: z.number().nullable().optional(),
  documentation: z.string().nullable().optional(),
  website: z.string().url().nullable().optional(),
  github: z.string().url().nullable().optional(),
  logo: z.string().url().nullable().optional(),

  description: z.string().min(1, "Description is required"),

  install_methods: z.array(InstallMethodSchema).min(1, "At least one install method is required"),

  default_credentials: z
    .object({
      username: z.string().nullable(),
      password: z.string().nullable(),
    })
    .optional(),

  notes: z.array(
    z.object({
      text: z.string().min(1, "Note text cannot be empty"),
      type: z.string().min(1, "Note type cannot be empty"),
    }),
  ).optional().default([]),
});

export type Script = z.infer<typeof ScriptSchema>;
