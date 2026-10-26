import AVFoundation
import AudioToolbox
import Foundation

/// Executed on macOS against the same queue, policy and analyzer sources as iOS.
@main
enum NativeRegressionChecks {
    static func main() throws {
        queueActions()
        automaticTuning()
        try boundedFileAnalysis()
        print("Native queue, automatic tuning and file analysis checks passed")
    }

    private static func queueActions() {
        let queue = NativeQueueManager()
        queue.setQueue(trackIds: ["past", "current", "a", "b", "c"], startIndex: 1)
        queue.enqueue(["c"], playNext: true)
        precondition(queue.trackIds == ["past", "current", "c", "a", "b"])
        precondition(queue.currentTrackId == "current")

        queue.enqueue(["a"], playNext: false)
        precondition(queue.trackIds == ["past", "current", "c", "b", "a"])
        queue.enqueue(["past", "new", "new"], playNext: true)
        precondition(queue.trackIds == ["current", "past", "new", "c", "b", "a"])
        precondition(queue.currentIndex == 0)
        queue.enqueue(["current"], playNext: false)
        precondition(queue.currentTrackId == "current" && queue.currentIndex == 0)

        // Auto-next has already advanced when a stale drag/remove arrives.
        queue.setCurrentIndex(2)
        queue.reorderUpcoming(["a", "current", "past", "b", "c"])
        precondition(queue.trackIds == ["current", "past", "new", "a", "b", "c"])
        queue.removeUpcoming(["current", "new", "b"])
        precondition(queue.trackIds == ["current", "past", "new", "a", "c"])
        precondition(queue.currentTrackId == "new")
        queue.setRepeatMode(.all)
        precondition(queue.nextCandidateIndices(wrapping: true) == [3, 4, 0, 1])
    }

    private static func automaticTuning() {
        // Identical clipped EQ curves must still yield different Epicenter
        // tuning when the original recordings have different bass profiles.
        var gains = [Float](repeating: 0, count: 31)
        for band in 2...9 { gains[band] = -6 }
        let lean = NativeAudioAnalysis(gains: gains, bassRelativeDb: 2, deepBassRatio: 0.15, bassCentroidHz: 115)
        let rich = NativeAudioAnalysis(gains: gains, bassRelativeDb: 26, deepBassRatio: 0.7, bassCentroidHz: 65)
        for headphones in [false, true] {
            let leanSettings = NativeAutoAdjustment.epicenter(analysis: lean, headphones: headphones)!
            let richSettings = NativeAutoAdjustment.epicenter(analysis: rich, headphones: headphones)!
            precondition(leanSettings.intensity > richSettings.intensity)
            precondition(leanSettings.sweep != richSettings.sweep)
            precondition(leanSettings.width != richSettings.width)
            precondition((0...100).contains(leanSettings.intensity))
            precondition((27...63).contains(leanSettings.sweep))
        }
        gains[0] = .nan
        precondition(!NativeAutoAdjustment.accepts(gains))
    }

    private static func boundedFileAnalysis() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        for sampleRate in [44_100.0, 192_000.0] {
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
            let url = directory.appendingPathComponent("tone-\(Int(sampleRate)).caf")
            // Two seconds, written in blocks like streaming playback.
            do {
                let file = try AVAudioFile(forWriting: url, settings: format.settings)
                let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4096)!
                var position = 0
                while position < Int(sampleRate * 2) {
                    let count = min(4096, Int(sampleRate * 2) - position)
                    buffer.frameLength = AVAudioFrameCount(count)
                    for frame in 0..<count {
                        let time = Double(position + frame) / sampleRate
                        let sample = Float(0.25 * sin(2 * .pi * 80 * time) + 0.1 * sin(2 * .pi * 1200 * time))
                        for channel in 0..<2 { buffer.floatChannelData![channel][frame] = sample }
                    }
                    try file.write(from: buffer)
                    position += count
                }
            }
            let gains = EpicenterAutoEQAnalyzer.computeGains(fileURL: url)
            precondition(gains != nil && NativeAutoAdjustment.accepts(gains!))
            if sampleRate == 44_100 {
                for codec in [kAudioFormatMPEG4AAC, kAudioFormatAppleLossless] {
                    let compressedURL = directory.appendingPathComponent("compressed-\(codec).m4a")
                    do {
                        let input = try AVAudioFile(forReading: url)
                        let output = try AVAudioFile(forWriting: compressedURL, settings: [
                            AVFormatIDKey: codec,
                            AVSampleRateKey: sampleRate,
                            AVNumberOfChannelsKey: 2,
                        ])
                        let block = AVAudioPCMBuffer(pcmFormat: input.processingFormat, frameCapacity: 4096)!
                        while input.framePosition < input.length {
                            try input.read(into: block, frameCount: 4096)
                            if block.frameLength == 0 { break }
                            try output.write(from: block)
                        }
                    }
                    let profile = EpicenterAutoEQAnalyzer.analyze(fileURL: compressedURL)
                    precondition(profile?.isValid == true, "Compressed file analysis failed")
                }
            }
        }
    }
}
