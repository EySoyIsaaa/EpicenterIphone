import Foundation

enum NativeRepeatMode: String {
    case off
    case all
    case one
}

final class NativeQueueManager {
    private(set) var trackIds: [String] = []
    private(set) var currentIndex: Int = 0
    private(set) var repeatMode: NativeRepeatMode = .off

    var currentTrackId: String? {
        guard !trackIds.isEmpty, currentIndex >= 0, currentIndex < trackIds.count else {
            return nil
        }
        return trackIds[currentIndex]
    }

    var dictionary: [String: Any] {
        [
            "trackIds": trackIds,
            "currentIndex": currentIndex,
            "currentTrackId": jsonOrNull(currentTrackId),
            "repeatMode": repeatMode.rawValue,
        ]
    }

    func setQueue(trackIds: [String], startIndex: Int) {
        let requestedTrackId: String? = trackIds.indices.contains(startIndex)
            ? trackIds[startIndex]
            : nil
        var seen = Set<String>()
        self.trackIds = trackIds.filter { trackId in
            !trackId.isEmpty && seen.insert(trackId).inserted
        }
        guard !self.trackIds.isEmpty else {
            currentIndex = 0
            return
        }
        if let requestedTrackId,
           let uniqueIndex = self.trackIds.firstIndex(of: requestedTrackId) {
            currentIndex = uniqueIndex
        } else {
            currentIndex = min(max(startIndex, 0), self.trackIds.count - 1)
        }
        print("[NativeQueue] currentIndex=\(currentIndex) currentTrackId=\(currentTrackId ?? "nil")")
    }

    func setCurrentTrackId(_ trackId: String) {
        if let index = trackIds.firstIndex(of: trackId) {
            currentIndex = index
        } else {
            trackIds = [trackId]
            currentIndex = 0
        }
    }

    func setCurrentIndex(_ index: Int) {
        guard !trackIds.isEmpty else {
            currentIndex = 0
            return
        }
        currentIndex = min(max(index, 0), trackIds.count - 1)
        print("[NativeQueue] currentIndex=\(currentIndex) currentTrackId=\(currentTrackId ?? "nil")")
    }

    func setRepeatMode(_ mode: NativeRepeatMode) {
        repeatMode = mode
    }

    /// Ordered candidate indices after the current item. With wrapping enabled,
    /// the search continues at the beginning; a one-item queue returns itself.
    func nextCandidateIndices(wrapping: Bool) -> [Int] {
        guard !trackIds.isEmpty, currentIndex >= 0, currentIndex < trackIds.count else {
            return []
        }
        let forward: [Int] = currentIndex + 1 < trackIds.count
            ? Array((currentIndex + 1)..<trackIds.count)
            : []
        guard wrapping else { return forward }
        if trackIds.count == 1 { return [currentIndex] }
        return forward + (currentIndex > 0 ? Array(0..<currentIndex) : [])
    }

    func previousCandidateIndices(wrapping: Bool) -> [Int] {
        guard !trackIds.isEmpty, currentIndex >= 0, currentIndex < trackIds.count else {
            return []
        }
        let backward: [Int] = currentIndex > 0
            ? Array(stride(from: currentIndex - 1, through: 0, by: -1))
            : []
        guard wrapping else { return backward }
        if trackIds.count == 1 { return [currentIndex] }
        let wrapped: [Int] = currentIndex + 1 < trackIds.count
            ? Array(stride(from: trackIds.count - 1, through: currentIndex + 1, by: -1))
            : []
        return backward + wrapped
    }

    func moveNext() -> String? {
        guard !trackIds.isEmpty else { return nil }
        guard currentIndex + 1 < trackIds.count else { return nil }
        currentIndex += 1
        return currentTrackId
    }

    func movePrevious() -> String? {
        guard !trackIds.isEmpty else { return nil }
        guard currentIndex > 0 else { return nil }
        currentIndex -= 1
        return currentTrackId
    }
}


private func jsonOrNull<T>(_ value: T?) -> Any {
    guard let value = value else {
        return NSNull()
    }
    return value
}
