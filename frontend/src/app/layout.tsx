import type { Metadata } from "next";

import { NuqsAdapter } from "nuqs/adapters/next/app";
import { Cinzel, JetBrains_Mono } from "next/font/google";
import Script from "next/script";
import React from "react";

import { CopycatWarningToast } from "@/components/copycat-warning-toast";
import { ThemeProvider } from "@/components/theme-provider";
import { analytics, basePath } from "@/config/site-config";
import QueryProvider from "@/components/query-provider";
import { Toaster } from "@/components/ui/sonner";
import Footer from "@/components/footer";
import Navbar from "@/components/navbar";
import "@/styles/globals.css";

// Heretek Fonts - Cinzel for headings (gothic/medieval), JetBrains Mono for body (industrial/tech)
const cinzel = Cinzel({
  subsets: ["latin"],
  variable: "--font-cinzel",
  display: "swap",
});

const jetbrainsMono = JetBrains_Mono({
  subsets: ["latin"],
  variable: "--font-jetbrains",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Heretek AI - Proxmox VE Scripts",
  description:
    "The Heretek AI repository for Proxmox VE Helper-Scripts. Embrace the machine spirit with over 400+ scripts to manage your Proxmox Virtual Environment. Tech-heresy made manifest.",
  applicationName: "Heretek AI",
  generator: "Next.js",
  referrer: "origin-when-cross-origin",
  keywords: [
    "Proxmox VE",
    "Helper-Scripts",
    "Heretek",
    "Heretek AI",
    "helper",
    "scripts",
    "proxmox",
    "VE",
    "virtualization",
    "containers",
    "LXC",
    "VM",
    "machine spirit",
    "tech-heresy",
    "Warhammer 40K",
  ],
  authors: [
    { name: "Bram Suurd", url: "https://github.com/BramSuurdje" },
    { name: "Heretek AI", url: "https://github.com/Heretek-AI" },
  ],
  creator: "Bram Suurd",
  publisher: "Heretek AI",
  metadataBase: new URL(`https://Heretek-AI.github.io/${basePath}/`),
  alternates: {
    canonical: `https://Heretek-AI.github.io/${basePath}/`,
  },
  viewport: {
    width: "device-width",
    initialScale: 1,
    maximumScale: 5,
  },
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  openGraph: {
    title: "Heretek AI - Proxmox VE Scripts",
    description:
      "The Heretek AI repository for Proxmox VE Helper-Scripts. Embrace the machine spirit with over 400+ scripts to manage your Proxmox Virtual Environment.",
    url: `https://Heretek-AI.github.io/${basePath}/`,
    siteName: "Heretek AI",
    images: [
      {
        url: `https://Heretek-AI.github.io/${basePath}/defaultimg.png`,
        width: 1200,
        height: 630,
        alt: "Heretek AI - Proxmox VE Scripts",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Heretek AI - Proxmox VE Scripts",
    creator: "@BramSuurdje",
    description:
      "The Heretek AI repository for Proxmox VE Helper-Scripts. Embrace the machine spirit with over 400+ scripts to manage your Proxmox Virtual Environment.",
    images: [`https://Heretek-AI.github.io/${basePath}/defaultimg.png`],
  },
  manifest: "/manifest.webmanifest",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "Heretek AI",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning className={`${cinzel.variable} ${jetbrainsMono.variable}`}>
      <head>
        <link rel="canonical" href={metadata.metadataBase?.href} />
        <link rel="manifest" href="manifest.webmanifest" />
        <link rel="preconnect" href="https://api.github.com" />
      </head>
      <body className={`${jetbrainsMono.className} antialiased`}>
        <Script
          src={`https://${analytics.url}/api/script.js`}
          data-site-id={analytics.token}
          strategy="afterInteractive"
        />
        <ThemeProvider attribute="class" defaultTheme="dark" enableSystem disableTransitionOnChange>
          <div className="flex w-full flex-col justify-center">
            <NuqsAdapter>
              <QueryProvider>
                <Navbar />
                <div className="flex min-h-screen flex-col justify-center">
                  <div className="flex w-full justify-center">
                    <div className="w-full max-w-[1440px] ">
                      {children}
                      <Toaster richColors />
                      <CopycatWarningToast />
                    </div>
                  </div>
                  <Footer />
                </div>
              </QueryProvider>
            </NuqsAdapter>
          </div>
        </ThemeProvider>
      </body>
    </html>
  );
}
