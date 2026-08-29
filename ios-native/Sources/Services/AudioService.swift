import Combine
import Foundation
import UIKit

/// Native facade that the SwiftUI layer talks to — the replacement for the Capacitor plugin.
///
/// It owns the SAME native services that already power the shipping app (playback controller,
/// library repository, importer) and republishes their state as `@Published` properties so
/// SwiftUI can observe them. No Capacitor / WebView involved.
@MainActor
final class AudioService: ObservableObject {
    static let shared = AudioService()

    // Playback state observed by the UI.
    @Published var isPlaying = false
    @Published var title = "—"
    @Published var artist = ""
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var libraryCount = 0
    @Published var currentTrackId: String?

    private let repository = NativeTrackRepository()
    private lazy var importer = NativeTrackImporter(repository: repository)
    private let playback = NativePlaybackController.shared

    private init() {
        // The controller emits events on a background queue; hop to the main actor for UI.
        playback.setEventEmitter { [weak self] event, data in
            Task { @MainActor in self?.apply(event: event, data: data) }
        }
        refresh()
    }

    // MARK: Library

    func refresh() {
        libraryCount = repository.loadTracks(limit: 5000).count
    }

    /// Full library as model objects, for the SwiftUI lists.
    func loadLibrary() -> [NativeTrack] {
        repository.loadTracks(limit: 5000)
    }

    /// Play a specific track from a list (sets the queue to that list starting at `index`).
    func play(_ tracks: [NativeTrack], startAt index: Int) {
        guard tracks.indices.contains(index) else { return }
        _ = playback.setQueueAndPlay(trackIds: tracks.map { $0.id }, startIndex: index)
    }

    func importTracks() {
        guard let presenter = UIApplication.shared.topViewController else { return }
        importer.importTracks(from: presenter) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    // MARK: Playback (debug smoke test for Phase 0b)

    func playAll() {
        let tracks = repository.loadTracks(limit: 2000)
        guard !tracks.isEmpty else { return }
        _ = playback.setQueueAndPlay(trackIds: tracks.map { $0.id }, startIndex: 0)
    }

    func togglePlayPause() {
        _ = isPlaying ? playback.pause() : playback.play()
    }

    func next() { _ = playback.next() }
    func previous() { _ = playback.previous() }

    // MARK: Events

    private func apply(event: String, data: [String: Any]) {
        if let value = data["isPlaying"] as? Bool { isPlaying = value }
        if let value = data["currentTime"] as? Double { currentTime = value }
        if let value = data["duration"] as? Double { duration = value }
        if let id = data["currentTrackId"] as? String { currentTrackId = id }
        if let track = data["currentTrack"] as? [String: Any] {
            title = track["title"] as? String ?? "—"
            artist = track["artist"] as? String ?? ""
            if let id = track["id"] as? String { currentTrackId = id }
        }
    }
}

extension UIApplication {
    /// Top-most view controller of the active scene (used to present the import picker).
    var topViewController: UIViewController? {
        let scene = connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
