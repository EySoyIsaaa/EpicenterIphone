import AVFoundation
import XCTest
@testable import EpicenterDSP

final class AutoEQIntegrationTests: XCTestCase {
    @MainActor
    func testEnablingAutoEQChangesAlreadyPlayingTrackAndRestoresManualCurve() async throws {
        let audio = AudioService.shared
        let repository = NativeTrackRepository()
        let id = "auto-eq-test-" + UUID().uuidString
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(id + ".caf")
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        do {
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 44100 * 20)!
            buffer.frameLength = buffer.frameCapacity
            for frame in 0..<Int(buffer.frameLength) {
                let time = Double(frame) / 44100
                let value = Float(0.03 * sin(2 * .pi * 80 * time) + 0.01 * sin(2 * .pi * 1200 * time))
                for channel in 0..<2 { buffer.floatChannelData![channel][frame] = value }
            }
            try file.write(from: buffer)
        }
        let track = NativeTrack(
            id: id, stableId: id, title: "Auto EQ regression", artist: "Test", album: nil,
            durationMs: 20000, fileName: url.lastPathComponent, fileExtension: "caf", codec: "pcm",
            qualityClass: "lossless", sourceUri: url.path, originalUrl: url.path, playbackUrl: url.path,
            optimizedUrl: nil, optimizedForPlayback: false, optimizationStatus: "ready", optimizationError: nil,
            originalBitDepth: 32, originalSampleRate: 44100, originalBitrate: nil, originalFormat: "caf",
            bookmarkData: nil, localFilePath: url.path, sourceType: "manual-ios", addedAt: Date(), updatedAt: Date(),
            sizeBytes: 7000000, sampleRate: 44100, bitDepth: 32, bitrate: nil, channelCount: 2,
            albumArtUri: nil, isAvailable: true, playCount: 0, lastPlayedAt: nil
        )
        _ = try repository.save(track)
        defer {
            _ = NativePlaybackController.shared.setQueue(trackIds: [], startIndex: 0)
            _ = NativePlaybackController.shared.stop()
            _ = try? repository.deleteTrack(id: id)
            try? FileManager.default.removeItem(at: url)
        }
        audio.setAutoEqEnabled(false)
        audio.resetEq()
        audio.setEqBand(12, 1.5)
        let manual = audio.eqBands
        audio.setEqEnabled(true)
        audio.play([track], startAt: 0)
        // Enable only AFTER this same track has been loaded and started.
        audio.setAutoEqEnabled(true)
        let applied = expectation(for: NSPredicate { _, _ in
            audio.autoEqStatus == "applied" && audio.eqBands != manual
        }, evaluatedWith: nil)
        await fulfillment(of: [applied], timeout: 15)
        print("[AutoEQ test] UI status=\(audio.autoEqStatus) bands=\(audio.eqBands)")
        XCTAssertTrue(audio.autoEqEnabled)
        XCTAssertEqual(NativePlaybackController.shared.getPlaybackState()["currentTrackId"] as? String, id)
        audio.setAutoEqEnabled(false)
        XCTAssertEqual(audio.eqBands, manual)
        XCTAssertEqual(audio.autoEqStatus, "off")
    }
}
