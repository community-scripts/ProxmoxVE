export function CPUIcon() {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      className="size-4"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={2}
    >
      <rect x="9" y="9" width="6" height="6" />
      <path d="M3 9h2m14 0h2M3 15h2m14 0h2M9 3v2m6-2v2M9 19v2m6-2v2" />
    </svg>
  );
}

export function RAMIcon() {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      className="size-4"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={2}
    >
      <rect x="4" y="6" width="16" height="12" rx="2" ry="2" />
      <path d="M8 6v12M16 6v12" />
    </svg>
  );
}

export function HDDIcon() {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      className="size-4"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={2}
    >
      <path d="M4 4h16v16H4z" />
      <circle cx="8" cy="16" r="1" />
      <circle cx="16" cy="16" r="1" />
    </svg>
  );
}
