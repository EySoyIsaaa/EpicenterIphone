import SwiftUI

/// Fase 2: la biblioteca con sus divisiones (Canciones · Artistas · Álbumes · Hi-Res).
/// Playlists llega en la Fase 5 (con persistencia real).
struct LibraryScreen: View {
    @StateObject private var audio = AudioService.shared
    @State private var tracks: [NativeTrack] = []
    @State private var section: Section = .canciones

    enum Section: String, CaseIterable, Identifiable {
        case canciones = "Canciones"
        case artistas = "Artistas"
        case albumes = "Álbumes"
        case hires = "Hi-Res"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    Picker("", selection: $section) {
                        ForEach(Section.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    content
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

    @ViewBuilder private var content: some View {
        switch section {
        case .canciones:
            SongsList(tracks: tracks)
        case .hires:
            SongsList(tracks: tracks.filter { ($0.qualityClass == "hi-res") || ($0.qualityClass == "studio") })
        case .artistas:
            GroupList(groups: groups { $0.artist }, icon: "music.mic")
        case .albumes:
            GroupList(groups: groups { $0.album }, icon: "square.stack")
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

/// Lista de grupos (artistas o álbumes); cada uno navega al detalle con sus canciones.
private struct GroupList: View {
    let groups: [TrackGroup]
    let icon: String

    var body: some View {
        if groups.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 34)).foregroundStyle(Theme.textMuted)
                Text("Nada aquí todavía").foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(groups) { group in
                NavigationLink(destination:
                    SongsList(tracks: group.tracks)
                        .background(Theme.background.ignoresSafeArea())
                        .navigationTitle(group.name)
                ) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(Theme.card).frame(width: 46, height: 46)
                            Image(systemName: icon).foregroundStyle(Theme.textMuted)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)
                            Text("\(group.tracks.count) canción\(group.tracks.count == 1 ? "" : "es")")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textSecondary)
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
}
