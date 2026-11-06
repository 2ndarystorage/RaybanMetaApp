import Foundation

struct VoiceMemo: Codable, Identifiable, Equatable {
    var id: UUID
    var createdAt: Date
    var text: String
    var title: String { String(text.split(whereSeparator: \.isNewline).first.map(String.init)?.prefix(40) ?? "音声メモ") }
}

/// Dedicated, protected local storage. Failed reads never overwrite existing data.
struct VoiceMemoStorage {
    let url: URL

    init(url: URL? = nil) {
        self.url = url ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VoiceMemos/memos.json")
    }

    func load() throws -> [VoiceMemo] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return try JSONDecoder().decode([VoiceMemo].self, from: Data(contentsOf: url))
    }

    func save(_ memo: VoiceMemo) throws {
        guard !memo.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var memos = try load()
        memos.removeAll { $0.id == memo.id }
        memos.insert(memo, at: 0)
        try write(memos)
    }

    func delete(_ id: UUID) throws {
        try write(load().filter { $0.id != id })
    }

    private func write(_ memos: [VoiceMemo]) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(memos)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
