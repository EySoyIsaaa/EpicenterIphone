import SwiftUI

/// Hoja simple para capturar un nombre (crear o renombrar playlist).
/// En iOS 15 no existe `TextField` dentro de `.alert`, por eso usamos una hoja.
struct NameInputSheet: View {
    let title: String
    let saveLabel: String
    let onSave: (String) -> Void
    @State private var text: String
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    init(title: String, initial: String = "", saveLabel: String? = nil, onSave: @escaping (String) -> Void) {
        self.title = title
        self.saveLabel = saveLabel ?? L("Guardar", "Save")
        self.onSave = onSave
        _text = State(initialValue: initial)
    }

    var body: some View {
        NavigationView {
            ZStack {
                BrandBackground()
                VStack(spacing: 16) {
                    TextField(L("Nombre", "Name"), text: $text)
                        .focused($focused)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(14)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                        .submitLabel(.done)
                        .onSubmit(save)
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("Cancelar", "Cancel")) { dismiss() }.foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(saveLabel, action: save)
                        .foregroundStyle(text.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.textMuted : Theme.red)
                        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear { focused = true }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onSave(trimmed)
        dismiss()
    }
}

/// Hoja para agregar una o más canciones a una playlist existente o nueva.
struct AddToPlaylistSheet: View {
    let trackIds: [String]
    @ObservedObject private var store = LibraryStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var creating = false

    var body: some View {
        NavigationView {
            ZStack {
                BrandBackground()
                List {
                    Button { creating = true } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill").foregroundStyle(Theme.red)
                            Text(L("Nueva playlist", "New playlist")).foregroundStyle(Theme.textPrimary)
                        }
                    }
                    .listRowBackground(Theme.card)

                    if store.playlists.isEmpty {
                        Text(L("Aún no tienes playlists", "You have no playlists yet"))
                            .foregroundStyle(Theme.textMuted)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(store.playlists) { playlist in
                            Button {
                                store.addTracks(trackIds, to: playlist.id)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "music.note.list").foregroundStyle(Theme.textSecondary)
                                    Text(playlist.name).foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text("\(playlist.trackIds.count)").foregroundStyle(Theme.textMuted)
                                }
                            }
                            .listRowBackground(Theme.card)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackgroundHiddenCompat()
            }
            .navigationTitle(L("Agregar a playlist", "Add to playlist"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("Cerrar", "Close")) { dismiss() }.foregroundStyle(Theme.textSecondary)
                }
            }
            .sheet(isPresented: $creating) {
                NameInputSheet(title: L("Nueva playlist", "New playlist"), saveLabel: L("Crear", "Create")) { name in
                    let playlist = store.createPlaylist(name: name)
                    store.addTracks(trackIds, to: playlist.id)
                    dismiss()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

/// Hoja con selección múltiple para agregar canciones de la biblioteca a una playlist.
struct AddSongsSheet: View {
    let playlistId: String
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var store = LibraryStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var all: [NativeTrack] = []
    @State private var query = ""
    @State private var selected = Set<String>()

    private var candidates: [NativeTrack] {
        let existing = Set(store.playlist(playlistId)?.trackIds ?? [])
        let base = all.filter { !existing.contains($0.id) }
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(q)
                || ($0.artist ?? "").localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                BrandBackground()
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundStyle(Theme.textMuted)
                        TextField(L("Buscar", "Search"), text: $query)
                            .foregroundStyle(Theme.textPrimary)
                            .autocorrectionDisabled()
                    }
                    .padding(10)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    .padding(.top, 8)

                    List {
                        ForEach(candidates) { track in
                            Button { toggle(track.id) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selected.contains(track.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selected.contains(track.id) ? Theme.red : Theme.textMuted)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.title).foregroundStyle(Theme.textPrimary).lineLimit(1)
                                        Text(track.artist ?? L("Artista desconocido", "Unknown artist"))
                                            .font(.system(size: 13)).foregroundStyle(Theme.textSecondary).lineLimit(1)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparatorTint(Theme.border)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(L("Agregar canciones", "Add songs"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("Cancelar", "Cancel")) { dismiss() }.foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(selected.isEmpty ? L("Agregar", "Add") : L("Agregar", "Add") + " (\(selected.count))") {
                        store.addTracks(Array(selected), to: playlistId)
                        dismiss()
                    }
                    .foregroundStyle(selected.isEmpty ? Theme.textMuted : Theme.red)
                    .disabled(selected.isEmpty)
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear { if all.isEmpty { all = audio.loadLibrary() } }
    }

    private func toggle(_ id: String) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }
}

extension View {
    /// Oculta el fondo del List solo en iOS 16+ (en iOS 15 no hace nada).
    @ViewBuilder func scrollContentBackgroundHiddenCompat() -> some View {
        if #available(iOS 16.0, *) { self.scrollContentBackground(.hidden) } else { self }
    }
}
