import AVFoundation
import AppKit
import Combine
import Foundation
import UniformTypeIdentifiers

@MainActor
final class MusicLibrary: ObservableObject {
    @Published private(set) var tracks: [MusicTrack] = []
    @Published var errorMessage: String?

    private let supportedExtensions: Set<String> = ["mp3", "mp4", "m4a"]

    var favoriteTracks: [MusicTrack] {
        tracks.filter(\.isFavorite)
    }

    var recentlyPlayedTracks: [MusicTrack] {
        tracks
            .filter { $0.lastPlayedAt != nil }
            .sorted { ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast) }
    }

    func requestImport() {
        let panel = NSOpenPanel()
        panel.title = "导入音乐"
        panel.message = "选择 MP3、M4A、MP4 音乐文件或文件夹"
        panel.prompt = "导入"
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.audio, .mpeg4Audio, .mpeg4Movie]

        guard panel.runModal() == .OK else { return }
        importURLs(panel.urls)
    }

    func importURLs(_ urls: [URL]) {
        let fileURLs = urls.flatMap(expandURL)
        let existingURLs = Set(tracks.map(\.url.standardizedFileURL))
        let newURLs = fileURLs
            .map(\.standardizedFileURL)
            .filter { !existingURLs.contains($0) }

        guard !newURLs.isEmpty else { return }

        for url in newURLs {
            let track = MusicTrack(
                url: url,
                title: url.deletingPathExtension().lastPathComponent
            )
            tracks.append(track)
            loadMetadata(for: track.id, url: url)
        }
    }

    func toggleFavorite(for trackID: UUID) {
        guard let index = tracks.firstIndex(where: { $0.id == trackID }) else { return }
        tracks[index].isFavorite.toggle()
    }

    func markAsPlayed(_ trackID: UUID) {
        guard let index = tracks.firstIndex(where: { $0.id == trackID }) else { return }
        tracks[index].lastPlayedAt = Date()
    }

    func track(withID id: UUID) -> MusicTrack? {
        tracks.first { $0.id == id }
    }

    private func expandURL(_ url: URL) -> [URL] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return []
        }

        if !isDirectory.boolValue {
            return isSupported(url) ? [url] : []
        }

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return enumerator.compactMap { item in
            guard let childURL = item as? URL else { return nil }
            return isSupported(childURL) ? childURL : nil
        }
    }

    private func isSupported(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }

    private func loadMetadata(for trackID: UUID, url: URL) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            let asset = AVURLAsset(url: url)
            var duration: TimeInterval = 0
            var title: String?
            var artist: String?
            var album: String?

            do {
                let loadedDuration = try await asset.load(.duration)
                if loadedDuration.isNumeric {
                    duration = loadedDuration.seconds
                }

                let metadata = try await asset.load(.commonMetadata)
                if let item = metadata.first(where: { $0.identifier == .commonIdentifierTitle }) {
                    title = try? await item.load(.stringValue)
                }
                if let item = metadata.first(where: { $0.identifier == .commonIdentifierArtist }) {
                    artist = try? await item.load(.stringValue)
                }
                if let item = metadata.first(where: { $0.identifier == .commonIdentifierAlbumName }) {
                    album = try? await item.load(.stringValue)
                }
            } catch {
                self.errorMessage = "读取“\(url.lastPathComponent)”的媒体信息失败：\(error.localizedDescription)"
            }

            guard let index = self.tracks.firstIndex(where: { $0.id == trackID }) else { return }
            self.tracks[index].duration = duration
            if let title, !title.isEmpty { self.tracks[index].title = title }
            if let artist, !artist.isEmpty { self.tracks[index].artist = artist }
            if let album, !album.isEmpty { self.tracks[index].album = album }
            self.tracks[index].lyrics = self.loadLyrics(for: url)
        }
    }

    private func loadLyrics(for musicURL: URL) -> LyricsDocument? {
        let baseURL = musicURL.deletingPathExtension()
        let candidates = [baseURL.appendingPathExtension("lrc"), baseURL.appendingPathExtension("txt")]

        for lyricsURL in candidates where FileManager.default.fileExists(atPath: lyricsURL.path) {
            if let text = try? String(contentsOf: lyricsURL, encoding: .utf8) {
                return LRCParser.parse(text)
            }
            if let text = try? String(contentsOf: lyricsURL, encoding: .utf16) {
                return LRCParser.parse(text)
            }
            if let text = try? String(contentsOf: lyricsURL, encoding: .shiftJIS) {
                return LRCParser.parse(text)
            }
        }

        return nil
    }
}
