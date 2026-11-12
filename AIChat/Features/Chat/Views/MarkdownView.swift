import SwiftUI

/// Отображает Markdown ответа ассистента: заголовки, списки, блоки кода и абзацы.
struct MarkdownView: View {
    let source: String

    var body: some View {
        let blocks = MarkdownBlockParser.parse(source)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(blocks.indices, id: \.self) { index in
                blockView(blocks[index])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .paragraph(let text):
            inlineText(text)
        case .heading(let level, let text):
            inlineText(text)
                .font(headingFont(level))
                .fontWeight(.semibold)
                .padding(.top, 4)
        case .bullet(let text):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("•")
                inlineText(text)
            }
        case .numbered(let number, let text):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(number).").monospacedDigit()
                inlineText(text)
            }
        case .divider:
            Divider()
                .padding(.vertical, 4)
        case .code(_, let text):
            ScrollView(.horizontal) {
                Text(text)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(12)
            }
            .background(
                Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: .title2
        case 2: .title3
        default: .headline
        }
    }

    private func inlineText(_ text: String) -> Text {
        Text(styled(text))
    }

    /// Строчная разметка абзаца. Текст внутри обратных кавычек выводится моноширинным шрифтом
    /// (разбор делается здесь, а не полагается на пометки системного парсера).
    /// Незакрытая кавычка (частичный ответ при потоковой генерации) не показывается.
    private func styled(_ text: String) -> AttributedString {
        let parts = text.components(separatedBy: "`")
        var result = AttributedString()
        for (index, part) in parts.enumerated() {
            if index % 2 == 1 && index < parts.count - 1 {
                var code = AttributedString(part)
                // Доступ по типу атрибута, а не через динамический key path: так код безопасен в Swift 6.
                code[AttributeScopes.SwiftUIAttributes.FontAttribute.self] = .system(.body, design: .monospaced)
                result += code
            } else {
                result += formatted(part)
            }
        }
        return result
    }

    /// Жирный и курсив внутри фрагмента. Переводы строк сохраняются.
    private func formatted(_ fragment: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        return (try? AttributedString(markdown: fragment, options: options)) ?? AttributedString(fragment)
    }
}

#Preview {
    ScrollView {
        MarkdownView(source: """
        # Заголовок
        Обычный текст с **жирным**, *курсивом* и `кодом`.
        Вторая строка того же абзаца.

        - пункт один
        - пункт два

        1. первый
        2. второй

        ```swift
        let answer = 42
        print(answer)
        ```
        """)
        .padding()
    }
}
