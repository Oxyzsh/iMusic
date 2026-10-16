import SwiftUI

enum LibrarySection: String, CaseIterable, Identifiable {
    case all = "全部歌曲"
    case favorites = "收藏"
    case recent = "最近播放"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .all: return "music.note.list"
        case .favorites: return "heart"
        case .recent: return "clock"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: LibrarySection

    var body: some View {
        List(selection: $selection) {
            Section("音乐库") {
                ForEach(LibrarySection.allCases) { section in
                    Label(section.rawValue, systemImage: section.systemImage)
                        .tag(section)
                }
            }
        }
        .navigationTitle("iMusic")
        .listStyle(.sidebar)
    }
}
