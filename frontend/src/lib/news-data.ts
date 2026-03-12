export interface NewsItem {
  id: string;
  date: string;
  title: string;
  content: string;
  type: "announcement" | "update" | "release" | "news";
}

export const newsItems: NewsItem[] = [
  {
    id: "1",
    date: "2026-03-11",
    title: "Heretek AI Scripts Portal Launch",
    content: "Welcome to the new Heretek AI Proxmox VE Scripts portal. This site provides a modern interface for browsing, discovering, and deploying automation scripts for your Proxmox environments. Built by the community, for the community.",
    type: "announcement",
  },
  {
    id: "2",
    date: "2026-03-06",
    title: "New Homepage Design",
    content: "A new website for the Heretek AI ProxmoxVE project makes it easier to discover, browse, and deploy automation scripts for Proxmox environments. Built by the community, the platform provides a central hub for simplifying homelab and virtualization workflows.",
    type: "news",
  },
  {
    id: "3",
    date: "2026-02-28",
    title: "Script Categories Added",
    content: "We've organized all scripts into logical categories to make it easier to find what you need. Browse by category including Proxmox & Virtualization, Operating Systems, Containers & Docker, Network & Firewall, and more.",
    type: "update",
  },
];

export function getNewsItems(limit?: number): NewsItem[] {
  const sorted = [...newsItems].sort(
    (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime(),
  );
  return limit ? sorted.slice(0, limit) : sorted;
}

export function getNewsItemById(id: string): NewsItem | undefined {
  return newsItems.find(item => item.id === id);
}
