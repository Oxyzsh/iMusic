import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var library: MusicLibrary
    @EnvironmentObject private var player: AudioPlayer

    @State private var section: LibrarySection = .all
    @State private var selectedTrackID: UUID?
    @State private var searchText = ""
    @State private var isDropTargeted = false

    private let playbackTimer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    private var currentlyPlayingTrack: MusicTrack? {
        guard let currentTrackID = player.currentTrack?.id else { return nil }
        return library.track(withID: currentTrackID) ?? player.currentTrack
    }

    private var visibleTracks: [MusicTrack] {
        let sectionTracks: [MusicTrack]
        switch section {
        case .all:
            sectionTracks = library.tracks
        case .favorites:
            sectionTracks = library.favoriteTracks
        case .recent:
            sectionTracks = library.recentlyPlayedTracks
        }

        guard !searchText.isEmpty else { return sectionTracks }
        return sectionTracks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.artist.localizedCaseInsensitiveContains(searchText)
                || $0.album.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $section)
        } detail: {
            VStack(spacing: 0) {
                toolbar
                Divider()
                trackList
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                PlayerBar(track: currentlyPlayingTrack)
            }
        }
        .frame(minWidth: 920, minHeight: 600)
        .onReceive(playbackTimer) { _ in
            player.refreshTime()
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
        }
        .alert(
            "提示",
            isPresented: Binding(
                get: { library.errorMessage != nil || player.errorMessage != nil },
                set: { if !$0 { library.errorMessage = nil; player.errorMessage = nil } }
            ),
            presenting: library.errorMessage ?? player.errorMessage
        ) { _ in
            Button("确定") { library.errorMessage = nil; player.errorMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(section.rawValue)
                    .font(.title2.weight(.semibold))
                Text("\(visibleTracks.count) 首歌曲")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            TextField("搜索歌曲、歌手或专辑", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)

            Button(action: library.requestImport) {
                Label("导入音乐", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var trackList: some View {
        Group {
            if visibleTracks.isEmpty {
                EmptyStateView(
                    title: "还没有音乐",
                    systemImage: "music.note.list",
                    message: "点击“导入音乐”，或将 MP3、M4A、MP4 文件拖到窗口中。"
                ) {
                    Button("导入音乐", action: library.requestImport)
                        .buttonStyle(.borderedProminent)
                }
            } else {
                HSplitView {
                    List(selection: $selectedTrackID) {
                        ForEach(visibleTracks) { track in
                            TrackRowView(
                                track: track,
                                isPlaying: player.currentTrack?.id == track.id && player.isPlaying,
                                onToggleFavorite: { library.toggleFavorite(for: track.id) }
                            )
                            .tag(track.id)
                            .onTapGesture(count: 2) {
                                play(track)
                            }
                            .contextMenu {
                                Button(player.currentTrack?.id == track.id && player.isPlaying ? "暂停" : "播放") {
                                    play(track)
                                }
                                Button(track.isFavorite ? "取消收藏" : "收藏") {
                                    library.toggleFavorite(for: track.id)
                                }
                                Divider()
                                Button("在访达中显示") {
                                    NSWorkspace.shared.activateFileViewerSelecting([track.url])
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                    .frame(minWidth: 520)

                    LyricsView(track: currentlyPlayingTrack, currentTime: player.currentTime)
                }
            }
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.tint, style: StrokeStyle(lineWidth: 3, dash: [8]))
                    .padding(10)
                    .allowsHitTesting(false)
            }
        }
    }

    private func play(_ track: MusicTrack) {
        selectedTrackID = track.id
        player.play(track)
        library.markAsPlayed(track.id)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                Task { @MainActor in
                    library.importURLs([url])
                }
            }
        }
        return true
    }
}
