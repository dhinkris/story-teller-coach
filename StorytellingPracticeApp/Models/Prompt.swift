import Foundation
import SwiftUI
import UIKit

struct StoryPrompt: Identifiable, Codable {
    let id: UUID
    let text: String
    let imageData: Data?
    let category: StoryCategory?
    let createdAt: Date
    
    init(id: UUID = UUID(), text: String, imageData: Data? = nil, category: StoryCategory? = nil, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.imageData = imageData
        self.category = category
        self.createdAt = createdAt
    }
    
    var image: Image? {
        guard let imageData = imageData,
              let uiImage = UIImage(data: imageData) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
}

extension StoryPrompt {
    static let samplePrompts = [
        StoryPrompt(
            text: "Tell a story about a person who discovers a hidden talent they never knew they had.",
            category: .fantasy
        ),
        StoryPrompt(
            text: "Describe a day in the life of someone living in a world where technology has solved all major problems.",
            category: .technology
        ),
        StoryPrompt(
            text: "Narrate an encounter between two strangers that changes both of their lives forever.",
            category: .socialInteractions
        )
    ]
}
