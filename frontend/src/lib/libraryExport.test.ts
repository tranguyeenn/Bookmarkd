import { beforeEach, describe, expect, it, vi } from "vitest";

const fetchJsonMock = vi.fn();
const assertDemoWritableMock = vi.fn();

vi.mock("@/lib/api", () => ({
  apiFetch: vi.fn(),
  fetchJson: fetchJsonMock,
  getApiErrorMessage: vi.fn()
}));

vi.mock("@/lib/demoMode", () => ({
  assertDemoWritable: assertDemoWritableMock
}));

describe("library export API helpers", () => {
  beforeEach(() => {
    fetchJsonMock.mockReset();
    assertDemoWritableMock.mockReset();
  });

  it("deletes books by encoded ISBN/UID path", async () => {
    fetchJsonMock.mockResolvedValue({ message: "Book deleted" });
    const { deleteBook } = await import("@/lib/libraryExport");

    await deleteBook("9788440630124");

    expect(assertDemoWritableMock).toHaveBeenCalledOnce();
    expect(fetchJsonMock).toHaveBeenCalledWith("/books/9788440630124", {
      method: "DELETE"
    });
  });

  it("encodes ISBN/UID values before placing them in the route", async () => {
    fetchJsonMock.mockResolvedValue({ message: "Book deleted" });
    const { deleteBook } = await import("@/lib/libraryExport");

    await deleteBook("isbn/value with spaces");

    expect(fetchJsonMock).toHaveBeenCalledWith("/books/isbn%2Fvalue%20with%20spaces", {
      method: "DELETE"
    });
  });
});
