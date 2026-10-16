import Foundation

enum PlaybackMode: String, CaseIterable, Identifiable {
    case listLoop
    case singleTrack

    var id: String { rawValue }

    var title: String {
        switch self {
        case .listLoop: return "循环列表"
        case .singleTrack: return "单曲循环"
        }
    }

    var systemImage: String {
        switch self {
        case .listLoop: return "repeat"
        case .singleTrack: return "repeat.1"
        }
    }
}
