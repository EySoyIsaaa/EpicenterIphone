import SwiftUI

/// Lista reutilizable de canciones. Tocar una fila la reproduce dentro de esta lista (la lista
/// se vuelve la cola). Deslizar o mantener presionado abre acciones: favorito, a la cola,
/// siguiente y agregar a playlist. Usada por Canciones, Favoritos, Hi-Res, artista/álbum y playlists.
struct SongsList: View {
    let tracks: [NativeTrack]
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var favorites = LibraryStore.shared
    @ObservedObject private var loc = LocalizationStore.shared
    @State private var addTarget: TrackIdSelection?

    var body: some View {
        Group {
            if tracks.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "music.note").font(.system(size: 34)).foregroundStyle(Theme.textMuted)
                    Text(L("Nada aquí todavía", "Nothing here yet")).foregroundStyle(Theme.textSecondary)
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
                                Label(favorites.isFavorite(track.id) ? L("Quitar", "Remove") : L("Favorito", "Favorite"),
                                      systemImage: favorites.isFavorite(track.id) ? "heart.slash.fill" : "heart.fill")
                            }
                            .tint(Theme.red)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button { audio.addToQueue([track.id]) } label: {
                                Label(L("A la cola", "Queue"), systemImage: "text.append")
                            }
                            .tint(.gray)
                            Button { audio.playNext([track.id]) } label: {
                                Label(L("Siguiente", "Next"), systemImage: "text.insert")
                            }
                            .tint(.blue)
                            Button { addTarget = TrackIdSelection(ids: [track.id]) } label: {
                                Label("Playlist", systemImage: "plus")
                            }
                            .tint(.indigo)
                        }
                        .contextMenu {
                            Button { audio.play(tracks, startAt: index) } label: {
                                Label(L("Reproducir", "Play"), systemImage: "play.fill")
                            }
                            Button { audio.playNext([track.id]) } label: {
                                Label(L("Reproducir siguiente", "Play next"), systemImage: "text.insert")
                            }
                            Button { audio.addToQueue([track.id]) } label: {
                                Label(L("Agregar a la cola", "Add to queue"), systemImage: "text.append")
                            }
                            Button { favorites.toggleFavorite(track.id) } label: {
                                Label(favorites.isFavorite(track.id) ? L("Quitar de favoritos", "Remove from favorites") : L("Agregar a favoritos", "Add to favorites"),
                                      systemImage: favorites.isFavorite(track.id) ? "heart.slash" : "heart")
                            }
                            Button { addTarget = TrackIdSelection(ids: [track.id]) } label: {
                                Label(L("Agregar a playlist", "Add to playlist"), systemImage: "plus")
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
