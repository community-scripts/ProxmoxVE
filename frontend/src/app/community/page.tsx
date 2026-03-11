"use client";

import React from "react";
import { CalendarIcon, ExternalLink, Heart, MessageCircle, Users } from "lucide-react";
import Link from "next/link";
import { Suspense } from "react";
import { Loader2 } from "lucide-react";

import { getNewsItems, type NewsItem } from "@/lib/news-data";
import { contributors, sponsors } from "@/lib/contributors-data";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import FAQ from "@/components/faq";
import { cn } from "@/lib/utils";

const typeColors: Record<string, string> = {
  announcement: "bg-primary/10 text-primary border-primary/20",
  update: "bg-green-500/10 text-green-600 dark:text-green-400 border-green-500/20",
  release: "bg-blue-500/10 text-blue-600 dark:text-blue-400 border-blue-500/20",
  news: "bg-orange-500/10 text-orange-600 dark:text-orange-400 border-orange-500/20",
};

function NewsSection() {
  const newsItems = getNewsItems();

  return (
    <div className="space-y-6">
      {newsItems.map((item: NewsItem) => (
        <Card key={item.id}>
          <CardHeader>
            <div className="flex items-center gap-2 mb-2">
              <span
                className={cn(
                  "rounded-full px-2 py-0.5 text-xs font-medium border",
                  typeColors[item.type] || typeColors.news,
                )}
              >
                {item.type}
              </span>
              <span className="text-xs text-muted-foreground flex items-center gap-1">
                <CalendarIcon className="h-3 w-3" />
                {new Date(item.date).toLocaleDateString("en-US", {
                  month: "long",
                  day: "numeric",
                  year: "numeric",
                })}
              </span>
            </div>
            <CardTitle>{item.title}</CardTitle>
          </CardHeader>
          <CardContent>
            <CardDescription className="text-base">{item.content}</CardDescription>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}

function ShoutoutsSection() {
  return (
    <div className="grid gap-4 md:grid-cols-2">
      {contributors.map((contributor) => (
        <Card key={contributor.name}>
          <CardHeader>
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
                <Users className="h-5 w-5 text-primary" />
              </div>
              <div>
                <CardTitle className="text-lg">{contributor.name}</CardTitle>
                <CardDescription>{contributor.role}</CardDescription>
              </div>
            </div>
          </CardHeader>
          {contributor.link && (
            <CardContent>
              <Button variant="outline" size="sm" asChild>
                <a href={contributor.link} target="_blank" rel="noopener noreferrer">
                  View Profile
                  <ExternalLink className="ml-2 h-4 w-4" />
                </a>
              </Button>
            </CardContent>
          )}
        </Card>
      ))}
    </div>
  );
}

function SponsoringSection() {
  return (
    <div className="grid gap-4 md:grid-cols-2">
      {sponsors.map((sponsor) => (
        <Card key={sponsor.name}>
          <CardHeader>
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
                <Heart className="h-5 w-5 text-primary" />
              </div>
              <div>
                <CardTitle className="text-lg">{sponsor.name}</CardTitle>
                <CardDescription>Support the project</CardDescription>
              </div>
            </div>
          </CardHeader>
          {sponsor.link && (
            <CardContent>
              <Button variant="outline" size="sm" asChild>
                <a href={sponsor.link} target="_blank" rel="noopener noreferrer">
                  Support
                  <ExternalLink className="ml-2 h-4 w-4" />
                </a>
              </Button>
            </CardContent>
          )}
        </Card>
      ))}
    </div>
  );
}

function CommunityContent() {
  return (
    <div className="mb-3">
      <div className="mt-20 px-4 xl:px-0">
        <div className="max-w-4xl mx-auto">
          {/* Header */}
          <div className="mb-8">
            <h1 className="text-3xl font-bold tracking-tight mb-2">Community Hub</h1>
            <p className="text-muted-foreground">
              News, frequently asked questions, and shoutouts to the people who make Heretek AI possible.
            </p>
          </div>

          {/* Sections Navigation */}
          <div className="flex flex-wrap gap-4 mb-8 border-b pb-4">
            <a href="#news" className="text-sm font-medium hover:text-primary transition-colors">
              News
            </a>
            <a href="#faq" className="text-sm font-medium hover:text-primary transition-colors">
              FAQ
            </a>
            <a href="#shoutouts" className="text-sm font-medium hover:text-primary transition-colors">
              Shoutouts
            </a>
            <a href="#sponsoring" className="text-sm font-medium hover:text-primary transition-colors">
              Sponsoring
            </a>
          </div>

          {/* News Section */}
          <section id="news" className="mb-12">
            <div className="flex items-center gap-2 mb-6">
              <MessageCircle className="h-5 w-5 text-primary" />
              <h2 className="text-2xl font-bold tracking-tight">News</h2>
            </div>
            <NewsSection />
          </section>

          <Separator className="my-8" />

          {/* FAQ Section */}
          <section id="faq" className="mb-12">
            <div className="flex items-center gap-2 mb-6">
              <MessageCircle className="h-5 w-5 text-primary" />
              <h2 className="text-2xl font-bold tracking-tight">Frequently Asked Questions</h2>
            </div>
            <FAQ />
          </section>

          <Separator className="my-8" />

          {/* Shoutouts Section */}
          <section id="shoutouts" className="mb-12">
            <div className="flex items-center gap-2 mb-6">
              <Users className="h-5 w-5 text-primary" />
              <h2 className="text-2xl font-bold tracking-tight">Shoutouts</h2>
            </div>
            <p className="text-muted-foreground mb-6">
              Thank you to all the contributors who have helped make this project possible.
            </p>
            <ShoutoutsSection />
          </section>

          <Separator className="my-8" />

          {/* Sponsoring Section */}
          <section id="sponsoring" className="mb-12">
            <div className="flex items-center gap-2 mb-6">
              <Heart className="h-5 w-5 text-primary" />
              <h2 className="text-2xl font-bold tracking-tight">Sponsoring</h2>
            </div>
            <p className="text-muted-foreground mb-6">
              If you find this project helpful, consider supporting its development.
            </p>
            <SponsoringSection />
          </section>
        </div>
      </div>
    </div>
  );
}

export default function CommunityPage() {
  return (
    <Suspense
      fallback={(
        <div className="flex h-[50vh] w-full flex-col items-center justify-center gap-5 bg-background px-4 md:px-6">
          <Loader2 className="h-10 w-10 animate-spin" />
        </div>
      )}
    >
      <CommunityContent />
    </Suspense>
  );
}
