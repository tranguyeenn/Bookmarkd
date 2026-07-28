// @vitest-environment jsdom

import { act } from "react";
import { createRoot, type Root } from "react-dom/client";
import { MemoryRouter } from "react-router-dom";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { BookLibraryCard } from "@/components/books/BookLibraryCard";
import { recordToApiBook, type BookRecord } from "@/lib/books";

(globalThis as typeof globalThis & { IS_REACT_ACT_ENVIRONMENT: boolean }).IS_REACT_ACT_ENVIRONMENT = true;

const { getSessionMock } = vi.hoisted(() => ({
  getSessionMock: vi.fn()
}));

vi.mock("@/lib/supabase", () => ({
  supabase: {
    auth: {
      getSession: getSessionMock
    }
  }
}));

describe("BookLibraryCard deletion", () => {
  let container: HTMLDivElement;
  let root: Root;
  let fetchMock: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
    root = createRoot(container);
    getSessionMock.mockResolvedValue({
      data: { session: { access_token: "test-token" } },
      error: null
    });
    fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ message: "Book deleted" }), {
        status: 200,
        headers: { "Content-Type": "application/json" }
      })
    );
    vi.stubGlobal("fetch", fetchMock);
    vi.spyOn(window, "confirm").mockReturnValue(true);
  });

  afterEach(() => {
    act(() => {
      root.unmount();
    });
    container.remove();
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it("deletes the serialized ISBN/UID through the real UI handler and API client", async () => {
    const serializedBook: BookRecord = {
      Title: "A Wild Sheep Chase",
      Authors: "Haruki Murakami",
      "ISBN/UID": "9788440630124",
      "Read Status": "to-read",
      "Progress (%)": 0,
      "Pages Read": 0,
      "Total Pages": 320,
      "Tracking Mode": "pages",
      "Star Rating": null,
      "Start Date": null,
      "End Date": null,
      "Cover URL": null,
      Genres: ["Fiction"],
      Subjects: ["Japanese fiction"],
      "First Publish Year": 1982
    };
    const book = recordToApiBook(serializedBook);
    const onDeleted = vi.fn();

    await act(async () => {
      root.render(
        <MemoryRouter>
          <BookLibraryCard book={book} onUpdated={vi.fn()} onDeleted={onDeleted} />
        </MemoryRouter>
      );
    });

    const deleteButton = Array.from(container.querySelectorAll("button")).find(
      (button) => button.textContent === "Delete book"
    );
    expect(deleteButton).toBeTruthy();

    await act(async () => {
      deleteButton?.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    });

    const [url, init] = fetchMock.mock.calls[0];
    expect(new URL(String(url), "http://localhost").pathname).toBe("/books/9788440630124");
    expect(init).toEqual(
      expect.objectContaining({
        method: "DELETE",
        headers: expect.any(Headers)
      })
    );
    expect(onDeleted).toHaveBeenCalledWith("9788440630124");
  });
});
