import Combine
import Foundation
import MediaPlayer
import SwiftUI   // move(fromOffsets:toOffset:) lo provee SwiftUI
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

    // Cola (para la pantalla "Cola")
    @Published var queueTrackIds: [String] = []
    @Published var queueIndex: Int = 0

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
    @Published var autoEqEnabled = false

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
        refreshQueue()
        configureLikeCommand()
    }

    // MARK: Corazón "me gusta" en pantalla bloqueada / Control Center / CarPlay

    /// Registra el comando de feedback "me gusta" del sistema. iOS lo muestra como corazón
    /// donde soporte comandos de feedback (CarPlay/Apple Watch seguro; Lock Screen/Control
    /// Center según versión). Se sincroniza con Favoritos.
    private func configureLikeCommand() {
        let like = MPRemoteCommandCenter.shared().likeCommand
        like.isEnabled = true
        like.localizedTitle = "Me gusta"
        like.localizedShortTitle = "Me gusta"
        like.addTarget { [weak self] _ in
            guard let self = self, let id = self.currentTrackId else { return .noSuchContent }
            LibraryStore.shared.toggleFavorite(id)
            self.updateLikeCommandState()
            return .success
        }
        updateLikeCommandState()
    }

    /// Refleja en el sistema si la canción actual es favorita (corazón lleno / vacío).
    func updateLikeCommandState() {
        let isFav = currentTrackId.map { LibraryStore.shared.isFavorite($0) } ?? false
        MPRemoteCommandCenter.shared().likeCommand.isActive = isFav
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
    /// Reproduce una colección concreta en orden aleatorio (artista, álbum, favoritos, playlist…).
    func playShuffled(_ tracks: [NativeTrack]) {
        let shuffled = tracks.shuffled()
        guard !shuffled.isEmpty else { return }
        _ = playback.setQueueAndPlay(trackIds: shuffled.map { $0.id }, startIndex: 0)
    }
    func track(id: String) -> NativeTrack? { repository.findTrack(id: id) }
    func togglePlayPause() { _ = isPlaying ? playback.pause() : playback.play() }
    func next() { _ = playback.next() }
    func previous() { _ = playback.previous() }
    func seek(to seconds: Double) { _ = playback.seek(seconds: seconds) }
    func cycleRepeat() {
        repeatMode = repeatMode == .off ? .all : (repeatMode == .all ? .one : .off)
        if let mode = NativeRepeatMode(rawValue: repeatMode.rawValue) { _ = playback.setRepeatMode(mode) }
    }

    // MARK: Cola

    /// Canciones de la cola actual, resueltas a modelos (puede omitir ids no encontrados).
    func queueTracks() -> [NativeTrack] { queueTrackIds.compactMap { repository.findTrack(id: $0) } }

    /// Sincroniza `queueTrackIds`/`queueIndex` desde el estado real del motor.
    func refreshQueue() {
        let state = playback.getPlaybackState()
        guard let queue = state["queue"] as? [String: Any] else { return }
        queueTrackIds = (queue["trackIds"] as? [String]) ?? []
        queueIndex = (queue["currentIndex"] as? Int) ?? 0
    }

    /// Salta a una canción que ya está en la cola sin reconstruirla.
    func playQueueTrack(id: String) { _ = playback.play(trackId: id) }

    func moveQueue(from source: IndexSet, to destination: Int) {
        var ids = queueTrackIds
        ids.move(fromOffsets: source, toOffset: destination)
        setQueueOrder(ids)
    }

    func removeQueue(at offsets: IndexSet) {
        let ids = offsets.compactMap { queueTrackIds.indices.contains($0) ? queueTrackIds[$0] : nil }
        removeFromQueue(ids: ids)
    }

    /// Agrega al final de la cola (o inicia reproducción si la cola está vacía).
    func addToQueue(_ ids: [String]) {
        let live = liveQueue()
        guard !live.ids.isEmpty else { play(ids.compactMap { track(id: $0) }, startAt: 0); return }
        let existing = Set(live.ids)
        setQueueOrder(live.ids + ids.filter { !existing.contains($0) })
    }

    /// Inserta justo después de la canción actual.
    func playNext(_ ids: [String]) {
        let live = liveQueue()
        guard !live.ids.isEmpty else { play(ids.compactMap { track(id: $0) }, startAt: 0); return }
        var newIds = live.ids
        let existing = Set(newIds)
        let toInsert = ids.filter { !existing.contains($0) }
        newIds.insert(contentsOf: toInsert, at: min(live.index + 1, newIds.count))
        setQueueOrder(newIds)
    }

    /// Quita canciones de la cola (nunca la que suena ahora).
    func removeFromQueue(ids: [String]) {
        let live = liveQueue()
        let currentId = live.ids.indices.contains(live.index) ? live.ids[live.index] : nil
        let removeSet = Set(ids).subtracting(currentId.map { [$0] } ?? [])
        guard !removeSet.isEmpty else { return }
        setQueueOrder(live.ids.filter { !removeSet.contains($0) })
    }

    /// Reinstala la cola conservando la pista que suena (sin reiniciar el audio).
    private func setQueueOrder(_ newIds: [String]) {
        let live = liveQueue()
        let currentId = live.ids.indices.contains(live.index) ? live.ids[live.index] : nil
        let start = currentId.flatMap { newIds.firstIndex(of: $0) } ?? 0
        _ = playback.setQueue(trackIds: newIds, startIndex: start)
        refreshQueue()
    }

    /// Lee la cola viva del motor (fuente de verdad para las mutaciones).
    private func liveQueue() -> (ids: [String], index: Int) {
        let queue = playback.getPlaybackState()["queue"] as? [String: Any]
        return ((queue?["trackIds"] as? [String]) ?? queueTrackIds,
                (queue?["currentIndex"] as? Int) ?? queueIndex)
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
    /// Auto-EQ: analiza cada canción en el dispositivo y aplica una curva automática.
    func setAutoEqEnabled(_ on: Bool) {
        autoEqEnabled = on
        UserDefaults.standard.set(on, forKey: "autoEqEnabled")
        _ = playback.setAutoEqEnabled(on)
    }

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
        autoEqEnabled = UserDefaults.standard.bool(forKey: "autoEqEnabled")
        if autoEqEnabled { _ = playback.setAutoEqEnabled(true) }
    }

    /// Canciones escuchadas recientemente (resueltas a modelos, en orden de recencia).
    func recentlyPlayedTracks() -> [NativeTrack] {
        LibraryStore.shared.recentlyPlayedIds.compactMap { repository.findTrack(id: $0) }
    }

    private func apply(event: String, data: [String: Any]) {
        let previousTrackId = currentTrackId
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
        if let queue = data["queue"] as? [String: Any] {
            if let ids = queue["trackIds"] as? [String] { queueTrackIds = ids }
            if let idx = queue["currentIndex"] as? Int { queueIndex = idx }
        }
        if let id = currentTrackId, id != previousTrackId {
            LibraryStore.shared.recordPlayed(id)
        }
        updateLikeCommandState()
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
