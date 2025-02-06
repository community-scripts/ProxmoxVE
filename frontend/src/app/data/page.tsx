"use client";

import React, { useEffect, useState } from "react";
import DatePicker from 'react-datepicker';
import 'react-datepicker/dist/react-datepicker.css';
import ApplicationChart from "../../components/ApplicationChart";

interface DataModel {
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

  const [showErrorRow, setShowErrorRow] = useState<number | null>(null);


  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await fetch("https://api.htl-braunau.at/data/json");
        if (!response.ok) throw new Error("Failed to fetch data: ${response.statusText}");
        const result: DataModel[] = await response.json();
        setData(result);
      } catch (err) {
        setError((err as Error).message);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);


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

  const handleItemsPerPageChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setItemsPerPage(Number(event.target.value));
    setCurrentPage(1);
  };

  const paginatedData = sortedData.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);


  if (loading) return <p>Loading...</p>;
  if (error) return <p>Error: {error}</p>;

  var installingCounts: number = 0;
  var failedCounts: number = 0;
  var doneCounts: number = 0
  var unknownCounts: number = 0;
  data.forEach((item) => {
    if (item.status === "installing") {
      installingCounts += 1;
    } else if (item.status === "failed") {
      failedCounts += 1;
    }
    else if (item.status === "done") {
      doneCounts += 1;
    }
    else {
      unknownCounts += 1;
    }
  });

  return (
    <div className="p-6 mt-20">
      <h1 className="text-2xl font-bold mb-4 text-center">Created LXCs</h1>
      <div className="mb-4 flex space-x-4">
        <div>
          <input
            type="text"
            placeholder="Search..."
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            className="p-2 border"
          />
          <label className="text-sm text-gray-600 mt-1 block">Search by keyword</label>
        </div>
        <div>
          <DatePicker
            selected={startDate}
            onChange={date => setStartDate(date)}
            selectsStart
            startDate={startDate}
            endDate={endDate}
            placeholderText="Start date"
            className="p-2 border"
          />
          <label className="text-sm text-gray-600 mt-1 block">Set a start date</label>
        </div>

        <div>
          <DatePicker
            selected={endDate}
            onChange={date => setEndDate(date)}
            selectsEnd
            startDate={startDate}
            endDate={endDate}
            placeholderText="End date"
            className="p-2 border"
          />
          <label className="text-sm text-gray-600 mt-1 block">Set a end date</label>
        </div>
      </div>
      <ApplicationChart data={filteredData} />
      <div className="mb-4 flex justify-between items-center">
        <p className="text-lg font-bold">{filteredData.length} results found</p>
        <p className="text-lg font">Status Legend: 🔄 installing {installingCounts} | ✔️ completetd {doneCounts} | ❌ failed {failedCounts} | ❓ unknown {unknownCounts}</p>
        <select value={itemsPerPage} onChange={handleItemsPerPageChange} className="p-2 border">
          <option value={25}>25</option>
          <option value={50}>50</option>
          <option value={100}>100</option>
          <option value={200}>200</option>
        </select>
      </div>
      <div className="overflow-x-auto">
        <div className="overflow-y-auto lg:overflow-y-visible">
          <table className="min-w-full table-auto border-collapse">
            <thead>
              <tr>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('status')}>Status</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('type')}>Type</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('nsapp')}>Application</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('os_type')}>OS</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('os_version')}>OS Version</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('disk_size')}>Disk Size</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('core_count')}>Core Count</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('ram_size')}>RAM Size</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('method')}>Method</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('pve_version')}>PVE Version</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('error')}>Error Message</th>
                <th className="px-4 py-2 border-b cursor-pointer" onClick={() => requestSort('created_at')}>Created At</th>
              </tr>
            </thead>
            <tbody>
              {paginatedData.map((item, index) => (
                <tr key={index}>
                  <td className="px-4 py-2 border-b">
                    {item.status === "done" ? (
                      "✔️"
                    ) : item.status === "failed" ? (
                      "❌"
                    ) : item.status === "installing" ? (
                      "🔄"
                    ) : (
                      item.status
                    )}
                  </td>
                  <td className="px-4 py-2 border-b">{item.type === "lxc" ? (
                    "📦"
                  ) : item.type === "vm" ? (
                    "🖥️"
                  ) : (
                    item.type
                  )}</td>
                  <td className="px-4 py-2 border-b">{item.nsapp}</td>
                  <td className="px-4 py-2 border-b">{item.os_type}</td>
                  <td className="px-4 py-2 border-b">{item.os_version}</td>
                  <td className="px-4 py-2 border-b">{item.disk_size}</td>
                  <td className="px-4 py-2 border-b">{item.core_count}</td>
                  <td className="px-4 py-2 border-b">{item.ram_size}</td>
                  <td className="px-4 py-2 border-b">{item.method}</td>
                  <td className="px-4 py-2 border-b">{item.pve_version}</td>
                  <td className="px-4 py-2 border-b">
                    {item.error && item.error !== "none" ? (
                      showErrorRow === index ? (
                        <>
                          {item.error}
                          <button onClick={() => setShowErrorRow(null)}>{item.error}</button>
                        </>
                      ) : (
                        <button onClick={() => setShowErrorRow(index)}>Click to show error</button>
                      )
                    ) : (
                      "none"
                    )}
                  </td>
                  <td className="px-4 py-2 border-b">{formatDate(item.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
      <div className="mt-4 flex justify-between items-center">
        <button
          onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
          disabled={currentPage === 1}
          className="p-2 border"
        >
          Previous
        </button>
        <span>Page {currentPage}</span>
        <button
          onClick={() => setCurrentPage(prev => (prev * itemsPerPage < sortedData.length ? prev + 1 : prev))}
          disabled={currentPage * itemsPerPage >= sortedData.length}
          className="p-2 border"
        >
          Next
        </button>
      </div>
    </div>
  );
};



export default DataFetcher;
