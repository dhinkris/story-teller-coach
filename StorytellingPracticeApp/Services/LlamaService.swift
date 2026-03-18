import Foundation
import os.log

private let logger = Logger(subsystem: "com.storytellingpractice.app", category: "OllamaService")

/// AI text generation via a local Ollama instance.
/// Requires Ollama running at http://localhost:11434 with llama3.1:8b pulled.
class LlamaService: ObservableObject {
    @Published var isGenerating: Bool = false
    @Published var error: Error?

    private let ollamaURL = URL(string: "http://localhost:11434/api/generate")!
    private let model = "llama3.1:8b"

    func generate(prompt: String, maxTokens: Int = 256, temperature: Float = 0.7) async throws -> String {
        await MainActor.run {
            isGenerating = true
            self.error = nil
        }
        defer {
            Task { @MainActor in self.isGenerating = false }
        }

        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false,
            "options": [
                "num_predict": maxTokens,
                "temperature": Double(temperature)
            ]
        ]

        var request = URLRequest(url: ollamaURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            logger.error("Network error reaching Ollama: \(error.localizedDescription)")
            throw OllamaError.networkError(underlying: error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse
        }
        guard http.statusCode == 200 else {
            throw OllamaError.httpError(statusCode: http.statusCode)
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["response"] as? String else {
            throw OllamaError.invalidResponseFormat
        }

        logger.debug("Ollama response (\(text.count) chars)")
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func analyzeText(prompt: String, systemPrompt: String = "") async throws -> String {
        let fullPrompt = systemPrompt.isEmpty ? prompt : "\(systemPrompt)\n\n\(prompt)"
        return try await generate(prompt: fullPrompt, maxTokens: 512, temperature: 0.3)
    }

    func generateStoryPrompt(category: String? = nil) async throws -> String {
        let categoryText = category.map { " about \($0)" } ?? ""
        let prompt = """
        Generate a single compelling storytelling prompt\(categoryText). \
        Make it specific and 1–2 sentences. Output only the prompt, no quotes or preamble.
        """
        return try await generate(prompt: prompt, maxTokens: 100, temperature: 0.85)
    }
}

enum OllamaError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case invalidResponseFormat
    case networkError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Ollama."
        case .httpError(let code):
            return "Ollama returned HTTP \(code). Make sure Ollama is running."
        case .invalidResponseFormat:
            return "Unexpected response format from Ollama."
        case .networkError:
            return "Could not reach Ollama at localhost:11434. Run 'ollama serve' to start it."
        }
    }
}
