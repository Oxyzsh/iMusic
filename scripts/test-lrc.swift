import Foundation

@main
struct LRCSmokeTest {
    static func main() {
        let synchronized = LRCParser.parse("""
        [00:12.50]第二句
        [00:01.00]第一句
        """)

        precondition(synchronized.isSynchronized)
        precondition(synchronized.lines.map(\.text) == ["第一句", "第二句"])
        precondition(synchronized.activeLineIndex(at: 1.2) == 0)
        precondition(synchronized.activeLineIndex(at: 13) == 1)

        let plain = LRCParser.parse("第一行\n第二行")
        precondition(!plain.isSynchronized)
        precondition(plain.plainText == "第一行\n第二行")
        precondition(plain.activeLineIndex(at: 10) == nil)

        print("LRC smoke tests passed")
    }
}
