import Foundation

/// Настройки подключения к AI-провайдеру. Модель и адрес задаются здесь, а не в логике сервиса.
struct APIConfiguration: Sendable {
    let apiKey: String?
    let model: String
    let endpoint: URL?

    static var current: APIConfiguration {
        APIConfiguration(
            apiKey: decodeKey(GeneratedSecrets.obfuscatedKey, mask: GeneratedSecrets.mask),
            model: GeneratedSecrets.model,
            endpoint: URL(string: "https://openrouter.ai/api/v1/chat/completions")
        )
    }

    /// Восстанавливает ключ из обфусцированного вида. Пустой ключ даёт nil.
    static func decodeKey(_ bytes: [UInt8], mask: [UInt8]) -> String? {
        guard !bytes.isEmpty, !mask.isEmpty else { return nil }
        let decoded = bytes.enumerated().map { index, byte in byte ^ mask[index % mask.count] }
        return String(bytes: decoded, encoding: .utf8)
    }
}
