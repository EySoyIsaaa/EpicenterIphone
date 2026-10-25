import SwiftUI

/// Cola de reproducción. Se presenta como hoja desde el reproductor.
/// La canción actual queda fija fuera del scroll. Solo se muestran y editan las siguientes.
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
                    VStack(spacing: 0) {
                        if let id = audio.queuedCurrentId, let track = audio.track(id: id) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(L("REPRODUCIENDO AHORA", "NOW PLAYING"))
                                    .font(.system(size: 10, weight: .black)).kerning(1.4)
                                    .foregroundStyle(Theme.red)
                                TrackRow(track: track, isCurrent: true)
                            }
                            .padding(16)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.red.opacity(0.4), lineWidth: 1))
                            .padding(.horizontal).padding(.vertical, 10)
                            .accessibilityElement(children: .combine)
                        }

                        List {
                            Section(header: Text(L("A continuación", "Up next"))) {
                            ForEach(audio.upcomingTrackIds, id: \.self) { id in
                                if let track = audio.track(id: id) {
                                    Button { audio.playQueueTrack(id: id) } label: {
                                        TrackRow(track: track)
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
                            if audio.upcomingTrackIds.isEmpty {
                                Text(L("No hay más canciones en la cola", "No more songs in the queue"))
                                    .foregroundStyle(Theme.textMuted)
                                    .listRowBackground(Color.clear)
                            }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle(L("Cola", "Queue"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("Listo", "Done")) { dismiss() }.foregroundStyle(Theme.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !audio.upcomingTrackIds.isEmpty { EditButton() }
                }
            }
            .environment(\.editMode, $editMode)
        }
        .navigationViewStyle(.stack)
        .onAppear { audio.refreshQueue() }
    }
}
