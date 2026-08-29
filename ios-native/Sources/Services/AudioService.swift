import Combine
import Foundation
import UIKit

/// Native facade that the SwiftUI layer talks to — the replacement for the Capacitor plugin.
/// Owns the same native services that power the shipping app and republishes their state as
/// `@Published` properties for SwiftUI. No Capacitor / WebView involved.
final class AudioService: ObservableObject {
    static let shared = AudioService()

    enum RepeatMode: String { case off, all, one }

    // Playback
    @Published var isPlaying = false
    @Published var title = "—"
    @Published var artist = ""
    @Published var artworkPath: String?
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var currentTrackId: String?
    @Published var repeatMode: RepeatMode = .off
    @Published var libraryCount = 0

    // Epicenter / DSP
    @Published var epicenterEnabled = false
    @Published var headphonesMode = false          // true = Audífonos, false = Car Audio
    @Published var intensity: Double = 100
    @Published var sweepFreq: Double = 45
    @Published var width: Double = 50
    @Published var balance: Double = 100
    @Published var volume: Double = 100

    // EQ
    @Published var eqEnabled = false
    @Published var eqBands: [Double] = Array(repeating: 0, count: 31)

    // Effects
    @Published var reverbEnabled = false
    @Published var reverbAmount: Double = 0
    @Published var concertHallEnabled = false
    @Published var concertHallAmount: Double = 0

    var hasTrack: Bool { currentTrackId != nil }

    private let repository = NativeTrackRepository()
    private lazy var importer = NativeTrackImporter(repository: repository)
    private let playback = NativePlaybackController.shared

    private init() {
        playback.setEventEmitter { [weak self] event, data in
            Task { @MainActor in self?.apply(event: event, data: data) }
        }
        refresh()
        loadDspState()
    }

    // MARK: Library

    func refresh() { libraryCount = repository.loadTracks(limit: 5000).count }
    func loadLibrary() -> [NativeTrack] { repository.loadTracks(limit: 5000) }

    func importTracks() {
        guard let presenter = UIApplication.shared.topViewController else { return }
        importer.importTracks(from: presenter) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    // MARK: Playback

    func play(_ tracks: [NativeTrack], startAt index: Int) {
        guard tracks.indices.contains(index) else { return }
        _ = playback.setQueueAndPlay(trackIds: tracks.map { $0.id }, startIndex: index)
    }
    func shuffleLibrary() {
        let tracks = repository.loadTracks(limit: 5000).shuffled()
        guard !tracks.isEmpty else { return }
        _ = playback.setQueueAndPlay(trackIds: tracks.map { $0.id }, startIndex: 0)
    }
    func togglePlayPause() { _ = isPlaying ? playback.pause() : playback.play() }
    func next() { _ = playback.next() }
    func previous() { _ = playback.previous() }
    func seek(to seconds: Double) { _ = playback.seek(seconds: seconds) }
    func cycleRepeat() {
        repeatMode = repeatMode == .off ? .all : (repeatMode == .all ? .one : .off)
        if let mode = NativeRepeatMode(rawValue: repeatMode.rawValue) { _ = playback.setRepeatMode(mode) }
    }

    // MARK: Epicenter / DSP

    func setEpicenterEnabled(_ on: Bool) { epicenterEnabled = on; _ = playback.setEpicenterEnabled(on) }
    func setHeadphonesMode(_ on: Bool) {
        headphonesMode = on
        UserDefaults.standard.set(on ? "headphones" : "car", forKey: "epicenterMode")
        _ = playback.setEpicenterMode(headphones: on)
    }
    func setIntensity(_ v: Double) { intensity = v; _ = playback.setEpicenterParams(intensity: v, sweepFreq: nil, width: nil, balance: nil, volume: nil) }
    func setSweep(_ v: Double) { sweepFreq = v; _ = playback.setEpicenterParams(intensity: nil, sweepFreq: v, width: nil, balance: nil, volume: nil) }
    func setWidth(_ v: Double) { width = v; _ = playback.setEpicenterParams(intensity: nil, sweepFreq: nil, width: v, balance: nil, volume: nil) }
    func setBalance(_ v: Double) { balance = v; _ = playback.setEpicenterParams(intensity: nil, sweepFreq: nil, width: nil, balance: v, volume: nil) }
    func setVolume(_ v: Double) { volume = v; _ = playback.setEpicenterParams(intensity: nil, sweepFreq: nil, width: nil, balance: nil, volume: v) }

    // MARK: EQ

    func setEqEnabled(_ on: Bool) { eqEnabled = on; _ = playback.setEqEnabled(on) }
    func setEqBand(_ index: Int, _ gain: Double) {
        guard eqBands.indices.contains(index) else { return }
        eqBands[index] = gain
        _ = playback.setEqBand(index: index, gain: gain)
    }
    func resetEq() { eqBands = Array(repeating: 0, count: 31); _ = playback.resetEq() }

    // MARK: Effects

    func setReverbEnabled(_ on: Bool) { reverbEnabled = on; _ = playback.setReverbEnabled(on) }
    func setReverbAmount(_ v: Double) { reverbAmount = v; _ = playback.setReverbAmount(v) }
    func setConcertHallEnabled(_ on: Bool) { concertHallEnabled = on; _ = playback.setConcertHallEnabled(on) }
    func setConcertHallAmount(_ v: Double) { concertHallAmount = v; _ = playback.setConcertHallAmount(v) }

    // MARK: State loading

    private func loadDspState() {
        let s = playback.getPlaybackState()
        if let e = s["epicenter"] as? [String: Any] {
            epicenterEnabled = e["enabled"] as? Bool ?? false
            intensity = num(e["intensity"], 100); sweepFreq = num(e["sweepFreq"], 45)
            width = num(e["width"], 50); balance = num(e["balance"], 100); volume = num(e["volume"], 100)
        }
        if let q = s["eq"] as? [String: Any] {
            eqEnabled = q["enabled"] as? Bool ?? false
            if let bands = q["bands"] as? [Double], bands.count == 31 { eqBands = bands }
        }
        if let f = s["fx"] as? [String: Any] {
            reverbEnabled = f["reverbEnabled"] as? Bool ?? false; reverbAmount = num(f["reverbAmount"], 0)
            concertHallEnabled = f["concertHallEnabled"] as? Bool ?? false; concertHallAmount = num(f["concertHallAmount"], 0)
        }
        headphonesMode = (UserDefaults.standard.string(forKey: "epicenterMode") ?? "car") == "headphones"
        _ = playback.setEpicenterMode(headphones: headphonesMode)
    }

    private func apply(event: String, data: [String: Any]) {
        if let value = data["isPlaying"] as? Bool { isPlaying = value }
        if let value = data["currentTime"] as? Double { currentTime = value }
        if let value = data["duration"] as? Double { duration = value }
        if let id = data["currentTrackId"] as? String { currentTrackId = id }
        if let track = data["currentTrack"] as? [String: Any] {
            title = track["title"] as? String ?? "—"
            artist = track["artist"] as? String ?? ""
            artworkPath = track["albumArtUri"] as? String
            if let id = track["id"] as? String { currentTrackId = id }
        }
    }

    private func num(_ v: Any?, _ d: Double) -> Double {
        (v as? Double) ?? (v as? NSNumber)?.doubleValue ?? d
    }
}

extension UIApplication {
    /// Top-most view controller of the active scene (used to present the import picker).
    var topViewController: UIViewController? {
        let scene = connectedScenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
