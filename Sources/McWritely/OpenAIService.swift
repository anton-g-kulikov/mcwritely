import Foundation

class OpenAIService {
    private let apiKey: String
    private let model: String = "gpt-4o-mini"
    private let systemPrompt: String = """
    You are an elite writing assistant. Correct the following text for grammar, spelling, style, and tone.
    Preserve the original meaning and formatting.
    If the text is already perfect, return it exactly as is.
    Only return the corrected text, no explanations.
    """
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Models
    
    struct OpenAIRequest: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double
        
        struct Message: Codable {
            let role: String
            let content: String
        }
    }
    
    struct OpenAIResponse: Codable {
        struct Choice: Codable {
            struct Message: Codable {
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }
    
    enum OpenAIError: LocalizedError {
        case invalidURL
        case apiError(String)
        case parsingError
        case noContent
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid API URL"
            case .apiError(let msg): return "API Error: \(msg)"
            case .parsingError: return "Failed to parse response"
            case .noContent: return "API returned no content"
            }
        }
    }
    
    func correctText(_ text: String) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody = OpenAIRequest(
            model: model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: text)
            ],
            temperature: 0.3
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIError.apiError(errorMsg)
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            guard let content = decodedResponse.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty else {
                throw OpenAIError.noContent
            }
            return content
        } catch {
            throw OpenAIError.parsingError
        }
    }
}
