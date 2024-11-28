import { screen } from "@testing-library/dom";
import { render } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Page from "@/app/page";

describe("Page", () => {
  it("should show button to view scripts", () => {
    render(<Page />);
    expect(screen.getByRole("button", { name: "View Scripts" })).toBeDefined();
  });
});
