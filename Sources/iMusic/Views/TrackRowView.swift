import SwiftUI

struct TrackRowView: View {
    let track: MusicTrack
    let isPlaying: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isPlaying ? "waveform" : "music.note")
                .font(.title3)
                .foregroundStyle(isPlaying ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .lineLimit(1)
                Text("\(track.displayArtist) · \(track.displayAlbum)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(track.duration.formattedDuration)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Button(action: onToggleFavorite) {
                Image(systemName: track.isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(track.isFavorite ? .red : .secondary)
            }
            .buttonStyle(.plain)
            .help(track.isFavorite ? "取消收藏" : "收藏")
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

private extension TimeInterval {
    var formattedDuration: String {
        guard isFinite, self > 0 else { return "--:--" }
        let totalSeconds = Int(self.rounded())
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}
