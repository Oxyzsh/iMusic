import SwiftUI

struct LyricsView: View {
    let track: MusicTrack?
    let currentTime: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("歌词")
                    .font(.headline)
                Spacer()
                if let lyrics = track?.lyrics, lyrics.isSynchronized {
                    Text("同步歌词")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ScrollViewReader { proxy in
                ScrollView {
                    if let lyrics = track?.lyrics {
                        let activeIndex = lyrics.activeLineIndex(at: currentTime)
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(lyrics.lines) { line in
                                Text(line.text.isEmpty ? " " : line.text)
                                    .font(.title3)
                                    .foregroundStyle(line.id == activeIndex ? .primary : .secondary)
                                    .fontWeight(line.id == activeIndex ? .semibold : .regular)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id(line.id)
                            }
                        }
                        .padding(.vertical, 8)
                        .onChange(of: activeIndex) { newValue in
                            guard let newValue else { return }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(newValue, anchor: .center)
                            }
                        }
                    } else {
                        EmptyStateView(
                            title: "暂无歌词",
                            systemImage: "text.quote",
                            message: "将与音乐同名的 .lrc 或 .txt 文件放在同一目录即可自动加载。"
                        )
                    }
                }
            }
        }
        .padding(16)
        .frame(minWidth: 240)
        .background(.regularMaterial)
    }
}
