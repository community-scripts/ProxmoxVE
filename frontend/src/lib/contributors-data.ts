export interface Contributor {
  name: string;
  role: string;
  avatar?: string;
  link?: string;
}

export const contributors: Contributor[] = [
  {
    name: "tteck",
    role: "Original Creator",
    link: "https://github.com/tteck",
  },
  {
    name: "Heretek AI",
    role: "Project Maintainer",
    link: "https://github.com/Heretek-AI",
  },
];

export const sponsors: { name: string; link?: string }[] = [
  {
    name: "GitHub Sponsors",
    link: "https://github.com/sponsors/Heretek-AI",
  },
  {
    name: "Ko-fi",
    link: "https://ko-fi.com/heretek",
  },
];
