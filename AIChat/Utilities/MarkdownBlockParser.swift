import Foundation

enum MarkdownBlock: Equatable {
    case paragraph(String)
    case heading(level: Int, text: String)
    case bullet(String)
    case numbered(number: String, text: String)
    case code(language: String?, text: String)
}

/// Разбор Markdown на блоки. Строчная разметка (жирный, курсив, код) обрабатывается при отображении.
/// Незакрытый блок кода (например, во время потоковой генерации) считается кодом до конца текста.
enum MarkdownBlockParser {
    static func parse(_ source: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraphLines: [String] = []
        var codeLines: [String] = []
        var codeLanguage: String?
        var isInsideCode = false

        func flushParagraph() {
            guard !paragraphLines.isEmpty else { return }
            blocks.append(.paragraph(paragraphLines.joined(separator: "\n")))
            paragraphLines.removeAll()
        }

        for line in source.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if isInsideCode {
                if trimmed.hasPrefix("```") {
                    blocks.append(.code(language: codeLanguage, text: codeLines.joined(separator: "\n")))
                    codeLines.removeAll()
                    codeLanguage = nil
                    isInsideCode = false
                } else {
                    codeLines.append(line)
                }
                continue
            }

            if trimmed.hasPrefix("```") {
                flushParagraph()
                let language = trimmed.dropFirst(3).trimmingCharacters(in: .whitespaces)
                codeLanguage = language.isEmpty ? nil : language
                isInsideCode = true
                continue
            }

            if trimmed.isEmpty {
                flushParagraph()
            } else if let block = blockStructure(trimmed) {
                flushParagraph()
                blocks.append(block)
            } else {
                paragraphLines.append(trimmed)
            }
        }

        flushParagraph()
        if isInsideCode {
            blocks.append(.code(language: codeLanguage, text: codeLines.joined(separator: "\n")))
        }
        return blocks
    }

    private static func blockStructure(_ line: String) -> MarkdownBlock? {
        heading(line) ?? bullet(line) ?? numbered(line)
    }

    private static func heading(_ line: String) -> MarkdownBlock? {
        let level = line.prefix { $0 == "#" }.count
        guard (1...6).contains(level), line.dropFirst(level).hasPrefix(" ") else { return nil }
        return .heading(level: level, text: String(line.dropFirst(level + 1)))
    }

    private static func bullet(_ line: String) -> MarkdownBlock? {
        for marker in ["- ", "* ", "• "] where line.hasPrefix(marker) {
            return .bullet(String(line.dropFirst(marker.count)))
        }
        return nil
    }

    private static func numbered(_ line: String) -> MarkdownBlock? {
        let digits = line.prefix { $0.isNumber }
        guard !digits.isEmpty, line.dropFirst(digits.count).hasPrefix(". ") else { return nil }
        return .numbered(number: String(digits), text: String(line.dropFirst(digits.count + 2)))
    }
}
