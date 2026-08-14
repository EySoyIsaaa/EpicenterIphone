/**
 * Epicenter Hi-Fi - iOS-only Audio Queue & Library Hook
 *
 * This branch is intentionally iPhone/iOS-only. The library source of truth is
 * EpicenterNative SQLite on iOS; no IndexedDB, localStorage, MediaStore, or web
 * scanner is used for tracks.
 */

import { useState, useCallback, useEffect, useRef } from "react";
import {
  EpicenterNative,
  type IOSNativeRepeatMode,
} from "@/native/iosNativeAudio";
import {
  nativeTrackToAppTrack,
  type IOSAppTrack,
} from "@/native/iosTrackMapper";
import {
  createSerialExecutor,
  loadEveryLibraryPage,
  shuffleKeepingCurrentFirst,
  uniqueItemsById,
} from "@/hooks/audioQueueUtils";

export interface Track extends IOSAppTrack {
  id: string;
  sourceTrackId?: string;
  file?: File;
  isEphemeral?: boolean;
  fileName?: string;
  fileType?: string;
  codec?: string;
  fileSize?: number;
  title: string;
  artist: string;
  duration: number;
  coverUrl?: string;
  bitDepth?: number;
  sampleRate?: number;
  bitrate?: number;
  isHiRes?: boolean;
  qualityClass?: IOSAppTrack["qualityClass"];
  sourceUri?: string;
  sourceUrl?: string;
  originalUrl?: string;
  playbackUrl?: string;
  optimizedUrl?: string;
  optimizedForPlayback?: boolean;
  optimizationStatus?: IOSAppTrack["optimizationStatus"];
  optimizationError?: string;
  originalBitDepth?: number;
  originalSampleRate?: number;
  originalBitrate?: number;
  originalFormat?: string;
  sourceType?: "manual-ios";
  albumId?: number;
  albumArtUri?: string;
  mediaStoreId?: string;
  dateModified?: number;
  sourceVersionKey?: string;
  unavailable?: boolean;
  unavailableReason?: string;
  lastSeenAt?: number;
  missingSince?: number;
  missingCount?: number;
  scanCompleteness?: "partial" | "complete";
  lastValidatedAt?: number;
}

export interface ImportResult {
  added: number;
  duplicates: string[];
}

export interface ImportProgress {
  isImporting: boolean;
  current: number;
  total: number;
  currentFileName: string;
}

export interface QueueController {
  library: Track[];
  isLoading: boolean;
  importProgress: ImportProgress;
  getTrackFile: (track: Track) => Promise<File | undefined>;
  queue: Track[];
  currentTrackIndex: number;
  currentTrack: Track | null;
  shuffleEnabled: boolean;
  repeatMode: IOSNativeRepeatMode;
  playbackRequestVersion: number;
  refreshLibrary: () => Promise<Track[]>;
  addToLibrary: (files: File[]) => Promise<ImportResult>;
  importManualTracksFromNativePicker: () => Promise<ImportResult>;
  addMediaStoreTracks: () => Promise<ImportResult>;
  reconcileMediaStoreTracks: () => Promise<{
    updated: number;
    missing: number;
  }>;
  removeFromLibrary: (id: string) => Promise<void>;
  clearLibrary: () => Promise<void>;
  addToQueue: (track: Track) => void;
  addToQueueNext: (track: Track) => void;
  addMultipleToQueue: (tracks: Track[]) => void;
  playAllInOrder: (tracks: Track[]) => Promise<boolean>;
  playFromCollection: (tracks: Track[], trackId: string) => Promise<boolean>;
  playNow: (track: Track) => Promise<boolean>;
  removeFromQueue: (id: string) => void;
  clearQueue: () => void;
  shuffleAll: (tracks: Track[], firstTrackId?: string) => Promise<boolean>;
  toggleShuffle: () => Promise<boolean>;
  cycleRepeatMode: () => Promise<boolean>;
  reorderQueue: (fromIndex: number, toIndex: number) => void;
  playTrack: (index: number) => Promise<boolean>;
  nextTrack: (requestId?: string) => void;
  previousTrack: (requestId?: string) => void;
  syncCurrentTrackById: (trackId: string) => void;
  persistEphemeralTrack: (trackId: string) => Promise<boolean>;
  addTrack: (file: File) => Promise<void>;
  addTracks: (files: File[]) => Promise<void>;
  addTrackToEnd: (track: Track) => void;
  addTrackNext: (track: Track) => void;
  removeTrack: (id: string) => void;
}

