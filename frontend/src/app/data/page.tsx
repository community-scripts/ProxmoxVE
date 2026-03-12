"use client";

import {
  ArrowUpDown,
  Box,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  List,
  Loader2,
  Trophy,
  XCircle,
} from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { Bar, BarChart, CartesianGrid, Cell, LabelList, XAxis } from "recharts";

import type { ChartConfig } from "@/components/ui/chart";

import { formattedBadge } from "@/components/command-menu";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";

type DataModel = {
  id: number;
  ct_type: number;
  disk_size: number;
  core_count: number;
  ram_size: number;
  os_type: string;
  os_version: string;
  disableip6: string;
  nsapp: string;
  created_at: string;
  method: string;
  pve_version: string;
  status: string;
  error: string;
  type: string;
  [key: string]: any;
};

type SummaryData = {
  total_entries: number;
  status_count: Record<string, number>;
  nsapp_count: Record<string, number>;
};

// Chart colors optimized for both light and dark modes
// Medium-toned colors that are visible and not too flashy in both themes
const CHART_COLORS = [
  "#5B8DEF", // blue - medium tone
  "#4ECDC4", // teal - medium tone
  "#FF8C42", // orange - medium tone
  "#A78BFA", // purple - medium tone
  "#F472B6", // pink - medium tone
  "#38BDF8", // cyan - medium tone
  "#4ADE80", // green - medium tone
  "#FBBF24", // yellow - medium tone
  "#818CF8", // indigo - medium tone
  "#FB7185", // rose - medium tone
  "#2DD4BF", // turquoise - medium tone
  "#C084FC", // violet - medium tone
  "#60A5FA", // sky blue - medium tone
  "#84CC16", // lime - medium tone
  "#F59E0B", // amber - medium tone
  "#A855F7", // purple - medium tone
  "#10B981", // emerald - medium tone
  "#EAB308", // gold - medium tone
  "#3B82F6", // royal blue - medium tone
  "#EF4444", // red - medium tone
];

const chartConfigApps = {
  count: {
    label: "Installations",
    color: "hsl(var(--chart-1))",
  },
} satisfies ChartConfig;

