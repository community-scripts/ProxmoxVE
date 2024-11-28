import { vi } from "vitest";

// Mock canvas getContext
HTMLCanvasElement.prototype.getContext = vi.fn();