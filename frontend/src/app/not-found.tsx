"use client";
import { Button } from "@/components/ui/button";
import { basePath } from "@/config/site-config";

export default function NotFoundPage() {
  return (
    <div className="flex h-screen w-full flex-col items-center justify-center gap-5 bg-background px-4 md:px-6">
      <div className="space-y-2 text-center">
        <h1 className="text-4xl font-bold tracking-tighter sm:text-5xl md:text-6xl">
          404
        </h1>
        <p className="text-muted-foreground md:text-xl">
          Oops, the page you are looking for could not be found.
        </p>
      </div>
      <Button
        onClick={() => {
          if (window.history.length > 1) {
            window.history.back();
          }
          else {
            window.location.href = `/${basePath}`;
          }
        }}
        variant="secondary"
      >
        Go Back
      </Button>
    </div>
  );
}
