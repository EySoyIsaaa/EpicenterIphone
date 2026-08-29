import SwiftUI

/// Lista de playlists. Se muestra como destino de navegación dentro de "Mi Música".
struct PlaylistsScreen: View {
    @ObservedObject private var store = LibraryStore.shared
    @ObservedObject private var audio = AudioService.shared
    @State private var creating = false
    @State private var renaming: Playlist?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if store.playlists.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list").font(.system(size: 44)).foregroundStyle(Theme.textMuted)
                    Text("Sin playlists").font(.headline).foregroundStyle(Theme.textPrimary)
                    Text("Crea una con el botón +").font(.footnote).foregroundStyle(Theme.textSecondary)
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
                                    Text("\(playlist.trackIds.count) canción\(playlist.trackIds.count == 1 ? "" : "es")")
                                        .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(Theme.border)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { store.deletePlaylist(playlist.id) } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                            Button { renaming = playlist } label: {
                                Label("Renombrar", systemImage: "pencil")
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
            NameInputSheet(title: "Nueva playlist", saveLabel: "Crear") { store.createPlaylist(name: $0) }
        }
        .sheet(item: $renaming) { playlist in
            NameInputSheet(title: "Renombrar", initial: playlist.name) { store.renamePlaylist(playlist.id, to: $0) }
        }
    }
}

/// Detalle de una playlist: reproducir, aleatorio, agregar/quitar/reordenar canciones.
struct PlaylistDetailScreen: View {
    let playlistId: String
    @ObservedObject private var store = LibraryStore.shared
    @ObservedObject private var audio = AudioService.shared
    @State private var addingSongs = false
    @State private var editMode: EditMode = .inactive

    private var playlist: Playlist? { store.playlist(playlistId) }
    private var trackIds: [String] { playlist?.trackIds ?? [] }
    private var tracks: [NativeTrack] { trackIds.compactMap { audio.track(id: $0) } }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                if !tracks.isEmpty {
                    PlayShuffleBar(tracks: tracks)
                }
                List {
                    Button { addingSongs = true } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill").foregroundStyle(Theme.red)
                            Text("Agregar canciones").foregroundStyle(Theme.textPrimary)
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
                            Text("Canción no disponible")
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
