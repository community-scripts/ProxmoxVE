"use client";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { Chart as ChartJS, ArcElement, Tooltip as ChartTooltip, Legend } from "chart.js";
import ChartDataLabels from "chartjs-plugin-datalabels";
import { BarChart3, PieChart } from "lucide-react";
import React, { useState } from "react";
import { Pie } from "react-chartjs-2";

ChartJS.register(ArcElement, ChartTooltip, Legend, ChartDataLabels);

interface ApplicationChartProps {
  data: { nsapp: string }[];
}

const ITEMS_PER_PAGE = 20;
const CHART_COLORS = [
  "#ff6384",
  "#36a2eb",
  "#ffce56",
  "#4bc0c0",
  "#9966ff",
  "#ff9f40",
  "#4dc9f6",
  "#f67019",
  "#537bc4",
  "#acc236",
  "#166a8f",
  "#00a950",
  "#58595b",
  "#8549ba",
];

export default function ApplicationChart({ data }: ApplicationChartProps) {
  const [isChartOpen, setIsChartOpen] = useState(false);
  const [isTableOpen, setIsTableOpen] = useState(false);
  const [chartStartIndex, setChartStartIndex] = useState(0);
  const [tableLimit, setTableLimit] = useState(ITEMS_PER_PAGE);

  // Calculate application counts
  const appCounts = data.reduce((acc, item) => {
    acc[item.nsapp] = (acc[item.nsapp] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  const sortedApps = Object.entries(appCounts)
    .sort(([, a], [, b]) => b - a);

  const chartApps = sortedApps.slice(
    chartStartIndex,
    chartStartIndex + ITEMS_PER_PAGE
  );

  const chartData = {
    labels: chartApps.map(([name]) => name),
    datasets: [
      {
        data: chartApps.map(([, count]) => count),
        backgroundColor: CHART_COLORS,
      },
    ],
  };

  const chartOptions = {
    plugins: {
      legend: { display: false },
      datalabels: {
        color: "white",
        font: { weight: "bold" as const },
        formatter: (value: number, context: any) => {
          const label = context.chart.data.labels?.[context.dataIndex];
          return `${label}\n(${value})`;
        },
      },
    },
    responsive: true,
    maintainAspectRatio: false,
  };

  return (
    <div className="mt-6 flex justify-center gap-4">
      <TooltipProvider>
        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant="outline"
              size="icon"
              onClick={() => setIsChartOpen(true)}
            >
              <PieChart className="h-5 w-5" />
            </Button>
          </TooltipTrigger>
          <TooltipContent>Open Chart View</TooltipContent>
        </Tooltip>

        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant="outline"
              size="icon"
              onClick={() => setIsTableOpen(true)}
            >
              <BarChart3 className="h-5 w-5" />
            </Button>
          </TooltipTrigger>
          <TooltipContent>Open Table View</TooltipContent>
        </Tooltip>
      </TooltipProvider>

      <Dialog open={isChartOpen} onOpenChange={setIsChartOpen}>
        <DialogContent className="max-w-3xl">
          <DialogHeader>
            <DialogTitle>Applications Distribution</DialogTitle>
          </DialogHeader>
          <div className="h-[60vh] w-full">
            <Pie data={chartData} options={chartOptions} />
          </div>
          <div className="flex justify-center gap-4">
            <Button
              variant="outline"
              onClick={() => setChartStartIndex(Math.max(0, chartStartIndex - ITEMS_PER_PAGE))}
              disabled={chartStartIndex === 0}
            >
              Previous {ITEMS_PER_PAGE}
            </Button>
            <Button
              variant="outline"
              onClick={() => setChartStartIndex(chartStartIndex + ITEMS_PER_PAGE)}
              disabled={chartStartIndex + ITEMS_PER_PAGE >= sortedApps.length}
            >
              Next {ITEMS_PER_PAGE}
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      <Dialog open={isTableOpen} onOpenChange={setIsTableOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Applications Count</DialogTitle>
          </DialogHeader>
          <div className="max-h-[60vh] overflow-y-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Application</TableHead>
                  <TableHead className="text-right">Count</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {sortedApps.slice(0, tableLimit).map(([name, count]) => (
                  <TableRow key={name}>
                    <TableCell>{name}</TableCell>
                    <TableCell className="text-right">{count}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          {tableLimit < sortedApps.length && (
            <Button
              variant="outline"
              className="w-full"
              onClick={() => setTableLimit(prev => prev + ITEMS_PER_PAGE)}
            >
              Load More
            </Button>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}