export default function DataPage() {
  const [data, setData] = useState<DataModel[]>([]);
  const [summary, setSummary] = useState<SummaryData | null>(null);
  const [summaryLoading, setSummaryLoading] = useState<boolean>(true);
  const [dataLoading, setDataLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(25);
  const [sortConfig, setSortConfig] = useState<{
    key: string;
    direction: "ascending" | "descending";
  } | null>(null);

  const nf = new Intl.NumberFormat("en-US", { maximumFractionDigits: 0 });

  // Fetch summary only once on mount
  useEffect(() => {
    const fetchSummary = async () => {
      try {
        const summaryRes = await fetch("https://api.htl-braunau.at/data/summary");
        if (!summaryRes.ok) {
          throw new Error(`Failed to fetch summary: ${summaryRes.statusText}`);
        }
        const summaryData: SummaryData = await summaryRes.json();
        setSummary(summaryData);
      } catch (err) {
        setError((err as Error).message);
      } finally {
        setSummaryLoading(false);
      }
    };

    fetchSummary();
  }, []);

  useEffect(() => {
    const fetchData = async () => {
      setDataLoading(true);
      try {
        const dataRes = await fetch(`https://api.htl-braunau.at/data/paginated?page=${currentPage}&limit=${itemsPerPage}`);
        if (!dataRes.ok) {
          throw new Error(`Failed to fetch data: ${dataRes.statusText}`);
        }
        const pageData: DataModel[] = await dataRes.json();
        setData(pageData);
      } catch (err) {
        setError((err as Error).message);
      } finally {
        setDataLoading(false);
      }
    };

    fetchData();
  }, [currentPage, itemsPerPage]);

  const sortedData = useMemo(() => {
    if (!sortConfig) return data;
    return [...data].sort((a, b) => {
      if (a[sortConfig.key] < b[sortConfig.key]) {
        return sortConfig.direction === "ascending" ? -1 : 1;
      }
      if (a[sortConfig.key] > b[sortConfig.key]) {
        return sortConfig.direction === "ascending" ? 1 : -1;
      }
      return 0;
    });
  }, [data, sortConfig]);

  const requestSort = (key: string) => {
    let direction: "ascending" | "descending" = "ascending";
    if (sortConfig && sortConfig.key === key && sortConfig.direction === "ascending") {
      direction = "descending";
    }
    setSortConfig({ key, direction });
  };

  const formatDate = (dateString: string): string => {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat("en-US", {
      dateStyle: "medium",
      timeStyle: "short",
    }).format(date);
  };

  const getTypeBadge = (type: string) => {
    if (type === "lxc") return formattedBadge("ct");
    if (type === "vm") return formattedBadge("vm");
    return null;
  };

  // Stats calculations
  const successCount = summary?.status_count.done ?? 0;
  const failureCount = summary?.status_count.failed ?? 0;
  const totalCount = summary?.total_entries ?? 0;
  const successRate = totalCount > 0 ? (successCount / totalCount) * 100 : 0;

  const allApps = useMemo(() => {
    if (!summary?.nsapp_count) return [];
    return Object.entries(summary.nsapp_count).sort(([, a], [, b]) => b - a);
  }, [summary]);

  const topApps = useMemo(() => {
    return allApps.slice(0, 15);
  }, [allApps]);

  const mostPopularApp = topApps[0];

  // Chart Data
  const appsChartData = topApps.map(([name, count], index) => ({
    app: name,
    count,
    fill: CHART_COLORS[index % CHART_COLORS.length],
  }));

  if (error) {
    return (
      <div className="p-6 text-center text-red-500">
        <p>
          Error loading data:
          {error}
        </p>
      </div>
    );
  }

  return (
    <div className="mb-3">
      <div className="mt-20 flex sm:px-4 xl:px-0">
        <div className="mx-4 w-full sm:mx-0 space-y-8">
          {/* Header */}
          <div>
            <h1 className="text-3xl font-bold tracking-tight">Analytics</h1>
            <p className="text-muted-foreground">Overview of container installations and system statistics.</p>
          </div>

          {/* Widgets */}
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Total Created</CardTitle>
                <Box className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{nf.format(totalCount)}</div>
                <p className="text-xs text-muted-foreground">Total LXC/VM entries found</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Success Rate</CardTitle>
                <CheckCircle2 className="h-4 w-4 text-green-500" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{successRate.toFixed(1)}%</div>
                <p className="text-xs text-muted-foreground">{nf.format(successCount)} successful installations</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Failures</CardTitle>
                <XCircle className="h-4 w-4 text-red-500" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{nf.format(failureCount)}</div>
                <p className="text-xs text-muted-foreground">Installations encountered errors</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Most Popular</CardTitle>
                <Trophy className="h-4 w-4 text-yellow-500" />
              </CardHeader>
              <CardContent>
                <div className="truncate text-2xl font-bold">{mostPopularApp ? mostPopularApp[0] : "N/A"}</div>
                <p className="text-xs text-muted-foreground">
                  {mostPopularApp ? nf.format(mostPopularApp[1]) : 0} installations
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Graphs */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <div className="space-y-1.5">
                <CardTitle>Top Applications</CardTitle>
                <CardDescription>The most frequently installed applications.</CardDescription>
              </div>
              <Dialog>
                <DialogTrigger asChild>
                  <Button variant="outline" size="sm" className="ml-auto">
                    <List className="mr-2 h-4 w-4" />
                    View All
                  </Button>
                </DialogTrigger>
                <DialogContent className="max-h-[80vh] sm:max-w-md">
                  <DialogHeader>
                    <DialogTitle>Application Statistics</DialogTitle>
                    <DialogDescription>Installation counts for all {allApps.length} applications.</DialogDescription>
                  </DialogHeader>
                  <ScrollArea className="h-[60vh] w-full rounded-md border p-4">
                    <div className="space-y-4">
                      {allApps.map(([name, count], index) => (
                        <div key={name} className="flex items-center justify-between text-sm">
                          <div className="flex items-center gap-2">
                            <span className="w-8 font-mono text-muted-foreground">{index + 1}.</span>
                            <span className="font-medium">{name}</span>
                          </div>
                          <span className="font-mono">{nf.format(count)}</span>
                        </div>
                      ))}
                    </div>
                  </ScrollArea>
                </DialogContent>
              </Dialog>
            </CardHeader>
            <CardContent className="pl-2">
              <div className="h-[300px] w-full">
                {summaryLoading ? (
                  <div className="flex h-full w-full items-center justify-center">
                    <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                  </div>
                ) : (
                  <ChartContainer config={chartConfigApps} className="h-full w-full">
                    <BarChart
                      accessibilityLayer
                      data={appsChartData}
                      margin={{
                        top: 20,
                      }}
                    >
                      <CartesianGrid vertical={false} />
                      <XAxis
                        dataKey="app"
                        tickLine={false}
                        tickMargin={10}
                        axisLine={false}
                        tickFormatter={(value) => (value.length > 8 ? `${value.slice(0, 8)}...` : value)}
                      />
                      <ChartTooltip cursor={false} content={<ChartTooltipContent nameKey="app" />} />
                      <Bar dataKey="count" radius={8}>
                        {appsChartData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry.fill} />
                        ))}
                        <LabelList position="top" offset={12} className="fill-foreground" fontSize={12} />
                      </Bar>
                    </BarChart>
                  </ChartContainer>
                )}
              </div>
            </CardContent>
          </Card>

          {/* Data Table */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <div>
                <CardTitle>Installation Log</CardTitle>
                <CardDescription>Detailed records of all container creation attempts.</CardDescription>
              </div>
              <div className="flex items-center gap-2">
                <Select value={String(itemsPerPage)} onValueChange={(val) => setItemsPerPage(Number(val))}>
                  <SelectTrigger className="w-[80px]">
                    <SelectValue placeholder="Limit" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="10">10</SelectItem>
                    <SelectItem value="25">25</SelectItem>
                    <SelectItem value="50">50</SelectItem>
                    <SelectItem value="100">100</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardHeader>
            <CardContent>
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="w-[100px] cursor-pointer" onClick={() => requestSort("status")}>
                        Status
                        {sortConfig?.key === "status" && <ArrowUpDown className="ml-2 inline h-4 w-4" />}
                      </TableHead>
                      <TableHead className="cursor-pointer" onClick={() => requestSort("type")}>
                        Type
                        {sortConfig?.key === "type" && <ArrowUpDown className="ml-2 inline h-4 w-4" />}
                      </TableHead>
                      <TableHead className="cursor-pointer" onClick={() => requestSort("nsapp")}>
                        Application
                        {sortConfig?.key === "nsapp" && <ArrowUpDown className="ml-2 inline h-4 w-4" />}
                      </TableHead>
                      <TableHead className="hidden cursor-pointer md:table-cell" onClick={() => requestSort("os_type")}>
                        OS
                        {sortConfig?.key === "os_type" && <ArrowUpDown className="ml-2 inline h-4 w-4" />}
                      </TableHead>
                      <TableHead
                        className="hidden cursor-pointer md:table-cell"
                        onClick={() => requestSort("disk_size")}
                      >
                        Disk Size
                        {sortConfig?.key === "disk_size" && <ArrowUpDown className="ml-2 inline h-4 w-4" />}
                      </TableHead>
                      <TableHead
                        className="hidden cursor-pointer lg:table-cell"
                        onClick={() => requestSort("core_count")}
                      >
                        Core Count
                        {sortConfig?.key === "core_count" && <ArrowUpDown className="ml-2 inline h-4 w-4" />}
                      </TableHead>
                      <TableHead
                        className="hidden cursor-pointer lg:table-cell"
                        onClick={() => requestSort("ram_size")}
                      >
                        RAM Size
                        {sortConfig?.key === "ram_size" && <ArrowUpDown className="ml-2 inline h-4 w-4" />}
                      </TableHead>
                      <TableHead className="cursor-pointer text-right" onClick={() => requestSort("created_at")}>
                        Created At
                        {sortConfig?.key === "created_at" && <ArrowUpDown className="ml-2 inline h-4 w-4" />}
                      </TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {dataLoading ? (
                      <TableRow>
                        <TableCell colSpan={8} className="h-24 text-center">
                          <div className="flex items-center justify-center gap-2">
                            <Loader2 className="h-4 w-4 animate-spin" /> Loading data...
                          </div>
                        </TableCell>
                      </TableRow>
                    ) : sortedData.length > 0 ? (
                      sortedData.map((item, idx) => (
                        <TableRow key={`${item.id}-${idx}`}>
                          <TableCell>
                            {item.status === "done" ? (
                              <Badge className="text-green-500/75 border-green-500/75">Success</Badge>
                            ) : item.status === "failed" ? (
                              <TooltipProvider>
                                <Tooltip>
                                  <TooltipTrigger asChild>
                                    <Badge className="text-red-500/75 border-red-500/75 cursor-help">Failed</Badge>
                                  </TooltipTrigger>
                                  <TooltipContent className="max-w-xs">
                                    <p className="font-semibold">Error:</p>
                                    <p className="text-sm">{item.error || "Unknown error"}</p>
                                  </TooltipContent>
                                </Tooltip>
                              </TooltipProvider>
                            ) : item.status === "installing" ? (
                              <Badge className="text-blue-500/75 border-blue-500/75">Installing</Badge>
                            ) : (
                              <Badge variant="outline">{item.status}</Badge>
                            )}
                          </TableCell>
                          <TableCell>
                            {getTypeBadge(item.type) || <Badge variant="outline">{item.type}</Badge>}
                          </TableCell>
                          <TableCell className="font-medium">{item.nsapp}</TableCell>
                          <TableCell className="hidden md:table-cell">
                            {item.os_type} {item.os_version}
                          </TableCell>
                          <TableCell className="hidden md:table-cell">
                            {item.disk_size}
                            GB
                          </TableCell>
                          <TableCell className="hidden lg:table-cell">{item.core_count}</TableCell>
                          <TableCell className="hidden lg:table-cell">
                            {item.ram_size}
                            MB
                          </TableCell>
                          <TableCell className="text-right">{formatDate(item.created_at)}</TableCell>
                        </TableRow>
                      ))
                    ) : (
                      <TableRow>
                        <TableCell colSpan={8} className="h-24 text-center">
                          No results found.
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </div>

              <div className="flex items-center justify-end space-x-2 py-4">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setCurrentPage((prev) => Math.max(prev - 1, 1))}
                  disabled={currentPage === 1 || dataLoading}
                >
                  <ChevronLeft className="mr-2 h-4 w-4" />
                  Previous
                </Button>
                <div className="text-sm text-muted-foreground">Page {currentPage}</div>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setCurrentPage((prev) => prev + 1)}
                  disabled={dataLoading || sortedData.length < itemsPerPage}
                >
                  Next
                  <ChevronRight className="ml-2 h-4 w-4" />
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
