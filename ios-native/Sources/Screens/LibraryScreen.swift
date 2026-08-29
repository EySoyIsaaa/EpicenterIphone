import SwiftUI

/// Biblioteca (pestaña "Mi Música"). Portada de tarjetas fiel a la vista web:
/// Reproducir aleatorio · Playlists · Favoritos · Canciones · Artistas · Álbumes · Hi-Res.
struct LibraryScreen: View {
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var store = LibraryStore.shared
    @State private var tracks: [NativeTrack] = []

    private var favoriteTracks: [NativeTrack] { tracks.filter { store.isFavorite($0.id) } }
    private var hiResTracks: [NativeTrack] { tracks.filter { $0.qualityClass == "hi-res" || $0.qualityClass == "studio" } }
    private var artistGroups: [TrackGroup] { groups { $0.artist } }
    private var albumGroups: [TrackGroup] { groups { $0.album } }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                if tracks.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            Button { audio.shuffleLibrary() } label: {
                                LibraryCard(icon: "shuffle", title: "Reproducir aleatorio",
                                            subtitle: "\(tracks.count) canciones", accent: true, chevron: false)
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: PlaylistsScreen()) {
                                LibraryCard(icon: "music.note.list", title: "Playlists",
                                            subtitle: "\(store.playlists.count)")
                            }
                            NavigationLink(destination: SongCollection(title: "Favoritos", tracks: favoriteTracks)) {
                                LibraryCard(icon: "heart.fill", title: "Favoritos",
                                            subtitle: "\(favoriteTracks.count)", accent: true)
                            }
                            NavigationLink(destination: SongCollection(title: "Canciones", tracks: tracks, showsSort: true)) {
                                LibraryCard(icon: "music.note", title: "Canciones",
                                            subtitle: "\(tracks.count)")
                            }
                            NavigationLink(destination: GroupCollection(title: "Artistas", groups: artistGroups, icon: "music.mic")) {
                                LibraryCard(icon: "music.mic", title: "Artistas",
                                            subtitle: "\(artistGroups.count)")
                            }
                            NavigationLink(destination: GroupCollection(title: "Álbumes", groups: albumGroups, icon: "square.stack")) {
                                LibraryCard(icon: "square.stack", title: "Álbumes",
                                            subtitle: "\(albumGroups.count)")
                            }
                            NavigationLink(destination: SongCollection(title: "Alta Resolución", tracks: hiResTracks)) {
                                LibraryCard(icon: "waveform.badge.plus", title: "Alta Resolución",
                                            subtitle: "\(hiResTracks.count)", accent: true)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Mi Música")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { audio.importTracks() } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(Theme.red)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear { tracks = audio.loadLibrary() }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "opticaldisc").font(.system(size: 54)).foregroundStyle(Theme.textMuted)
            Text("Sin música todavía").font(.headline).foregroundStyle(Theme.textPrimary)
            Text("Toca + para importar canciones").font(.footnote).foregroundStyle(Theme.textSecondary)
            Button { audio.importTracks() } label: {
                Text("Agregar música")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 20).padding(.vertical, 11)
                    .background(Theme.red, in: Capsule())
                    .foregroundStyle(.white)
            }
            .padding(.top, 4)
        }
    }

    /// Agrupa la biblioteca por una clave (artista o álbum).
    private func groups(_ key: (NativeTrack) -> String?) -> [TrackGroup] {
        Dictionary(grouping: tracks) { track -> String in
            let value = key(track) ?? ""
            return value.isEmpty ? "Desconocido" : value
        }
        .map { TrackGroup(name: $0.key, tracks: $0.value.sorted { $0.title < $1.title }) }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

struct TrackGroup: Identifiable {
    var id: String { name }
    let name: String
    let tracks: [NativeTrack]
}

/// Tarjeta de la portada de biblioteca.
private struct LibraryCard: View {
    let icon: String
    let title: String
    let subtitle: String
    var accent: Bool = false
    var chevron: Bool = true

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Theme.card)
                    .frame(width: 48, height: 48)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent ? Theme.red.opacity(0.5) : Theme.border, lineWidth: 1))
                Image(systemName: icon).foregroundStyle(accent ? Theme.red : Theme.textPrimary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Text(subtitle).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if chevron {
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textMuted)
            } else {
                Image(systemName: "play.fill").foregroundStyle(Theme.red)
            }
        }
        .padding(14)
        .background(Theme.card.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1))
    }
}

/// Lista de grupos (artistas o álbumes); cada uno navega a su colección con Play/Aleatorio.
private struct GroupCollection: View {
    let title: String
    let groups: [TrackGroup]
    let icon: String

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if groups.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: icon).font(.system(size: 34)).foregroundStyle(Theme.textMuted)
                    Text("Nada aquí todavía").foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(groups) { group in
                    NavigationLink(destination: SongCollection(title: group.name, tracks: group.tracks)) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8).fill(Theme.card).frame(width: 46, height: 46)
                                Image(systemName: icon).foregroundStyle(Theme.textMuted)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary).lineLimit(1)
                                Text("\(group.tracks.count) canción\(group.tracks.count == 1 ? "" : "es")")
                                    .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(Theme.border)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