const NATIVE_LIBRARY_PAGE_SIZE = 500;

interface QueueSnapshot {
  tracks: Track[];
  currentIndex: number;
  shuffleEnabled: boolean;
  originalOrder: Track[] | null;
}

const nativeTrackToTrack = nativeTrackToAppTrack;

const isValidTrack = (track: Track | null | undefined): track is Track =>
  Boolean(track?.id);

const uniqueValidTracks = (tracks: readonly (Track | null | undefined)[]) => {
  return uniqueItemsById(tracks);
};

const setNativeQueue = async (tracks: Track[], startIndex: number) => {
  const playableTracks = Array.isArray(tracks) ? uniqueValidTracks(tracks) : [];
  const response = await EpicenterNative.setQueue({
    trackIds: playableTracks.map((track) => track.id),
    startIndex:
      playableTracks.length > 0
        ? Math.max(0, Math.min(startIndex, playableTracks.length - 1))
        : 0,
  });
  if (response.status !== "ok") {
    throw new Error(`Native queue update failed: ${response.status}`);
  }
};

const setNativeQueueAndPlay = async (tracks: Track[], startIndex: number) => {
  const playableTracks = Array.isArray(tracks) ? uniqueValidTracks(tracks) : [];
  const safeStartIndex =
    playableTracks.length > 0
      ? Math.max(0, Math.min(startIndex, playableTracks.length - 1))
      : 0;
  const response = await EpicenterNative.setQueueAndPlay({
    trackIds: playableTracks.map((track) => track.id),
    startIndex: safeStartIndex,
  });
  if (response.status !== "ok") {
    throw new Error(
      response.message || `Native playback failed: ${response.status}`,
    );
  }
  return response;
};

