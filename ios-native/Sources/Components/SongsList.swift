import SwiftUI

/// Lista reutilizable de canciones. Tocar una fila la reproduce dentro de esta lista (la lista
/// se vuelve la cola). Deslizar o mantener presionado abre acciones: favorito, a la cola,
/// siguiente y agregar a playlist. Usada por Canciones, Favoritos, Hi-Res, artista/álbum y playlists.
struct SongsList: View {
    let tracks: [NativeTrack]
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var favorites = LibraryStore.shared
    @State private var addTarget: TrackIdSelection?

    var body: some View {
        Group {
            if tracks.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "music.note").font(.system(size: 34)).foregroundStyle(Theme.textMuted)
                    Text("Nada aquí todavía").foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                        Button { audio.play(tracks, startAt: index) } label: {
                            TrackRow(track: track, isCurrent: audio.currentTrackId == track.id)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(Theme.border)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button { favorites.toggleFavorite(track.id) } label: {
                                Label(favorites.isFavorite(track.id) ? "Quitar" : "Favorito",
                                      systemImage: favorites.isFavorite(track.id) ? "heart.slash.fill" : "heart.fill")
                            }
                            .tint(Theme.red)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button { audio.addToQueue([track.id]) } label: {
                                Label("A la cola", systemImage: "text.append")
                            }
                            .tint(.gray)
                            Button { audio.playNext([track.id]) } label: {
                                Label("Siguiente", systemImage: "text.insert")
                            }
                            .tint(.blue)
                            Button { addTarget = TrackIdSelection(ids: [track.id]) } label: {
                                Label("Playlist", systemImage: "plus")
                            }
                            .tint(.indigo)
                        }
                        .contextMenu {
                            Button { audio.play(tracks, startAt: index) } label: {
                                Label("Reproducir", systemImage: "play.fill")
                            }
                            Button { audio.playNext([track.id]) } label: {
                                Label("Reproducir siguiente", systemImage: "text.insert")
                            }
                            Button { audio.addToQueue([track.id]) } label: {
                                Label("Agregar a la cola", systemImage: "text.append")
                            }
                            Button { favorites.toggleFavorite(track.id) } label: {
                                Label(favorites.isFavorite(track.id) ? "Quitar de favoritos" : "Agregar a favoritos",
                                      systemImage: favorites.isFavorite(track.id) ? "heart.slash" : "heart")
                            }
                            Button { addTarget = TrackIdSelection(ids: [track.id]) } label: {
                                Label("Agregar a playlist", systemImage: "plus")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(item: $addTarget) { selection in
            AddToPlaylistSheet(trackIds: selection.ids)
        }
    }
}
