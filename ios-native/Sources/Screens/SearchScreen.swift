import SwiftUI

/// Buscar en la biblioteca por título, artista o álbum.
struct SearchScreen: View {
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var loc = LocalizationStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var all: [NativeTrack] = []

    private var results: [NativeTrack] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        return all.filter {
            $0.title.localizedCaseInsensitiveContains(q)
                || ($0.artist ?? "").localizedCaseInsensitiveContains(q)
                || ($0.album ?? "").localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundStyle(Theme.textMuted)
                        TextField(L("Buscar en tu música", "Search your music"), text: $query)
                            .foregroundStyle(Theme.textPrimary)
                            .autocorrectionDisabled()
                        if !query.isEmpty {
                            Button { query = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.textMuted)
                            }
                        }
                    }
                    .padding(10)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)

                    if query.isEmpty {
                        Spacer()
                        Text(L("Escribe para buscar", "Type to search")).foregroundStyle(Theme.textMuted)
                        Spacer()
                    } else if results.isEmpty {
                        Spacer()
                        Text(L("Sin resultados", "No results")).foregroundStyle(Theme.textMuted)
                        Spacer()
                    } else {
                        SongsList(tracks: results)
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle(L("Buscar", "Search"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("Cerrar", "Close")) { dismiss() }.foregroundStyle(Theme.red)
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear { all = audio.loadLibrary() }
    }
}
