import Foundation
import Speech
import AVFoundation

class SpeechRecognitionService: ObservableObject {
    @Published var transcript: String = ""
    @Published var isTranscribing: Bool = false
    @Published var error: Error?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionTask: SFSpeechRecognitionTask?

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func transcribeAudio(from url: URL) async throws -> String {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw NSError(domain: "SpeechRecognition", code: -1, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"])
        }

        recognitionTask?.cancel()
        recognitionTask = nil

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        return try await withCheckedThrowingContinuation { continuation in
            // The recognition callback can fire more than once (e.g. an error
            // after the final result); resuming a continuation twice crashes.
            var didResume = false
            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                guard !didResume else { return }

                if let error = error {
                    didResume = true
                    continuation.resume(throwing: error)
                    return
                }

                guard let result = result, result.isFinal else { return }
                didResume = true

                let text = result.bestTranscription.formattedString
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    continuation.resume(throwing: NSError(
                        domain: "SpeechRecognition",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "We couldn't hear any speech in that recording. Try again a little closer to the microphone."]
                    ))
                } else {
                    continuation.resume(returning: text)
                }
            }
        }
    }
}
