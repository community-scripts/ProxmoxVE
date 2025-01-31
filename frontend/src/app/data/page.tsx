"use client";

import ApplicationChart from "@/components/ApplicationChart";
import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { format } from "date-fns";
import { Calendar as CalendarIcon } from "lucide-react";
import React, { useCallback, useEffect, useState } from "react";

interface DataModel {
  id: number;
  ct_type: number;
  disk_size: number;
  core_count: number;
  ram_size: number;
  verbose: string;
  os_type: string;
  os_version: string;
  hn: string;
  disableip6: string;
  ssh: string;
  tags: string;
  nsapp: string;
  created_at: string;
  method: string;
  pve_version: string;
  status: string;
}


const DataFetcher: React.FC = () => {
  const [data, setData] = useState<DataModel[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [startDate, setStartDate] = useState<Date | null>(null);
  const [endDate, setEndDate] = useState<Date | null>(null);
  const [sortConfig, setSortConfig] = useState<{ key: keyof DataModel | null, direction: 'ascending' | 'descending' }>({ key: 'id', direction: 'descending' });
  const [itemsPerPage, setItemsPerPage] = useState(25);
  const [currentPage, setCurrentPage] = useState(1);
  const [interval, setIntervalTime] = useState<number>(10); // Default interval 10 seconds
  const [reloadInterval, setReloadInterval] = useState<NodeJS.Timeout | null>(null);


  const fetchData = useCallback(async () => {
    try {
      const response = await fetch("https://api.htl-braunau.at/data/json");
      if (!response.ok) throw new Error(`Failed to fetch data: ${response.statusText}`);
      const result: DataModel[] = await response.json();
      setData(result);
      setLoading(false);
    } catch (err) {
      setError((err as Error).message);
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
    const storedInterval = localStorage.getItem('reloadInterval');
    if (storedInterval) {
      setIntervalTime(Number(storedInterval));
    }
  }, [fetchData]);

  useEffect(() => {
    let intervalId: NodeJS.Timeout | null = null;
    
    if (interval > 0) {
      intervalId = setInterval(fetchData, Math.max(interval, 10) * 1000);
      localStorage.setItem('reloadInterval', interval.toString());
    } else {
      localStorage.removeItem('reloadInterval');
    }

    return () => {
      if (intervalId) clearInterval(intervalId);
    };
  }, [interval, fetchData]);

  const filteredData = data.filter(item => {
    const matchesSearchQuery = Object.values(item).some(value =>
      value.toString().toLowerCase().includes(searchQuery.toLowerCase())
    );
    const itemDate = new Date(item.created_at);
    const matchesDateRange = (!startDate || itemDate >= startDate) && (!endDate || itemDate <= endDate);
    return matchesSearchQuery && matchesDateRange;
  });

  const sortedData = React.useMemo(() => {
    let sortableData = [...filteredData];
    if (sortConfig.key !== null) {
      sortableData.sort((a, b) => {
        if (sortConfig.key !== null && a[sortConfig.key] < b[sortConfig.key]) {
          return sortConfig.direction === 'ascending' ? -1 : 1;
        }
        if (sortConfig.key !== null && a[sortConfig.key] > b[sortConfig.key]) {
          return sortConfig.direction === 'ascending' ? 1 : -1;
        }
        return 0;
      });
    }
    return sortableData;
  }, [filteredData, sortConfig]);

  const requestSort = (key: keyof DataModel | null) => {
    let direction: 'ascending' | 'descending' = 'ascending';
    if (sortConfig.key === key && sortConfig.direction === 'ascending') {
      direction = 'descending';
    } else if (sortConfig.key === key && sortConfig.direction === 'descending') {
      direction = 'ascending';
    } else {
      direction = 'descending';
    }
    setSortConfig({ key, direction });
  };

  interface SortConfig {
    key: keyof DataModel | null;
    direction: 'ascending' | 'descending';
  }

  const formatDate = (dateString: string): string => {
    const date = new Date(dateString);
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const timezoneOffset = dateString.slice(-6);
    return `${day}.${month}.${year} ${hours}:${minutes} ${timezoneOffset} GMT`;
  };

  const paginatedData = sortedData.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);

  const statusCounts = data.reduce((acc, item) => {
    const status = item.status;
    acc[status] = (acc[status] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  if (loading) return <div className="flex justify-center items-center h-screen">Loading...</div>;
  if (error) return <div className="flex justify-center items-center h-screen text-red-500">Error: {error}</div>;

  return (
    <div className="container mx-auto p-6 pt-20 space-y-6">
      <h1 className="text-3xl font-bold text-center">Created LXCs</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Search</CardTitle>
          </CardHeader>
          <CardContent>
            <Input
              placeholder="Search..."
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
            />
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Start Date</CardTitle>
          </CardHeader>
          <CardContent>
            <Popover>
              <PopoverTrigger asChild>
                <Button variant="outline" className="w-full justify-start text-left font-normal">
                  <CalendarIcon className="mr-2 h-4 w-4" />
                  {startDate ? format(startDate, "PPP") : "Pick a date"}
                </Button>
              </PopoverTrigger>
              <PopoverContent className="w-auto p-0">
                <Calendar
                  mode="single"
                  selected={startDate || undefined}
                  onSelect={(date: Date | undefined) => setStartDate(date || null)}
                  initialFocus
                />
              </PopoverContent>
            </Popover>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">End Date</CardTitle>
          </CardHeader>
          <CardContent>
            <Popover>
              <PopoverTrigger asChild>
                <Button variant="outline" className="w-full justify-start text-left font-normal">
                  <CalendarIcon className="mr-2 h-4 w-4" />
                  {endDate ? format(endDate, "PPP") : "Pick a date"}
                </Button>
              </PopoverTrigger>
              <PopoverContent className="w-auto p-0">
                <Calendar
                  mode="single"
                  selected={endDate || undefined}
                  onSelect={(date: Date | undefined) => setEndDate(date || null)}
                  initialFocus
                />
              </PopoverContent>
            </Popover>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Reload Interval</CardTitle>
          </CardHeader>
          <CardContent>
            <Input
              type="number"
              value={interval}
              onChange={e => setIntervalTime(Number(e.target.value))}
              placeholder="Interval (seconds)"
            />
          </CardContent>
        </Card>
      </div>

      <ApplicationChart data={filteredData} />

      <div className="flex justify-between items-center">
        <p className="text-lg font-medium">{filteredData.length} results found</p>
        <div className="flex gap-2 items-center">
          <span>🔄 Installing: {statusCounts.installing || 0}</span>
          <span>✔️ Completed: {statusCounts.done || 0}</span>
          <span>❌ Failed: {statusCounts.failed || 0}</span>
          <span>❓ Unknown: {statusCounts.unknown || 0}</span>
        </div>
        <Select value={itemsPerPage.toString()} onValueChange={(value) => setItemsPerPage(Number(value))}>
          <SelectTrigger className="w-[180px]">
            <SelectValue placeholder="Items per page" />
          </SelectTrigger>
          <SelectContent>
            {[25, 50, 100, 200].map(value => (
              <SelectItem key={value} value={value.toString()}>
                {value} items
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('status')}>Status</TableHead>
              <TableHead className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('nsapp')}>Application</TableHead>
              <TableHead className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('os_type')}>OS</TableHead>
              <TableHead className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('os_version')}>OS Version</TableHead>
              <TableHead className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('disk_size')}>Disk Size</TableHead>
              <TableHead className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('core_count')}>Core Count</TableHead>
              <TableHead className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('ram_size')}>RAM Size</TableHead>
              <TableHead className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('hn')}>Hostname</TableHead>
              <TableHead className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('ssh')}>SSH</TableHead>
              <TableHead className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('verbose')}>Verb</TableHead>
              <TableHead className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('tags')}>Tags</TableHead>
              <TableHead className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('method')}>Method</TableHead>
              <TableHead className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('pve_version')}>PVE Version</TableHead>
              <TableHead className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('created_at')}>Created At</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {paginatedData.map((item, index) => (
              <TableRow key={index}>
                <TableCell className="px-4 py-2 border-b">{item.status === "done" ? (
                  "✔️"
                ) : item.status === "failed" ? (
                  "❌"
                ) : item.status === "installing" ? (
                  "🔄"  
                ) : (
                  item.status
                )}</TableCell>
                <TableCell className="px-4 py-2 border-b">{item.nsapp}</TableCell>
                <TableCell className="px-4 py-2 border-b">{item.os_type}</TableCell>
                <TableCell className="px-4 py-2 border-b">{item.os_version}</TableCell>
                <TableCell className="px-4 py-2 border-b">{item.disk_size}</TableCell>
                <TableCell className="px-4 py-2 border-b">{item.core_count}</TableCell>
                <TableCell className="px-4 py-2 border-b">{item.ram_size}</TableCell>
                <TableCell className="px-4 py-2 border-b">{item.hn}</TableCell>
                <TableCell className="px-4 py-2 border-b">{item.ssh}</TableCell>
                <TableCell className="px-4 py-2 border-b">{item.verbose}</TableCell>
                <TableCell className="px-4 py-2 border-b">{item.tags.replace(/;/g, ' ')}</TableCell>
                <TableCell className="px-4 py-2 border-b">{item.method}</TableCell>
                <TableCell className="px-4 py-2 border-b">{item.pve_version}</TableCell>
                <TableCell className="px-4 py-2 border-b">{formatDate(item.created_at)}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      <div className="flex items-center justify-center space-x-2">
        <Button
          variant="outline"
          onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
          disabled={currentPage === 1}
        >
          Previous
        </Button>
        <span className="text-sm">
          Page {currentPage} of {Math.ceil(sortedData.length / itemsPerPage)}
        </span>
        <Button
          variant="outline"
          onClick={() => setCurrentPage(prev => (prev * itemsPerPage < sortedData.length ? prev + 1 : prev))}
          disabled={currentPage * itemsPerPage >= sortedData.length}
        >
          Next
        </Button>
      </div>
    </div>
  );
};

export default DataFetcher;
