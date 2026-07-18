import CarPlay
import Foundation
import UIKit

/// CarPlay entry point for EpicenterDSP Player.
///
/// CarPlay audio apps are template-only (no custom UI), so this delegate builds Apple's
/// list / now-playing templates and wires them to the SAME `NativePlaybackController`
/// the phone UI uses. Transport controls (play/pause/next/previous/seek) come "for free"
/// from the already-configured `MPRemoteCommandCenter` + `MPNowPlayingInfoCenter`; here we
/// add library browsing and a custom Epicenter on/off button on the Now Playing screen.
///
/// The `@objc(CarPlaySceneDelegate)` name lets `Info.plist` reference this class without a
/// Swift module prefix (it lives inside the EpicenterNativeIos plugin module).
@objc(CarPlaySceneDelegate)
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    private var interfaceController: CPInterfaceController?
    private let repository = NativeTrackRepository()

    /// Cap the number of rows we hand to CarPlay. CarPlay throttles very long lists while
    /// driving; a few hundred keeps browsing responsive. (Pagination is a future refinement.)
    private let maxListItems = 300

    private var playback: NativePlaybackController { .shared }

    // MARK: - Scene lifecycle

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        interfaceController.setRootTemplate(makeRootTemplate(), animated: true, completion: nil)
        refreshEpicenterButton()
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
    }

    // MARK: - Library templates

    private func makeRootTemplate() -> CPTemplate {
        // A tab bar so we can grow later (playlists, albums, search). One tab for now.
        CPTabBarTemplate(templates: [makeSongsTemplate()])
    }

    private func makeSongsTemplate() -> CPListTemplate {
        let tracks = repository.loadTracks(limit: maxListItems)
        let items: [CPListItem] = tracks.map { track in
            let item = CPListItem(text: track.title, detailText: track.artist)
            item.handler = { [weak self] _, completion in
                self?.play(track: track, within: tracks)
                completion()
            }
            return item
        }

        let sections: [CPListSection]
        if items.isEmpty {
            let empty = CPListItem(text: "No hay canciones", detailText: "Agrega música desde la app")
            sections = [CPListSection(items: [empty])]
        } else {
            sections = [CPListSection(items: items)]
        }

        let template = CPListTemplate(title: "Canciones", sections: sections)
        template.tabTitle = "Canciones"
        template.tabImage = UIImage(systemName: "music.note.list")
        return template
    }

    // MARK: - Playback

    private func play(track: NativeTrack, within tracks: [NativeTrack]) {
        let ids = tracks.map { $0.id }
        let startIndex = tracks.firstIndex { $0.id == track.id } ?? 0
        _ = playback.setQueue(trackIds: ids, startIndex: startIndex)
        _ = playback.play(trackId: track.id)
        presentNowPlaying()
    }

    private func presentNowPlaying() {
        let nowPlaying = CPNowPlayingTemplate.shared
        refreshEpicenterButton()
        if interfaceController?.topTemplate !== nowPlaying {
            interfaceController?.pushTemplate(nowPlaying, animated: true, completion: nil)
        }
    }

    // MARK: - Epicenter toggle button (Now Playing)

    private func refreshEpicenterButton() {
        let enabled = isEpicenterEnabled()
        let button = CPNowPlayingImageButton(image: epicenterImage(enabled: enabled)) { [weak self] _ in
            self?.toggleEpicenter()
        }
        CPNowPlayingTemplate.shared.updateNowPlayingButtons([button])
    }

    private func toggleEpicenter() {
        _ = playback.setEpicenterEnabled(!isEpicenterEnabled())
        refreshEpicenterButton()
    }

    private func isEpicenterEnabled() -> Bool {
        let state = playback.getPlaybackState()
        guard let epicenter = state["epicenter"] as? [String: Any],
              let enabled = epicenter["enabled"] as? Bool else {
            return false
        }
        return enabled
    }

    private func epicenterImage(enabled: Bool) -> UIImage {
        let symbolName = enabled ? "waveform.circle.fill" : "waveform.circle"
        let configuration = UIImage.SymbolConfiguration(pointSize: 44, weight: .regular)
        return UIImage(systemName: symbolName, withConfiguration: configuration)
            ?? UIImage(systemName: "waveform") ?? UIImage()
    }
}
