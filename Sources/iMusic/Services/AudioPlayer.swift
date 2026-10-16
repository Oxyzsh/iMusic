import AVFoundation
import Combine
import Foundation

@MainActor
final class AudioPlayer: ObservableObject {
    @Published private(set) var currentTrack: MusicTrack?
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published var errorMessage: String?

    private var player: AVPlayer?

    func play(_ track: MusicTrack) {
        if currentTrack?.id != track.id {
            let item = AVPlayerItem(url: track.url)
            player = AVPlayer(playerItem: item)
            currentTrack = track
            currentTime = 0
            duration = track.duration

            Task { @MainActor [weak self, weak item] in
                guard let self, let item else { return }
                do {
                    let loadedDuration = try await item.asset.load(.duration)
                    if loadedDuration.isNumeric {
                        self.duration = loadedDuration.seconds
                    }
                } catch {
                    self.errorMessage = "无法读取音频时长：\(error.localizedDescription)"
                }
            }
        }

        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func togglePlayPause() {
        guard currentTrack != nil else { return }
        if isPlaying {
            pause()
        } else {
            player?.play()
            isPlaying = true
        }
    }

    func seek(to time: TimeInterval) {
        guard let player else { return }
        let boundedTime = max(0, min(time, duration > 0 ? duration : time))
        player.seek(
            to: CMTime(seconds: boundedTime, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
        currentTime = boundedTime
    }

    func refreshTime() {
        guard let player else { return }
        let seconds = player.currentTime().seconds
        guard seconds.isFinite else { return }

        currentTime = max(0, seconds)
        if duration > 0, currentTime >= duration - 0.2, player.timeControlStatus != .playing {
            currentTime = duration
            isPlaying = false
        } else {
            isPlaying = player.timeControlStatus == .playing
        }
    }
}
