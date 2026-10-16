import Foundation

struct MusicTrack: Identifiable {
    let id: UUID
    let url: URL
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var lyrics: LyricsDocument?
    var isFavorite: Bool
    var lastPlayedAt: Date?

    init(
        id: UUID = UUID(),
        url: URL,
        title: String,
        artist: String = "未知艺术家",
        album: String = "未知专辑",
        duration: TimeInterval = 0,
        lyrics: LyricsDocument? = nil,
        isFavorite: Bool = false,
        lastPlayedAt: Date? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.lyrics = lyrics
        self.isFavorite = isFavorite
        self.lastPlayedAt = lastPlayedAt
    }

    var displayArtist: String {
        artist.isEmpty ? "未知艺术家" : artist
    }

    var displayAlbum: String {
        album.isEmpty ? "未知专辑" : album
    }
}
