import Foundation
import os.log

private let logger = Logger(subsystem: "com.storytellingpractice.app", category: "KokoroTTS")

/// Calls a local Kokoro FastAPI server (OpenAI-compatible TTS endpoint).
/// Default: http://localhost:8880/v1/audio/speech
class KokoroTTSService: ObservableObject {
    @Published var isGenerating = false
    @Published var generationError: String? = nil

    // MARK: - Configuration
    private let baseURL: URL
    private let voice: String
    private let speed: Double

    init(
        host: String = "http://localhost:8880",
        voice: String = "af_heart",
        speed: Double = 0.9
    ) {
        self.baseURL = URL(string: "\(host)/v1/audio/speech")!
        self.voice = voice
        self.speed = speed
    }

    // MARK: - Public API

    /// Returns a cached local MP3 URL for the story, generating it if needed.
    func audioURL(for story: Story) async -> URL? {
        let cached = cacheURL(for: story)
        if FileManager.default.fileExists(atPath: cached.path) {
            logger.info("Cache hit: \(story.title)")
            return cached
        }
        logger.info("Generating audio for: \(story.title)")
        return await generate(text: story.content, saveTo: cached)
    }

    /// Forces re-generation even if a cached file exists.
    func regenerate(for story: Story) async -> URL? {
        clearCache(for: story)
        return await audioURL(for: story)
    }

    func clearCache(for story: Story) {
        try? FileManager.default.removeItem(at: cacheURL(for: story))
    }

    func clearAllCache() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: docs, includingPropertiesForKeys: nil
        ) else { return }
        for file in files where file.lastPathComponent.hasPrefix("story_audio_") && file.pathExtension == "mp3" {
            try? FileManager.default.removeItem(at: file)
        }
    }

    // MARK: - Private

    private func generate(text: String, saveTo destination: URL) async -> URL? {
        await MainActor.run { isGenerating = true; generationError = nil }
        defer { Task { @MainActor in self.isGenerating = false } }

        let body: [String: Any] = [
            "model": "kokoro",
            "input": text,
            "voice": voice,
            "response_format": "mp3",
            "speed": speed
        ]

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 180   // stories can be ~1000 words
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                let msg = "Kokoro returned HTTP \(code)"
                logger.error("\(msg)")
                await MainActor.run { self.generationError = msg }
                return nil
            }
            try data.write(to: destination, options: .atomic)
            logger.info("Saved \(data.count / 1024) KB → \(destination.lastPathComponent)")
            return destination
        } catch is CancellationError {
            logger.info("Generation cancelled for task")
            return nil
        } catch {
            logger.error("Kokoro request failed: \(error.localizedDescription)")
            await MainActor.run { self.generationError = error.localizedDescription }
            return nil
        }
    }

    private func cacheURL(for story: Story) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("story_audio_\(story.id.uuidString).mp3")
    }
}
