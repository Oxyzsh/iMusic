import SwiftUI

@main
struct IMusicApp: App {
    @StateObject private var library = MusicLibrary()
    @StateObject private var player = AudioPlayer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
                .environmentObject(player)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("导入音乐") {
                    library.requestImport()
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
        }
    }
}
