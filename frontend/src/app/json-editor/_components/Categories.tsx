import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Category } from "@/lib/types";
import { cn } from "@/lib/utils";
import { z } from "zod";
import { type Script } from "../_schemas/schemas";
import { memo } from "react";

type CategoryProps = {
  script: Script;
  setScript: (script: Script) => void;
  setIsValid: (isValid: boolean) => void;
  setZodErrors: (zodErrors: z.ZodError | null) => void;
  categories: Category[];
};

const CategoryTag = memo(({ 
  category, 
  onRemove 
}: { 
  category: Category;
  onRemove: () => void;
}) => (
  <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
    {category.name}
    <button
      type="button"
      className="ml-1 inline-flex text-blue-400 hover:text-blue-600"
      onClick={onRemove}
    >
      <span className="sr-only">Remove</span>
      <svg
        className="h-3 w-3"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M6 18L18 6M6 6l12 12"
        />
      </svg>
    </button>
  </span>
));

CategoryTag.displayName = 'CategoryTag';

function Categories({
  script,
  setScript,
  categories,
}: Omit<CategoryProps, "setIsValid" | "setZodErrors">) {
  const addCategory = (categoryId: number) => {
    setScript({
      ...script,
      categories: [...new Set([...script.categories, categoryId])],
    });
  };

  const removeCategory = (categoryId: number) => {
    setScript({
      ...script,
      categories: script.categories.filter((id: number) => id !== categoryId),
    });
  };

  const categoryMap = new Map(categories.map(c => [c.id, c]));

  return (
    <div>
      <Label>
        Category <span className="text-red-500">*</span>
      </Label>
      <Select onValueChange={(value) => addCategory(Number(value))}>
        <SelectTrigger>
          <SelectValue placeholder="Select a category" />
        </SelectTrigger>
        <SelectContent>
          {categories.map((category) => (
            <SelectItem key={category.id} value={category.id.toString()}>
              {category.name}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
      <div
        className={cn(
          "flex flex-wrap gap-2",
          script.categories.length !== 0 && "mt-2",
        )}
      >
        {script.categories.map((categoryId) => {
          const category = categoryMap.get(categoryId);
          return category ? (
            <CategoryTag
              key={categoryId}
              category={category}
              onRemove={() => removeCategory(categoryId)}
            />
          ) : null;
        })}
      </div>
    </div>
  );
}

export default memo(Categories);
