export function getDisplayValueFromRAM(ram: number): string {
  return ram >= 1024 ? `${Math.floor(ram / 1024)}GB` : `${ram}MB`;
}

export function cleanSlug(slug: string): string {
  return slug.replace(/[^a-z0-9]/gi, "").toLowerCase();
}
