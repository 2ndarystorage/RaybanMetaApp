import Foundation

/// Emit complete JSON as soon as its data line arrives, without waiting for the next event.
/// This also accepts multi-line JSON and ignores SSE keep-alive comments.
struct VisionEventBuffer {
    private var dataLines: [String] = []

    mutating func append(_ line: String) -> String? {
        if line.isEmpty { return finishEvent() }
        guard line.hasPrefix("data:") else { return nil }
        var data = String(line.dropFirst(5))
        if data.first == " " { data.removeFirst() }
        dataLines.append(data)
        let payload = dataLines.joined(separator: "\n")
        if payload == "[DONE]" || (try? JSONSerialization.jsonObject(with: Data(payload.utf8))) != nil {
            return finishEvent()
        }
        return nil
    }

    mutating func finishEvent() -> String? {
        guard !dataLines.isEmpty else { return nil }
        defer { dataLines.removeAll(keepingCapacity: true) }
        return dataLines.joined(separator: "\n")
    }
}

/// Hold incomplete sentences across network chunks so speech is queued exactly once.
struct VisionSentenceBuffer {
    private var pending = ""

    mutating func append(_ delta: String) -> [String] {
        pending += delta
        var sentences: [String] = []
        var start = pending.startIndex
        for index in pending.indices {
            let character = pending[index]
            let next = pending.index(after: index)
            let isBoundary = "。！？!?\n".contains(character)
                || (character == "." && next < pending.endIndex && pending[next].isWhitespace)
            if isBoundary {
                let sentence = pending[start...index].trimmingCharacters(in: .whitespacesAndNewlines)
                if !sentence.isEmpty { sentences.append(sentence) }
                start = next
            }
        }
        pending = String(pending[start...])
        return sentences
    }

    mutating func finish() -> String? {
        defer { pending = "" }
        let remainder = pending.trimmingCharacters(in: .whitespacesAndNewlines)
        return remainder.isEmpty ? nil : remainder
    }
}
