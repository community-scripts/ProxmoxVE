"use client";

import React, { useEffect, useState } from "react";
import "react-datepicker/dist/react-datepicker.css";

import ApplicationChart from "../../components/application-chart";

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

const DataFetcher: React.FC = () => {
  const [data, setData] = useState<DataModel[]>([]);
  const [summary, setSummary] = useState<SummaryData | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(25);
  const [sortConfig, setSortConfig] = useState<{ key: string; direction: "ascending" | "descending" } | null>(null);
  const nf = new Intl.NumberFormat("en-US", { maximumFractionDigits: 0 });

  useEffect(() => {
    const fetchSummary = async () => {
      try {
        const response = await fetch("https://api.htl-braunau.at/data/summary");
        if (!response.ok)
          throw new Error(`Failed to fetch summary: ${response.statusText}`);
        const result: SummaryData = await response.json();
        setSummary(result);
      }
      catch (err) {
        setError((err as Error).message);
      }
    };

    fetchSummary();
  }, []);

  useEffect(() => {
    const fetchPaginatedData = async () => {
      setLoading(true);
      try {
        const response = await fetch(`https://api.htl-braunau.at/data/paginated?page=${currentPage}&limit=${itemsPerPage === 0 ? "" : itemsPerPage}`);
        if (!response.ok)
          throw new Error(`Failed to fetch data: ${response.statusText}`);
        const result: DataModel[] = await response.json();
        setData(result);
      }
      catch (err) {
        setError((err as Error).message);
      }
      finally {
        setLoading(false);
      }
    };

    fetchPaginatedData();
  }, [currentPage, itemsPerPage]);

  const sortedData = React.useMemo(() => {
    if (!sortConfig)
      return data;
    const sorted = [...data].sort((a, b) => {
      if (a[sortConfig.key] < b[sortConfig.key]) {
        return sortConfig.direction === "ascending" ? -1 : 1;
      }
      if (a[sortConfig.key] > b[sortConfig.key]) {
        return sortConfig.direction === "ascending" ? 1 : -1;
      }
      return 0;
    });
    return sorted;
  }, [data, sortConfig]);

  if (loading)
    return <p>Loading...</p>;
  if (error) {
    return (
      <p>
        Error:
        {error}
      </p>
    );
  }

  const requestSort = (key: string) => {
    let direction: "ascending" | "descending" = "ascending";
    if (sortConfig && sortConfig.key === key && sortConfig.direction === "ascending") {
      direction = "descending";
    }
    setSortConfig({ key, direction });
  };

  const formatDate = (dateString: string): string => {
    const date = new Date(dateString);
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const hours = String(date.getHours()).padStart(2, "0");
    const minutes = String(date.getMinutes()).padStart(2, "0");
    const timezoneOffset = dateString.slice(-6);
    return `${day}.${month}.${year} ${hours}:${minutes} ${timezoneOffset} GMT`;
  };

  return (
    <div className="p-6 mt-20">
      <h1 className="text-2xl font-bold mb-4 text-center">Created LXCs</h1>
      <ApplicationChart data={summary} />
      <p className="text-lg font-bold mt-4"> </p>
      <div className="mb-4 flex justify-between items-center">
        <p className="text-lg font-bold">
          {nf.format(
            summary?.total_entries ?? 0,
          )}
          {" "}
          results found
        </p>
        <p className="text-lg font">
          Status Legend: 🔄 installing
          {" "}
          {nf.format(summary?.status_count.installing ?? 0)}
          {" "}
          | ✔️ completed
          {" "}
          {nf.format(summary?.status_count.done ?? 0)}
          {" "}
          | ❌ failed
          {" "}
          {nf.format(summary?.status_count.failed ?? 0)}
          {" "}
          | ❓ unknown
        </p>
      </div>
      <div className="overflow-x-auto">
        <div className="overflow-y-auto lg:overflow-y-visible">
          <table className="min-w-full table-auto border-collapse">
            <thead>
              <tr>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort("status")}>Status</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort("type")}>Type</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort("nsapp")}>Application</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort("os_type")}>OS</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort("os_version")}>OS Version</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort("disk_size")}>Disk Size</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort("core_count")}>Core Count</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort("ram_size")}>RAM Size</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort("method")}>Method</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort("pve_version")}>PVE Version</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort("error")}>Error Message</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort("created_at")}>Created At</th>
              </tr>
            </thead>
            <tbody>
              {sortedData.map((item, index) => (
                <tr key={index}>
                  <td className="px-4 py-2 border-b">
                    {item.status === "done"
                      ? (
                          "✔️"
                        )
                      : item.status === "failed"
                        ? (
                            "❌"
                          )
                        : item.status === "installing"
                          ? (
                              "🔄"
                            )
                          : (
                              item.status
                            )}
                  </td>
                  <td className="px-4 py-2 border-b">
                    {item.type === "lxc"
                      ? (
                          "📦"
                        )
                      : item.type === "vm"
                        ? (
                            "🖥️"
                          )
                        : (
                            item.type
                          )}
                  </td>
                  <td className="px-4 py-2 border-b">{item.nsapp}</td>
                  <td className="px-4 py-2 border-b">{item.os_type}</td>
                  <td className="px-4 py-2 border-b">{item.os_version}</td>
                  <td className="px-4 py-2 border-b">{item.disk_size}</td>
                  <td className="px-4 py-2 border-b">{item.core_count}</td>
                  <td className="px-4 py-2 border-b">{item.ram_size}</td>
                  <td className="px-4 py-2 border-b">{item.method}</td>
                  <td className="px-4 py-2 border-b">{item.pve_version}</td>
                  <td className="px-4 py-2 border-b">{item.error}</td>
                  <td className="px-4 py-2 border-b">{formatDate(item.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
      <div className="mt-4 flex justify-between items-center">
        <button onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))} disabled={currentPage === 1} className="p-2 border">Previous</button>
        <span>
          Page
          {currentPage}
        </span>
        <button onClick={() => setCurrentPage(prev => prev + 1)} className="p-2 border">Next</button>
        <select
          value={itemsPerPage}
          onChange={e => setItemsPerPage(Number(e.target.value))}
          className="p-2 border"
        >
          <option value={10}>10</option>
          <option value={20}>20</option>
          <option value={50}>50</option>
          <option value={100}>100</option>
          <option value={250}>250</option>
          <option value={500}>500</option>
          <option value={5000}>5000</option>
        </select>
      </div>
    </div>
  );
};

export default DataFetcher;
