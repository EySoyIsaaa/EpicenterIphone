import SwiftUI

/// Cola de reproducción. Se presenta como hoja desde el reproductor.
/// Tocar salta a la canción; deslizar la quita; el botón Editar permite reordenar.
struct QueueScreen: View {
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var loc = LocalizationStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationView {
            ZStack {
                BrandBackground()
                if audio.queueTrackIds.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet").font(.system(size: 44)).foregroundStyle(Theme.textMuted)
                        Text(L("Cola vacía", "Empty queue")).font(.headline).foregroundStyle(Theme.textPrimary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(Array(audio.queueTrackIds.enumerated()), id: \.element) { index, id in
                            if let track = audio.track(id: id) {
                                Button { audio.playQueueTrack(id: id) } label: {
                                    TrackRow(track: track, isCurrent: index == audio.queueIndex)
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
                        .onMove { audio.moveQueue(from: $0, to: $1) }
                        .onDelete { audio.removeQueue(at: $0) }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(L("Cola", "Queue"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("Listo", "Done")) { dismiss() }.foregroundStyle(Theme.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !audio.queueTrackIds.isEmpty { EditButton() }
                }
            }
            .environment(\.editMode, $editMode)
        }
        .navigationViewStyle(.stack)
        .onAppear { audio.refreshQueue() }
    }
}
