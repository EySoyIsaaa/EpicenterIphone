import { describe, expect, it, vi } from "vitest";
import {
  createSerialExecutor,
  loadEveryLibraryPage,
  shuffleKeepingCurrentFirst,
  uniqueItemsById,
} from "../client/src/hooks/audioQueueUtils";

describe("createSerialExecutor", () => {
  it("runs complete async mutations in order", async () => {
    const enqueue = createSerialExecutor();
    const events: string[] = [];
    let releaseFirst: (() => void) | undefined;

    const first = enqueue(async () => {
      events.push("first:start");
      await new Promise<void>((resolve) => {
        releaseFirst = resolve;
      });
      events.push("first:end");
      return 1;
    });
    const second = enqueue(async () => {
      events.push("second");
      return 2;
    });

    await Promise.resolve();
    expect(events).toEqual(["first:start"]);
    releaseFirst?.();
    await expect(Promise.all([first, second])).resolves.toEqual([1, 2]);
    expect(events).toEqual(["first:start", "first:end", "second"]);
  });

  it("continues after a rejected mutation", async () => {
    const enqueue = createSerialExecutor();
    const failed = enqueue(async () => {
      throw new Error("native write failed");
    });
    const recovered = enqueue(async () => "recovered");

    await expect(failed).rejects.toThrow("native write failed");
    await expect(recovered).resolves.toBe("recovered");
  });
});

describe("loadEveryLibraryPage", () => {
  it("loads every native page beyond the 500-row database page size", async () => {
    const source = Array.from({ length: 1_205 }, (_, index) => ({
      id: `track-${index}`,
    }));
    const fetchPage = vi.fn(async (offset: number, limit: number) => ({
      tracks: source.slice(offset, offset + limit),
      total: source.length,
    }));

    const result = await loadEveryLibraryPage(fetchPage, 500);

    expect(result).toHaveLength(1_205);
    expect(fetchPage.mock.calls).toEqual([
      [0, 500],
      [500, 500],
      [1_000, 500],
    ]);
  });

  it("deduplicates boundary rows and stops safely on an unexpected empty page", async () => {
    const fetchPage = vi
      .fn()
      .mockResolvedValueOnce({
        tracks: [{ id: "a" }, { id: "b" }],
        total: 10,
      })
      .mockResolvedValueOnce({
        tracks: [{ id: "b" }, { id: "c" }],
        total: 10,
      })
      .mockResolvedValueOnce({ tracks: [], total: 10 });

    const result = await loadEveryLibraryPage(fetchPage, 2);

    expect(result.map((track) => track.id)).toEqual(["a", "b", "c"]);
    expect(fetchPage).toHaveBeenCalledTimes(3);
  });
});

describe("shuffleKeepingCurrentFirst", () => {
  it("keeps the playing track first and returns every track exactly once", () => {
    const tracks = ["a", "b", "c", "d"].map((id) => ({ id }));
    const randomValues = [0.75, 0.1, 0.5];
    let randomIndex = 0;

    const shuffled = shuffleKeepingCurrentFirst(
      tracks,
      "c",
      (track) => track.id,
      () => randomValues[randomIndex++] ?? 0,
    );

    expect(shuffled[0]?.id).toBe("c");
    expect(shuffled.map((track) => track.id).sort()).toEqual([
      "a",
      "b",
      "c",
      "d",
    ]);
    expect(tracks.map((track) => track.id)).toEqual(["a", "b", "c", "d"]);
  });
});

describe("uniqueItemsById", () => {
  it("keeps the first queue entry for each non-empty track ID", () => {
    const firstA = { id: "a", title: "first" };
    const duplicateA = { id: "a", title: "duplicate" };
    const b = { id: "b", title: "second" };

    expect(
      uniqueItemsById([
        firstA,
        null,
        duplicateA,
        undefined,
        b,
        { id: "", title: "invalid" },
      ]),
    ).toEqual([firstA, b]);
  });
});
