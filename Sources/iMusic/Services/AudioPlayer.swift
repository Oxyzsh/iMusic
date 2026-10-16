import AVFoundation
import Combine
import Foundation

@MainActor
final class AudioPlayer: ObservableObject {
    @Published private(set) var currentTrack: MusicTrack?
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published var playbackMode: PlaybackMode = .listLoop
    @Published var errorMessage: String?

    private var player: AVPlayer?
    private var playbackQueue: [MusicTrack] = []
    private var endObserver: NSObjectProtocol?

    func play(_ track: MusicTrack, queue: [MusicTrack] = []) {
        playbackQueue = queue.isEmpty ? [track] : queue

        if currentTrack?.id != track.id {
            let item = AVPlayerItem(url: track.url)
            removeEndObserver()
            player = AVPlayer(playerItem: item)
            observeEnd(of: item)
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

    private func observeEnd(of item: AVPlayerItem) {
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handlePlaybackEnded()
            }
        }
    }

    private func handlePlaybackEnded() {
        guard let currentTrack else { return }

        switch playbackMode {
        case .singleTrack:
            restartCurrentTrack()
        case .listLoop:
            guard
                let currentIndex = playbackQueue.firstIndex(where: { $0.id == currentTrack.id }),
                !playbackQueue.isEmpty
            else {
                isPlaying = false
                return
            }

            let nextIndex = (currentIndex + 1) % playbackQueue.count
            let nextTrack = playbackQueue[nextIndex]
            if nextTrack.id == currentTrack.id {
                restartCurrentTrack()
            } else {
                play(nextTrack, queue: playbackQueue)
            }
        }
    }

    private func restartCurrentTrack() {
        guard let player else { return }
        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.currentTime = 0
                self.player?.play()
                self.isPlaying = true
            }
        }
    }

    private func removeEndObserver() {
        guard let endObserver else { return }
        NotificationCenter.default.removeObserver(endObserver)
        self.endObserver = nil
    }
}