export function useAudioQueue(): QueueController {
  const [library, setLibrary] = useState<Track[]>([]);
  const [queue, setQueue] = useState<Track[]>([]);
  const [currentTrackIndex, setCurrentTrackIndex] = useState(-1);
  const [shuffleEnabled, setShuffleEnabled] = useState(false);
  const [repeatMode, setRepeatMode] = useState<IOSNativeRepeatMode>("off");
  const [playbackRequestVersion, setPlaybackRequestVersion] = useState(0);
  const queueSnapshotRef = useRef<QueueSnapshot>({
    tracks: [],
    currentIndex: -1,
    shuffleEnabled: false,
    originalOrder: null,
  });
  const queueOperationRef = useRef(createSerialExecutor());
  const repeatModeTouchedRef = useRef(false);
  const repeatModeChangeInFlightRef = useRef(false);
  const [isLoading, setIsLoading] = useState(true);
  const [importProgress, setImportProgress] = useState<ImportProgress>({
    isImporting: false,
    current: 0,
    total: 0,
    currentFileName: "",
  });

  const publishQueueSnapshot = useCallback(
    (candidate: QueueSnapshot, playbackStarted = false) => {
      const tracks = uniqueValidTracks(candidate.tracks);
      const currentIndex =
        tracks.length > 0 && candidate.currentIndex >= 0
          ? Math.max(0, Math.min(candidate.currentIndex, tracks.length - 1))
          : -1;
      const originalOrder = candidate.originalOrder
        ? uniqueValidTracks(candidate.originalOrder)
        : null;
      const snapshot: QueueSnapshot = {
        tracks,
        currentIndex,
        shuffleEnabled: candidate.shuffleEnabled,
        originalOrder,
      };

      // Publish the synchronous snapshot first. The next queued operation must read
      // the state that was confirmed by iOS, even before React finishes rendering.
      queueSnapshotRef.current = snapshot;
      setQueue(tracks);
      setCurrentTrackIndex(currentIndex);
      setShuffleEnabled(candidate.shuffleEnabled);
      if (playbackStarted) {
        setPlaybackRequestVersion((version) => version + 1);
      }
    },
    [],
  );

  const refreshLibrary = useCallback(async (): Promise<Track[]> => {
    console.info("[iOS Native Library] app start load");
    setIsLoading(true);
    try {
      const nativeTracks = await loadEveryLibraryPage(async (offset, limit) => {
        const page = await EpicenterNative.getLibraryPage({
          offset,
          limit,
          sort: "addedAt",
        });
        return {
          tracks: Array.isArray(page.tracks) ? page.tracks : [],
          total: page.total,
        };
      }, NATIVE_LIBRARY_PAGE_SIZE);
      const tracks = nativeTracks.map(nativeTrackToTrack).filter(isValidTrack);
      setLibrary(tracks);
      console.info("[iOS Native Library] loaded count", tracks.length);
      return tracks;
    } catch (error) {
      console.error("[iOS Native Library] load error", error);
      setLibrary([]);
      return [];
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void refreshLibrary();
  }, [refreshLibrary]);

  useEffect(() => {
    void EpicenterNative.getPlaybackState()
      .then((state) => {
        const nativeRepeatMode = state.queue?.repeatMode;
        if (
          !repeatModeTouchedRef.current &&
          (nativeRepeatMode === "off" ||
            nativeRepeatMode === "all" ||
            nativeRepeatMode === "one")
        ) {
          setRepeatMode(nativeRepeatMode);
        }
      })
      .catch((error) =>
        console.warn("[Queue] unable to restore native repeat mode", error),
      );
  }, []);

  const importManualTracksFromNativePicker =
    useCallback(async (): Promise<ImportResult> => {
      console.info("[iOS Native Library] import requested");
      setImportProgress({
        isImporting: true,
        current: 0,
        total: 1,
        currentFileName: "iOS Import",
      });
      try {
        const result = await EpicenterNative.importTracks();
        console.info(
          "[iOS Native Library] imported count",
          Array.isArray(result.tracks) ? result.tracks.length : 0,
        );
        await refreshLibrary();
        return {
          added: Array.isArray(result.tracks) ? result.tracks.length : 0,
          duplicates: [],
        };
      } catch (error) {
        console.error("[iOS Native Library] import error", error);
        throw error;
      } finally {
        setImportProgress({
          isImporting: false,
          current: 0,
          total: 0,
          currentFileName: "",
        });
      }
    }, [refreshLibrary]);

  const removeFromLibrary = useCallback(
    async (id: string) => {
      return queueOperationRef.current(async () => {
        const before = queueSnapshotRef.current;
        const currentTrackId = before.tracks[before.currentIndex]?.id;
        if (currentTrackId === id) {
          await EpicenterNative.stop();
        }
        await EpicenterNative.deleteTrack({ id });
        setLibrary((prev) => prev.filter((track) => track.id !== id));

        const next = before.tracks.filter((track) => track.id !== id);
        const nextCurrentIndex = currentTrackId
          ? (() => {
              const retainedIndex = next.findIndex(
                (track) => track.id === currentTrackId,
              );
              return retainedIndex >= 0
                ? retainedIndex
                : next.length > 0
                  ? Math.min(Math.max(before.currentIndex, 0), next.length - 1)
                  : -1;
            })()
          : -1;
        const originalOrder =
          before.originalOrder?.filter((track) => track.id !== id) ?? null;
        await setNativeQueue(next, nextCurrentIndex);
        publishQueueSnapshot({
          tracks: next,
          currentIndex: nextCurrentIndex,
          shuffleEnabled: before.shuffleEnabled,
          originalOrder,
        });
      });
    },
    [publishQueueSnapshot],
  );

  const clearLibrary = useCallback(async () => {
    return queueOperationRef.current(async () => {
      await EpicenterNative.stop();
      for (const track of library) {
        await EpicenterNative.deleteTrack({ id: track.id });
      }
      await setNativeQueue([], 0);
      setLibrary([]);
      publishQueueSnapshot({
        tracks: [],
        currentIndex: -1,
        shuffleEnabled: false,
        originalOrder: null,
      });
    });
  }, [library, publishQueueSnapshot]);

  const addToQueue = useCallback(
    (track: Track) => {
      if (!isValidTrack(track)) return;
      void queueOperationRef
        .current(async () => {
          const before = queueSnapshotRef.current;
          if (before.tracks.some((item) => item.id === track.id)) return;
          const next = [...before.tracks, track];
          const originalOrder = before.originalOrder
            ? uniqueValidTracks([...before.originalOrder, track])
            : null;
          await setNativeQueue(next, before.currentIndex);
          publishQueueSnapshot({
            tracks: next,
            currentIndex: before.currentIndex,
            shuffleEnabled: before.shuffleEnabled,
            originalOrder,
          });
        })
        .catch((error) => console.error("[Queue] add-to-queue failed", error));
    },
    [publishQueueSnapshot],
  );

  const addToQueueNext = useCallback(
    (track: Track) => {
      if (!isValidTrack(track)) return;
      void queueOperationRef
        .current(async () => {
          const before = queueSnapshotRef.current;
          if (before.tracks.some((item) => item.id === track.id)) return;
          const insertIndex =
            before.currentIndex >= 0 ? before.currentIndex + 1 : 0;
          const next = [
            ...before.tracks.slice(0, insertIndex),
            track,
            ...before.tracks.slice(insertIndex),
          ];
          let originalOrder = before.originalOrder;
          if (before.shuffleEnabled && originalOrder) {
            const originalCurrentId = before.tracks[before.currentIndex]?.id;
            const originalInsertIndex = originalCurrentId
              ? originalOrder.findIndex(
                  (item) => item.id === originalCurrentId,
                ) + 1
              : 0;
            originalOrder = uniqueValidTracks([
              ...originalOrder.slice(0, originalInsertIndex),
              track,
              ...originalOrder.slice(originalInsertIndex),
            ]);
          }
          await setNativeQueue(next, before.currentIndex);
          publishQueueSnapshot({
            tracks: next,
            currentIndex: before.currentIndex,
            shuffleEnabled: before.shuffleEnabled,
            originalOrder,
          });
        })
        .catch((error) => console.error("[Queue] add-next failed", error));
    },
    [publishQueueSnapshot],
  );

  const addMultipleToQueue = useCallback(
    (tracks: Track[]) => {
      const validTracks = Array.isArray(tracks)
        ? uniqueValidTracks(tracks)
        : [];
      if (validTracks.length === 0) return;
      void queueOperationRef
        .current(async () => {
          const before = queueSnapshotRef.current;
          const next = uniqueValidTracks([...before.tracks, ...validTracks]);
          if (next.length === before.tracks.length) return;
          const originalOrder = before.originalOrder
            ? uniqueValidTracks([...before.originalOrder, ...validTracks])
            : null;
          await setNativeQueue(next, before.currentIndex);
          publishQueueSnapshot({
            tracks: next,
            currentIndex: before.currentIndex,
            shuffleEnabled: before.shuffleEnabled,
            originalOrder,
          });
        })
        .catch((error) => console.error("[Queue] add-many failed", error));
    },
    [publishQueueSnapshot],
  );

  const performPlaybackSelection = useCallback(
    async (
      tracks: Track[],
      startIndex: number,
      options: {
        shuffle: boolean;
        originalOrder: Track[] | null;
      },
    ): Promise<boolean> => {
      const validTracks = uniqueValidTracks(tracks);
      if (validTracks.length === 0) return false;
      const safeStartIndex = Math.max(
        0,
        Math.min(startIndex, validTracks.length - 1),
      );
      const nativeState = await setNativeQueueAndPlay(
        validTracks,
        safeStartIndex,
      );
      const nativeTrackId =
        nativeState.currentTrackId ?? nativeState.queue?.currentTrackId;
      const nativeIndex = nativeTrackId
        ? validTracks.findIndex((track) => track.id === nativeTrackId)
        : -1;
      const committedIndex = nativeIndex >= 0 ? nativeIndex : safeStartIndex;
      publishQueueSnapshot(
        {
          tracks: validTracks,
          currentIndex: committedIndex,
          shuffleEnabled: options.shuffle,
          originalOrder: options.originalOrder,
        },
        true,
      );
      return true;
    },
    [publishQueueSnapshot],
  );

  const commitPlaybackSelection = useCallback(
    (
      tracks: Track[],
      startIndex: number,
      options: {
        shuffle: boolean;
        originalOrder: Track[] | null;
      },
    ): Promise<boolean> => {
      return queueOperationRef.current(async () => {
        try {
          return await performPlaybackSelection(tracks, startIndex, options);
        } catch (error) {
          console.error("[Queue] atomic queue playback failed", error);
          return false;
        }
      });
    },
    [performPlaybackSelection],
  );

  const moveToQueueIndex = useCallback(
    async (index: number, reason: string): Promise<boolean> => {
      const requestedTrackId = queue[index]?.id;
      if (!requestedTrackId) {
        console.warn("[Queue] move requested with empty queue", {
          reason,
          index,
        });
        return false;
      }
      return queueOperationRef.current(async () => {
        const before = queueSnapshotRef.current;
        const after = before.tracks.findIndex(
          (track) => track.id === requestedTrackId,
        );
        if (after < 0) return false;
        const track = before.tracks[after];
        console.info("[Queue] before/after index", {
          reason,
          before: before.currentIndex,
          after,
          trackId: track?.id,
          title: track?.title,
        });
        try {
          return await performPlaybackSelection(before.tracks, after, {
            shuffle: before.shuffleEnabled,
            originalOrder: before.originalOrder,
          });
        } catch (error) {
          console.error("[Queue] unable to play queued track", error);
          return false;
        }
      });
    },
    [performPlaybackSelection, queue],
  );

  const playTrack = useCallback(
    (index: number) => moveToQueueIndex(index, "playTrack"),
    [moveToQueueIndex],
  );

  const playNow = useCallback(
    async (track: Track) => {
      if (!isValidTrack(track)) return false;
      return commitPlaybackSelection([track], 0, {
        shuffle: false,
        originalOrder: null,
      });
    },
    [commitPlaybackSelection],
  );

  const playFromCollection = useCallback(
    async (tracks: Track[], trackId: string) => {
      const validTracks = Array.isArray(tracks)
        ? uniqueValidTracks(tracks)
        : [];
      const requestedIndex = validTracks.findIndex(
        (track) => track.id === trackId,
      );
      if (requestedIndex < 0) return false;
      return queueOperationRef.current(async () => {
        const shouldShuffle = queueSnapshotRef.current.shuffleEnabled;
        const playbackTracks = shouldShuffle
          ? shuffleKeepingCurrentFirst(
              validTracks,
              trackId,
              (track) => track.id,
            )
          : validTracks;
        const playbackIndex = shouldShuffle ? 0 : requestedIndex;
        try {
          return await performPlaybackSelection(playbackTracks, playbackIndex, {
            shuffle: shouldShuffle,
            originalOrder: shouldShuffle ? validTracks : null,
          });
        } catch (error) {
          console.error("[Queue] unable to play collection", error);
          return false;
        }
      });
    },
    [performPlaybackSelection],
  );

  const playAllInOrder = useCallback(
    async (tracks: Track[]) => {
      const validTracks = Array.isArray(tracks)
        ? uniqueValidTracks(tracks)
        : [];
      return commitPlaybackSelection(validTracks, 0, {
        shuffle: false,
        originalOrder: null,
      });
    },
    [commitPlaybackSelection],
  );

  const shuffleAll = useCallback(
    async (tracks: Track[], firstTrackId?: string) => {
      const validTracks = Array.isArray(tracks)
        ? uniqueValidTracks(tracks)
        : [];
      const shuffled = shuffleKeepingCurrentFirst(
        validTracks,
        firstTrackId,
        (track) => track.id,
      );
      return commitPlaybackSelection(shuffled, 0, {
        shuffle: true,
        originalOrder: validTracks,
      });
    },
    [commitPlaybackSelection],
  );

  const toggleShuffle = useCallback(async (): Promise<boolean> => {
    return queueOperationRef.current(async () => {
      const before = queueSnapshotRef.current;
      const currentTrackId = before.tracks[before.currentIndex]?.id ?? null;
      try {
        if (before.shuffleEnabled) {
          const restored = uniqueValidTracks(
            before.originalOrder ?? before.tracks,
          );
          const foundRestoredIndex = currentTrackId
            ? restored.findIndex((track) => track.id === currentTrackId)
            : -1;
          const restoredIndex =
            foundRestoredIndex >= 0
              ? foundRestoredIndex
              : before.currentIndex >= 0 && restored.length > 0
                ? 0
                : -1;
          await setNativeQueue(restored, restoredIndex);
          publishQueueSnapshot({
            tracks: restored,
            currentIndex: restoredIndex,
            shuffleEnabled: false,
            originalOrder: null,
          });
          return true;
        }

        const validTracks = uniqueValidTracks(before.tracks);
        if (validTracks.length === 0) return false;
        const shuffled = shuffleKeepingCurrentFirst(
          validTracks,
          currentTrackId,
          (track) => track.id,
        );
        const shuffledIndex = before.currentIndex >= 0 ? 0 : -1;
        await setNativeQueue(shuffled, shuffledIndex);
        publishQueueSnapshot({
          tracks: shuffled,
          currentIndex: shuffledIndex,
          shuffleEnabled: true,
          originalOrder: validTracks,
        });
        return true;
      } catch (error) {
        console.error("[Queue] unable to toggle shuffle", error);
        return false;
      }
    });
  }, [publishQueueSnapshot]);

  const cycleRepeatMode = useCallback(async (): Promise<boolean> => {
    if (repeatModeChangeInFlightRef.current) return false;
    repeatModeTouchedRef.current = true;
    repeatModeChangeInFlightRef.current = true;
    const nextMode: IOSNativeRepeatMode =
      repeatMode === "off" ? "all" : repeatMode === "all" ? "one" : "off";
    try {
      const state = await EpicenterNative.setRepeatMode({ mode: nextMode });
      if (state.status !== "ok") {
        throw new Error(
          state.message || `Repeat update failed: ${state.status}`,
        );
      }
      setRepeatMode(state.queue?.repeatMode ?? nextMode);
      return true;
    } catch (error) {
      console.error("[Queue] unable to set repeat mode", error);
      return false;
    } finally {
      repeatModeChangeInFlightRef.current = false;
    }
  }, [repeatMode]);

  const nextTrack = useCallback(
    (requestId = `webqueue-next-${Date.now()}`) => {
      console.info(
        `[WebQueue] nextTrack called requestId=${requestId} platform=ios action=delegating-to-native`,
        {
          currentIndex: currentTrackIndex,
          queueLength: queue.length,
        },
      );
      void EpicenterNative.next({ requestId });
    },
    [currentTrackIndex, queue.length],
  );

  const previousTrack = useCallback(
    (requestId = `webqueue-previous-${Date.now()}`) => {
      console.info(
        `[WebQueue] previousTrack called requestId=${requestId} platform=ios action=delegating-to-native`,
        {
          currentIndex: currentTrackIndex,
          queueLength: queue.length,
        },
      );
      void EpicenterNative.previous({ requestId });
    },
    [currentTrackIndex, queue.length],
  );

  const syncCurrentTrackById = useCallback((trackId: string) => {
    if (!trackId) return;
    const before = queueSnapshotRef.current;
    const after = before.tracks.findIndex((track) => track.id === trackId);
    if (after < 0 || after === before.currentIndex) return;
    console.info("[Queue] before/after index", {
      reason: "native-sync",
      before: before.currentIndex,
      after,
      trackId,
    });
    queueSnapshotRef.current = { ...before, currentIndex: after };
    setCurrentTrackIndex(after);
  }, []);

  const removeFromQueue = useCallback(
    (id: string) => {
      void queueOperationRef
        .current(async () => {
          const before = queueSnapshotRef.current;
          const currentTrackId = before.tracks[before.currentIndex]?.id;
          // Removing the actively playing entry would leave AVAudioEngine playing a
          // track that no longer exists in its native queue. Keep it until playback
          // advances; users can still clear the entire queue explicitly.
          if (currentTrackId === id) return;
          const next = before.tracks.filter((track) => track.id !== id);
          if (next.length === before.tracks.length) return;
          const originalOrder =
            before.originalOrder?.filter((track) => track.id !== id) ?? null;
          const retainedCurrentIndex = currentTrackId
            ? next.findIndex((track) => track.id === currentTrackId)
            : -1;
          const nextCurrentIndex =
            retainedCurrentIndex >= 0
              ? retainedCurrentIndex
              : next.length > 0
                ? Math.min(Math.max(before.currentIndex, 0), next.length - 1)
                : -1;
          await setNativeQueue(next, nextCurrentIndex);
          publishQueueSnapshot({
            tracks: next,
            currentIndex: nextCurrentIndex,
            shuffleEnabled: before.shuffleEnabled,
            originalOrder,
          });
        })
        .catch((error) =>
          console.error("[Queue] remove-from-queue failed", error),
        );
    },
    [publishQueueSnapshot],
  );

  const clearQueue = useCallback(() => {
    void queueOperationRef
      .current(async () => {
        await EpicenterNative.stop();
        await setNativeQueue([], 0);
        publishQueueSnapshot({
          tracks: [],
          currentIndex: -1,
          shuffleEnabled: false,
          originalOrder: null,
        });
      })
      .catch((error) => console.error("[Queue] clear-queue failed", error));
  }, [publishQueueSnapshot]);

  const reorderQueue = useCallback(
    (fromIndex: number, toIndex: number) => {
      void queueOperationRef
        .current(async () => {
          const before = queueSnapshotRef.current;
          if (
            fromIndex < 0 ||
            fromIndex >= before.tracks.length ||
            toIndex < 0 ||
            toIndex >= before.tracks.length ||
            fromIndex === toIndex
          ) {
            return;
          }
          const currentTrackId = before.tracks[before.currentIndex]?.id;
          const next = [...before.tracks];
          const [moved] = next.splice(fromIndex, 1);
          if (moved) next.splice(toIndex, 0, moved);
          const nextCurrentIndex = currentTrackId
            ? next.findIndex((track) => track.id === currentTrackId)
            : -1;
          await setNativeQueue(next, nextCurrentIndex);
          publishQueueSnapshot({
            tracks: next,
            currentIndex: nextCurrentIndex,
            shuffleEnabled: before.shuffleEnabled,
            originalOrder: before.originalOrder,
          });
        })
        .catch((error) => console.error("[Queue] reorder failed", error));
    },
    [publishQueueSnapshot],
  );

  const addToLibrary = useCallback(
    async () => importManualTracksFromNativePicker(),
    [importManualTracksFromNativePicker],
  );
  const addMediaStoreTracks = useCallback(
    async (): Promise<ImportResult> => ({ added: 0, duplicates: [] }),
    [],
  );
  const reconcileMediaStoreTracks = useCallback(
    async () => ({ updated: 0, missing: 0 }),
    [],
  );
  const getTrackFile = useCallback(async () => undefined, []);
  const persistEphemeralTrack = useCallback(async () => true, []);
  const addTrack = useCallback(async () => {
    await importManualTracksFromNativePicker();
  }, [importManualTracksFromNativePicker]);
  const addTracks = useCallback(async () => {
    await importManualTracksFromNativePicker();
  }, [importManualTracksFromNativePicker]);

  return {
    library,
    isLoading,
    importProgress,
    getTrackFile,
    queue,
    currentTrackIndex,
    shuffleEnabled,
    repeatMode,
    playbackRequestVersion,
    currentTrack:
      currentTrackIndex >= 0
        ? (queue.filter(isValidTrack)[currentTrackIndex] ?? null)
        : null,
    refreshLibrary,
    addToLibrary,
    importManualTracksFromNativePicker,
    addMediaStoreTracks,
    reconcileMediaStoreTracks,
    removeFromLibrary,
    clearLibrary,
    addToQueue,
    addToQueueNext,
    addMultipleToQueue,
    playAllInOrder,
    playFromCollection,
    playNow,
    removeFromQueue,
    clearQueue,
    shuffleAll,
    toggleShuffle,
    cycleRepeatMode,
    reorderQueue,
    playTrack,
    nextTrack,
    previousTrack,
    syncCurrentTrackById,
    persistEphemeralTrack,
    addTrack,
    addTracks,
    addTrackToEnd: addToQueue,
    addTrackNext: addToQueueNext,
    removeTrack: (id: string) => void removeFromLibrary(id),
  };
}
