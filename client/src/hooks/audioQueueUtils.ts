export interface LibraryPage<T> {
  tracks: T[];
  total: number;
}

export type SerialExecutor = <T>(task: () => Promise<T>) => Promise<T>;

/**
 * Executes complete queue mutations one at a time. Each task is responsible for
 * reading its latest snapshot, awaiting the native write, and only then publishing
 * UI state. A rejected task never poisons the operations queued behind it.
 */
export function createSerialExecutor(): SerialExecutor {
  let tail: Promise<void> = Promise.resolve();

  return <T>(task: () => Promise<T>): Promise<T> => {
    const result = tail.then(task, task);
    tail = result.then(
      () => undefined,
      () => undefined,
    );
    return result;
  };
}

export function uniqueItemsById<T extends { id: string }>(
  items: readonly (T | null | undefined)[],
): T[] {
  const seen = new Set<string>();
  return items.filter((item): item is T => {
    if (!item?.id || seen.has(item.id)) return false;
    seen.add(item.id);
    return true;
  });
}

export async function loadEveryLibraryPage<T extends { id: string }>(
  fetchPage: (offset: number, limit: number) => Promise<LibraryPage<T>>,
  pageSize = 500,
): Promise<T[]> {
  const normalizedPageSize = Math.max(1, Math.floor(pageSize));
  const tracks: T[] = [];
  const seenIds = new Set<string>();
  let offset = 0;
  let total = Number.POSITIVE_INFINITY;

  while (offset < total) {
    const page = await fetchPage(offset, normalizedPageSize);
    const pageTracks = Array.isArray(page.tracks) ? page.tracks : [];
    total = Number.isFinite(page.total) ? Math.max(0, page.total) : 0;

    // A provider returning an empty page before `total` is reached must not leave
    // the app in an infinite refresh loop.
    if (pageTracks.length === 0) break;

    for (const track of pageTracks) {
      if (!track?.id || seenIds.has(track.id)) continue;
      seenIds.add(track.id);
      tracks.push(track);
    }

    // Advance by rows consumed, not unique rows retained. This remains correct if
    // the native database happens to return a duplicate at a page boundary.
    offset += pageTracks.length;
  }

  return tracks;
}

export function shuffleKeepingCurrentFirst<T>(
  tracks: readonly T[],
  currentTrackId: string | null | undefined,
  getId: (track: T) => string,
  random: () => number = Math.random,
): T[] {
  const currentIndex = currentTrackId
    ? tracks.findIndex((track) => getId(track) === currentTrackId)
    : -1;
  const current = currentIndex >= 0 ? tracks[currentIndex] : undefined;
  const shuffled = tracks.filter((_, index) => index !== currentIndex);

  // Fisher-Yates provides an unbiased permutation; Array.sort(Math.random) does not.
  for (let index = shuffled.length - 1; index > 0; index -= 1) {
    const swapIndex = Math.floor(random() * (index + 1));
    [shuffled[index], shuffled[swapIndex]] = [
      shuffled[swapIndex],
      shuffled[index],
    ];
  }

  return current ? [current, ...shuffled] : shuffled;
}
