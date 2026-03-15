"use client";

import { Search as SearchIcon, X } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { useQueryState } from "nuqs";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

interface SearchProps {
  placeholder?: string;
  className?: string;
  debounceMs?: number;
  // Controlled mode props
  value?: string;
  onChange?: (e: React.ChangeEvent<HTMLInputElement>) => void;
}

export function Search({
  placeholder = "Search scripts...",
  className,
  debounceMs = 300,
  value: controlledValue,
  onChange: controlledOnChange,
}: SearchProps) {
  const [search, setSearch] = useQueryState("search");
  const [localValue, setLocalValue] = useState(controlledValue ?? search ?? "");

  // Determine if we're in controlled mode
  const isControlled = controlledValue !== undefined && controlledOnChange !== undefined;

  // Sync local state with URL state on mount (uncontrolled mode)
  useEffect(() => {
    if (!isControlled) {
      setLocalValue(search ?? "");
    }
  }, [search, isControlled]);

  // Sync with controlled value
  useEffect(() => {
    if (isControlled) {
      setLocalValue(controlledValue);
    }
  }, [controlledValue, isControlled]);

  // Debounced search update (uncontrolled mode only)
  useEffect(() => {
    if (isControlled) return;

    const timer = setTimeout(() => {
      if (localValue !== (search ?? "")) {
        setSearch(localValue || null);
      }
    }, debounceMs);

    return () => clearTimeout(timer);
  }, [localValue, debounceMs, search, setSearch, isControlled]);

  const handleClear = useCallback(() => {
    setLocalValue("");
    if (!isControlled) {
      setSearch(null);
    }
    if (controlledOnChange) {
      controlledOnChange({ target: { value: "" } } as React.ChangeEvent<HTMLInputElement>);
    }
  }, [setSearch, isControlled, controlledOnChange]);

  const handleChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value;
    setLocalValue(newValue);

    if (isControlled && controlledOnChange) {
      controlledOnChange(e);
    }
  }, [isControlled, controlledOnChange]);

  return (
    <div className={cn("relative", className)}>
      <SearchIcon className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
      <Input
        type="text"
        placeholder={placeholder}
        value={localValue}
        onChange={handleChange}
        className="pl-9 pr-9 border-rust/30 focus:border-brass bg-background"
      />
      {localValue && (
        <Button
          variant="ghost"
          size="sm"
          onClick={handleClear}
          className="absolute right-1 top-1/2 h-7 w-7 -translate-y-1/2 p-0 hover:bg-accent"
        >
          <X className="h-4 w-4" />
          <span className="sr-only">Clear search</span>
        </Button>
      )}
    </div>
  );
}
