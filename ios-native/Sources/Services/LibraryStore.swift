import Combine
import Foundation
import SwiftUI   // move(fromOffsets:toOffset:) y remove(atOffsets:) los provee SwiftUI

/// Persistencia nativa de Favoritos y Playlists (nueva funcionalidad, no existía en la
/// vista web). Se guarda en UserDefaults como JSON — sin tocar la base SQLite compartida
/// del motor. Todas las pantallas observan esta única fuente de verdad.
final class LibraryStore: ObservableObject {
    static let shared = LibraryStore()

    @Published private(set) var favoriteIds: Set<String> = []
    @Published private(set) var playlists: [Playlist] = []
    @Published private(set) var recentlyPlayedIds: [String] = []

    private let favKey = "epicenter.favorites.v1"
    private let playlistsKey = "epicenter.playlists.v1"
    private let recentKey = "epicenter.recentlyPlayed.v1"
    private let defaults = UserDefaults.standard

    private init() {
        if let ids = defaults.array(forKey: favKey) as? [String] {
            favoriteIds = Set(ids)
        }
        if let data = defaults.data(forKey: playlistsKey),
           let decoded = try? JSONDecoder().decode([Playlist].self, from: data) {
            playlists = decoded
        }
        if let ids = defaults.array(forKey: recentKey) as? [String] {
            recentlyPlayedIds = ids
        }
    }

    /// Registra una canción como escuchada recientemente (la lleva al frente).
    func recordPlayed(_ id: String) {
        guard !id.isEmpty else { return }
        var ids = recentlyPlayedIds
        ids.removeAll { $0 == id }
        ids.insert(id, at: 0)
        if ids.count > 120 { ids = Array(ids.prefix(120)) }
        recentlyPlayedIds = ids
        defaults.set(ids, forKey: recentKey)
    }

    // MARK: Favoritos

    func isFavorite(_ id: String) -> Bool { favoriteIds.contains(id) }

    func toggleFavorite(_ id: String) {
        if favoriteIds.contains(id) { favoriteIds.remove(id) } else { favoriteIds.insert(id) }
        defaults.set(Array(favoriteIds), forKey: favKey)
    }

    // MARK: Playlists

    @discardableResult
    func createPlaylist(name: String) -> Playlist {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let playlist = Playlist(name: trimmed.isEmpty ? "Nueva playlist" : trimmed, trackIds: [])
        playlists.append(playlist)
        savePlaylists()
        return playlist
    }

    func renamePlaylist(_ id: String, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = playlists.firstIndex(where: { $0.id == id }) else { return }
        playlists[index].name = trimmed
        savePlaylists()
    }

    func deletePlaylist(_ id: String) {
        playlists.removeAll { $0.id == id }
        savePlaylists()
    }

    func addTracks(_ ids: [String], to playlistId: String) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        let existing = Set(playlists[index].trackIds)
        playlists[index].trackIds.append(contentsOf: ids.filter { !existing.contains($0) })
        savePlaylists()
    }

    func removeTrack(_ id: String, from playlistId: String) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        playlists[index].trackIds.removeAll { $0 == id }
        savePlaylists()
    }

    func removeTracks(in playlistId: String, at offsets: IndexSet) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        playlists[index].trackIds.remove(atOffsets: offsets)
        savePlaylists()
    }

    func moveTracks(in playlistId: String, from source: IndexSet, to destination: Int) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        playlists[index].trackIds.move(fromOffsets: source, toOffset: destination)
        savePlaylists()
    }

    func playlist(_ id: String) -> Playlist? { playlists.first { $0.id == id } }

    private func savePlaylists() {
        if let data = try? JSONEncoder().encode(playlists) {
            defaults.set(data, forKey: playlistsKey)
        }
    }
}

struct Playlist: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var trackIds: [String]
    var createdAt: Date = Date()
}

/// Envoltorio Identifiable para presentar hojas `.sheet(item:)` con un conjunto de canciones
/// (p. ej. "agregar a playlist").
struct TrackIdSelection: Identifiable {
    let id = UUID()
    let ids: [String]
}

/// `NativeTrack` ya tiene `id: String`; esto habilita `ForEach(tracks)` y `.sheet(item:)`.
extension NativeTrack: Identifiable {}
