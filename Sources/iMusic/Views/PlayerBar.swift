import SwiftUI

struct PlayerBar: View {
    @EnvironmentObject private var player: AudioPlayer
    let track: MusicTrack?

    var body: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { player.currentTime },
                    set: { player.seek(to: $0) }
                ),
                in: 0...max(player.duration, 1)
            )
            .disabled(player.currentTrack == nil)

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(track?.title ?? "未选择歌曲")
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    Text(track?.displayArtist ?? "导入音乐后开始播放")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(width: 190, alignment: .leading)

                Spacer()

                Button(action: player.togglePlayPause) {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderedProminent)
                .disabled(player.currentTrack == nil)

                Text("\(player.currentTime.formattedDuration) / \(player.duration.formattedDuration)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .trailing)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.bar)
    }
}

private extension TimeInterval {
    var formattedDuration: String {
        guard isFinite, self > 0 else { return "--:--" }
        let totalSeconds = Int(self.rounded())
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}
