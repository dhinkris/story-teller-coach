import Foundation

enum StoryCategory: String, CaseIterable, Identifiable, Codable {
    case technology = "Technology"
    case fashion = "Fashion"
    case fantasy = "Fantasy"
    case socialInteractions = "Social Interactions"
    case sports = "Sports"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .technology: return "laptopcomputer"
        case .fashion: return "tshirt.fill"
        case .fantasy: return "sparkles"
        case .socialInteractions: return "person.2.fill"
        case .sports: return "figure.run"
        }
    }
}
