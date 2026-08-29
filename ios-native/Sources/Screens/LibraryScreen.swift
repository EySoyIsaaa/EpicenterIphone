import SwiftUI
import UIKit

/// Biblioteca (pestaña "Música"). Portada de tiles a color + álbumes escuchados recientemente.
struct LibraryScreen: View {
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var store = LibraryStore.shared
    @State private var tracks: [NativeTrack] = []
    @State private var showSearch = false

    private var favoriteTracks: [NativeTrack] { tracks.filter { store.isFavorite($0.id) } }
    private var hiResTracks: [NativeTrack] { tracks.filter { $0.isHiRes } }
    private var artistGroups: [TrackGroup] { groups { $0.artist } }
    private var albumGroups: [TrackGroup] { groups { $0.album } }

    /// Álbumes escuchados recientemente (sin repetir), en orden de recencia.
    /// Se resuelve contra la biblioteca ya cargada en memoria (sin consultas por render).
    private var recentAlbums: [TrackGroup] {
        let byId = Dictionary(tracks.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var seen = Set<String>()
        var result: [TrackGroup] = []
        for id in store.recentlyPlayedIds {
            guard let track = byId[id] else { continue }
            let key = (track.album ?? "").isEmpty ? "Desconocido" : track.album!
            guard seen.insert(key).inserted else { continue }
            let albumTracks = tracks.filter { (($0.album ?? "").isEmpty ? "Desconocido" : $0.album!) == key }
            result.append(TrackGroup(name: key, tracks: albumTracks.isEmpty ? [track] : albumTracks))
            if result.count >= 8 { break }
        }
        return result
    }

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
                                shuffleCard
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: PlaylistsScreen()) {
                                CategoryTile(icon: "music.note.list", title: "Playlists",
                                             subtitle: "\(store.playlists.count)",
                                             colors: [Color(red: 0.55, green: 0.35, blue: 0.95), Color(red: 0.33, green: 0.18, blue: 0.72)])
                            }
                            NavigationLink(destination: SongCollection(title: "Favoritos", tracks: favoriteTracks)) {
                                CategoryTile(icon: "heart.fill", title: "Favoritos",
                                             subtitle: "\(favoriteTracks.count)",
                                             colors: [Color(red: 1.0, green: 0.32, blue: 0.46), Color(red: 0.85, green: 0.08, blue: 0.22)])
                            }
                            NavigationLink(destination: SongCollection(title: "Canciones", tracks: tracks, showsSort: true)) {
                                CategoryTile(icon: "music.note", title: "Canciones",
                                             subtitle: "\(tracks.count)",
                                             colors: [Color(red: 0.25, green: 0.55, blue: 1.0), Color(red: 0.10, green: 0.35, blue: 0.85)])
                            }
                            NavigationLink(destination: GroupCollection(title: "Artistas", groups: artistGroups, icon: "music.mic")) {
                                CategoryTile(icon: "music.mic", title: "Artistas",
                                             subtitle: "\(artistGroups.count)",
                                             colors: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.9, green: 0.38, blue: 0.1)])
                            }
                            NavigationLink(destination: GroupCollection(title: "Álbumes", groups: albumGroups, icon: "square.stack")) {
                                CategoryTile(icon: "square.stack", title: "Álbumes",
                                             subtitle: "\(albumGroups.count)",
                                             colors: [Color(red: 0.2, green: 0.75, blue: 0.68), Color(red: 0.08, green: 0.53, blue: 0.48)])
                            }
                            NavigationLink(destination: SongCollection(title: "Alta Resolución", tracks: hiResTracks, showsHiResBadge: true)) {
                                hiResCard
                            }

                            if !recentAlbums.isEmpty {
                                recentSection
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Música")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showSearch = true } label: {
                        Image(systemName: "magnifyingglass").foregroundStyle(Theme.textPrimary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { audio.importTracks() } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(Theme.red)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showSearch) { SearchScreen() }
        .onAppear { tracks = audio.loadLibrary() }
    }

    // MARK: Secciones

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Escuchado recientemente")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 16) {
                ForEach(recentAlbums) { album in
                    NavigationLink(destination: SongCollection(title: album.name, tracks: album.tracks)) {
                        AlbumCell(album: album)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var shuffleCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [Theme.red, Color(red: 0.75, green: 0.03, blue: 0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                Image(systemName: "shuffle").font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Reproducir aleatorio").font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Text("\(tracks.count) canciones").font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "play.fill").foregroundStyle(Theme.red)
        }
        .padding(12)
        .background(Theme.card.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.red.opacity(0.4), lineWidth: 1))
    }

    private var hiResCard: some View {
        HStack(spacing: 14) {
            HiResBadge(height: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text("Alta Resolución").font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Text("\(hiResTracks.count)").font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textMuted)
        }
        .padding(12)
        .background(Theme.card.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.83, green: 0.66, blue: 0.35).opacity(0.5), lineWidth: 1))
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

/// Tile de categoría con tesela de color (menos genérico, estilo Apple Music).
private struct CategoryTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let colors: [Color]

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Text(subtitle).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textMuted)
        }
        .padding(12)
        .background(Theme.card.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1))
    }
}

/// Celda de álbum (carátula cuadrada + nombre + artista) para la rejilla de recientes.
private struct AlbumCell: View {
    let album: TrackGroup

    private var image: UIImage? {
        guard let path = album.tracks.first?.albumArtUri, !path.isEmpty else { return nil }
        let file = path.hasPrefix("file://") ? (URL(string: path)?.path ?? path) : path
        return UIImage(contentsOfFile: file)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12).fill(Theme.card)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    if let image = image {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Image(systemName: "music.note").font(.system(size: 28)).foregroundStyle(Theme.textMuted)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary).lineLimit(1)
                Text(album.tracks.first?.artist ?? "Artista desconocido")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary).lineLimit(1)
            }
        }
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
                            AlbumArtwork(path: group.tracks.first?.albumArtUri, size: 46)
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
