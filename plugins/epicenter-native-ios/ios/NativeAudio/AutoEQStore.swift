import Foundation

/// Per-song Auto-EQ cache.
///
/// Deliberately isolated from the main library SQLite database: this is a derived,
/// disposable analysis result, and keeping it in its own JSON file means we never touch the
/// live library schema (no migration risk on an app that's already shipping). Keyed by the
/// track's content `stableId`, so a re-import of the same file reuses the cached curve.
final class AutoEQStore {
    static let shared = AutoEQStore()

    private let queue = DispatchQueue(label: "com.epicenter.hifi.auto-eq-store")
    private let fileURL: URL
    private var cache: [String: NativeAudioAnalysis]

    private init() {
        let base = (try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )) ?? FileManager.default.temporaryDirectory
        // New schema intentionally ignores old EQ-only results, whose clipped
        // bass bands cannot describe the original song's bass profile.
        fileURL = base.appendingPathComponent("EpicenterAnalysis-v2.json")
        cache = AutoEQStore.load(from: fileURL)
    }

    func analysis(forStableId stableId: String) -> NativeAudioAnalysis? {
        queue.sync { cache[stableId] }
    }

    func save(analysis: NativeAudioAnalysis, forStableId stableId: String) {
        queue.async {
            self.cache[stableId] = analysis
            self.persist()
        }
    }

    func clear(stableId: String) {
        queue.async {
            self.cache.removeValue(forKey: stableId)
            self.persist()
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func load(from url: URL) -> [String: NativeAudioAnalysis] {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: NativeAudioAnalysis].self, from: data) else {
            return [:]
        }
        return decoded
    }
}
