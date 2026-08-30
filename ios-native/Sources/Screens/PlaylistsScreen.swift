import SwiftUI

/// Lista de playlists. Se muestra como destino de navegación dentro de "Mi Música".
struct PlaylistsScreen: View {
    @ObservedObject private var store = LibraryStore.shared
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var loc = LocalizationStore.shared
    @State private var creating = false
    @State private var renaming: Playlist?

    var body: some View {
        ZStack {
            BrandBackground()
            if store.playlists.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list").font(.system(size: 44)).foregroundStyle(Theme.textMuted)
                    Text(L("Sin playlists", "No playlists")).font(.headline).foregroundStyle(Theme.textPrimary)
                    Text(L("Crea una con el botón +", "Create one with the + button")).font(.footnote).foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.playlists) { playlist in
                        NavigationLink(destination: PlaylistDetailScreen(playlistId: playlist.id)) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8).fill(Theme.card).frame(width: 46, height: 46)
                                    Image(systemName: "music.note.list").foregroundStyle(Theme.textSecondary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(playlist.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Theme.textPrimary).lineLimit(1)
                                    Text("\(playlist.trackIds.count) " + (playlist.trackIds.count == 1 ? L("canción", "song") : L("canciones", "songs")))
                                        .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(Theme.border)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { store.deletePlaylist(playlist.id) } label: {
                                Label(L("Eliminar", "Delete"), systemImage: "trash")
                            }
                            Button { renaming = playlist } label: {
                                Label(L("Renombrar", "Rename"), systemImage: "pencil")
                            }
                            .tint(.gray)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Playlists")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { creating = true } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(Theme.red)
                }
            }
        }
        .sheet(isPresented: $creating) {
            NameInputSheet(title: L("Nueva playlist", "New playlist"), saveLabel: L("Crear", "Create")) { store.createPlaylist(name: $0) }
        }
        .sheet(item: $renaming) { playlist in
            NameInputSheet(title: L("Renombrar", "Rename"), initial: playlist.name) { store.renamePlaylist(playlist.id, to: $0) }
        }
    }
}

/// Detalle de una playlist: reproducir, aleatorio, agregar/quitar/reordenar canciones.
struct PlaylistDetailScreen: View {
    let playlistId: String
    @ObservedObject private var store = LibraryStore.shared
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var loc = LocalizationStore.shared
    @State private var addingSongs = false
    @State private var editMode: EditMode = .inactive

    private var playlist: Playlist? { store.playlist(playlistId) }
    private var trackIds: [String] { playlist?.trackIds ?? [] }
    private var tracks: [NativeTrack] { trackIds.compactMap { audio.track(id: $0) } }

    var body: some View {
        ZStack {
            BrandBackground()
            VStack(spacing: 0) {
                if !tracks.isEmpty {
                    PlayShuffleBar(tracks: tracks)
                }
                List {
                    Button { addingSongs = true } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill").foregroundStyle(Theme.red)
                            Text(L("Agregar canciones", "Add songs")).foregroundStyle(Theme.textPrimary)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(Theme.border)

                    ForEach(trackIds, id: \.self) { id in
                        if let track = audio.track(id: id) {
                            Button { play(trackId: id) } label: {
                                TrackRow(track: track, isCurrent: audio.currentTrackId == id)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparatorTint(Theme.border)
                        } else {
                            Text(L("Canción no disponible", "Song unavailable"))
                                .foregroundStyle(Theme.textMuted)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .onDelete { store.removeTracks(in: playlistId, at: $0) }
                    .onMove { store.moveTracks(in: playlistId, from: $0, to: $1) }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(playlist?.name ?? "Playlist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
        }
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $addingSongs) { AddSongsSheet(playlistId: playlistId) }
    }

    /// Reproduce empezando en la canción tocada, con toda la playlist como cola.
    private func play(trackId: String) {
        if let index = tracks.firstIndex(where: { $0.id == trackId }) {
            audio.play(tracks, startAt: index)
        }
    }
}
