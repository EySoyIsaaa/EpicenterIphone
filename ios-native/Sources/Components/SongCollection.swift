import SwiftUI

/// Barra de acciones "Reproducir" (en orden) + "Aleatorio" para una colección.
struct PlayShuffleBar: View {
    let tracks: [NativeTrack]
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var loc = LocalizationStore.shared

    var body: some View {
        HStack(spacing: 12) {
            Button { audio.play(tracks, startAt: 0) } label: {
                Label(L("Reproducir", "Play"), systemImage: "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Theme.red, in: Capsule())
                    .foregroundStyle(.white)
            }
            Button { audio.playShuffled(tracks) } label: {
                Label(L("Aleatorio", "Shuffle"), systemImage: "shuffle")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .overlay(Capsule().stroke(Theme.border, lineWidth: 1))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }
}

/// Colección de canciones con encabezado de acciones y (opcional) orden.
/// Se usa como destino de navegación (no crea su propio NavigationView).
struct SongCollection: View {
    let title: String
    let tracks: [NativeTrack]
    var showsSort: Bool = false
    var showsHiResBadge: Bool = false

    @ObservedObject private var loc = LocalizationStore.shared
    @State private var sort: SortMode = .added

    enum SortMode: String, CaseIterable, Identifiable {
        case added, name, artist
        var id: String { rawValue }
        var label: String {
            switch self {
            case .added:  return L("Recientes", "Recent")
            case .name:   return L("Nombre", "Name")
            case .artist: return L("Artista", "Artist")
            }
        }
    }

    private var sortedTracks: [NativeTrack] {
        guard showsSort else { return tracks }
        switch sort {
        case .added:  return tracks
        case .name:   return tracks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .artist: return tracks.sorted { ($0.artist ?? "").localizedCaseInsensitiveCompare($1.artist ?? "") == .orderedAscending }
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                if showsHiResBadge {
                    HStack(spacing: 10) {
                        HiResBadge(height: 22)
                        Text(L("Reproducción a máxima resolución sin recompresión.",
                               "Playback at maximum resolution without recompression."))
                            .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal).padding(.top, 10).padding(.bottom, 2)
                }
                if !tracks.isEmpty {
                    PlayShuffleBar(tracks: sortedTracks)
                    if showsSort {
                        Picker(L("Orden", "Sort"), selection: $sort) {
                            ForEach(SortMode.allCases) { Text($0.label).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
                SongsList(tracks: sortedTracks)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
