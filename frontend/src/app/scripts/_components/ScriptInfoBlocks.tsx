import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { extractDate } from "@/lib/time";
import { Category } from "@/lib/types";
import { CalendarPlus } from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { useMemo, useState } from "react";

const ITEMS_PER_PAGE = 3;

export function LatestScripts({ items }: { items: Category[] }) {
  const [page, setPage] = useState(1);

  const latestScripts = useMemo(() => {
    if (!items) return [];
    const scripts = items.flatMap((category) => category.scripts || []);
    return scripts.sort(
      (a, b) => new Date(b.date_created).getTime() - new Date(a.date_created).getTime(),
    );
  }, [items]);

  const goToNextPage = () => {
    setPage((prevPage) => prevPage + 1);
  };

  const goToPreviousPage = () => {
    setPage((prevPage) => prevPage - 1);
  };

  const startIndex = (page - 1) * ITEMS_PER_PAGE;
  const endIndex = page * ITEMS_PER_PAGE;

  if (!items) {
    return null;
  }

  return (
    <div className="">
      {latestScripts.length > 0 && (
        <div className="flex w-full items-center justify-between">
          <h2 className="text-lg font-semibold">Newest Scripts</h2>
          <div className="flex items-center justify-end gap-1">
            {page > 1 && (
              <div
                className="cursor-pointer select-none p-2 text-sm font-semibold"
                onClick={goToPreviousPage}
              >
                Previous
              </div>
            )}
            {endIndex < latestScripts.length && (
              <div
                onClick={goToNextPage}
                className="cursor-pointer select-none p-2 text-sm font-semibold"
              >
                {page === 1 ? "More.." : "Next"}
              </div>
            )}
          </div>
        </div>
      )}
      <div className="min-w flex w-full flex-row flex-wrap gap-4">
        {latestScripts.slice(startIndex, endIndex).map((item) => (
          <Card
            key={item.name}
            className="min-w-[250px] flex-1 flex-grow bg-accent/30"
          >
            <CardHeader>
              <CardTitle className="flex items-center gap-3">
                <div className="flex h-16 w-16 items-center justify-center rounded-lg bg-accent p-1">
                  <Image
                    src={item.logo || "/logo.png"}
                    unoptimized
                    height={64}
                    width={64}
                    alt=""
                    className="h-11 w-11 object-contain"
                  />
                </div>
                <div className="flex flex-col">
                  <p className="text-lg line-clamp-1">
                    {item.name} {item.type}
                  </p>
                  <p className="text-sm text-muted-foreground flex items-center gap-1">
                    <CalendarPlus className="h-4 w-4" />
                    {extractDate(item.date_created)}
                  </p>
                </div>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <CardDescription className="line-clamp-3 text-card-foreground">
                {item.description}
              </CardDescription>
            </CardContent>
            <CardFooter className="">
              <Button asChild variant="outline">
                <Link
                  href={{
                    pathname: "/scripts",
                    query: { id: item.name },
                  }}
                >
                  View Script
                </Link>
              </Button>
            </CardFooter>
          </Card>
        ))}
      </div>
    </div>
  );
}

// TODO: find way to determine what the most popular scripts are  

// export function MostViewedScripts({ items }: { items: Category[] }) {
//   const [page, setPage] = useState(1);

//   const mostViewedScripts = useMemo(() => {
//     if (!items) return [];
//     const scripts = items.flatMap((category) => category.scripts || []);
//     const mostViewedScripts = scripts
//       .filter((script) => script.isMostViewed)
//       .map((script) => ({
//         ...script,
//       }));
//     return mostViewedScripts;
//   }, [items]);

//   const goToNextPage = () => {
//     setPage((prevPage) => prevPage + 1);
//   };

//   const goToPreviousPage = () => {
//     setPage((prevPage) => prevPage - 1);
//   };

//   const startIndex = (page - 1) * ITEMS_PER_PAGE;
//   const endIndex = page * ITEMS_PER_PAGE;

//   return (
//     <div className="">
//       {mostViewedScripts.length > 0 && (
//         <>
//           <h2 className="text-lg font-semibold">Most Viewed Scripts</h2>
//         </>
//       )}
//       <div className="min-w flex w-full flex-row flex-wrap gap-4">
//         {mostViewedScripts.slice(startIndex, endIndex).map((item) => (
//           <Card
//             key={item.id}
//             className="min-w-[250px] flex-1 flex-grow bg-accent/30"
//           >
//             <CardHeader>
//               <CardTitle className="flex items-center gap-3">
//                 <div className="flex max-h-16 min-h-16 min-w-16 max-w-16 items-center justify-center rounded-lg bg-accent p-1">
//                   <Image
//                     unoptimized
//                     src={item.logo}
//                     height={64}
//                     width={64}
//                     alt=""
//                     className="h-11 w-11 object-contain"
//                   />
//                 </div>
//                 <div className="flex flex-col">
//                   <p className="line-clamp-1 text-lg">
//                     {item.title} {item.item_type}
//                   </p>
//                   <p className="flex items-center gap-1 text-sm text-muted-foreground">
//                     <CalendarPlus className="h-4 w-4" />
//                     {extractDate(item.created)}
//                   </p>
//                 </div>
//               </CardTitle>
//             </CardHeader>
//             <CardContent>
//               <CardDescription className="line-clamp-3 text-card-foreground break-words">
//                 {item.description}
//               </CardDescription>
//             </CardContent>
//             <CardFooter className="">
//               <Button asChild variant="outline">
//                 <Link
//                   href={{
//                     pathname: "/scripts",
//                     query: { id: item.title },
//                   }}
//                   prefetch={false}
//                 >
//                   View Script
//                 </Link>
//               </Button>
//             </CardFooter>
//           </Card>
//         ))}
//       </div>
//       <div className="flex justify-end gap-1 p-2">
//         {page > 1 && (
//           <Button onClick={goToPreviousPage} variant="outline">
//             Previous
//           </Button>
//         )}
//         {endIndex < mostViewedScripts.length && (
//           <Button onClick={goToNextPage} variant="outline">
//             {page === 1 ? "More.." : "Next"}
//           </Button>
//         )}
//       </div>
//     </div>
//   );
// }
