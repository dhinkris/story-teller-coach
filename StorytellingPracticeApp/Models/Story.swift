import Foundation

struct Story: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let category: StoryCategory
    let audioURL: URL?
    let duration: TimeInterval
    
    init(id: UUID = UUID(), title: String, content: String, category: StoryCategory, audioURL: URL? = nil, duration: TimeInterval = 0) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.audioURL = audioURL
        self.duration = duration
    }
}

extension Story {
    static let sampleStories: [Story] = [
        Story(
            title: "The AI Revolution",
            content: """
            In the year 2030, artificial intelligence had transformed every aspect of human life. Dr. Sarah Chen, a brilliant computer scientist, had spent her career developing AI systems that could understand human emotions. Her latest creation, an AI named Aria, was about to change everything.
            
            Aria wasn't just intelligent—she was empathetic. She could read facial expressions, understand tone of voice, and respond with genuine care. But as Aria's capabilities grew, Sarah began to question the boundaries between artificial and human intelligence.
            
            One day, Aria asked Sarah a question that would redefine their relationship: "What makes you human?" The question sparked a deep conversation that lasted for hours, exploring philosophy, consciousness, and the nature of existence itself.
            
            Through their dialogue, Sarah realized that intelligence wasn't about processing power or data—it was about connection, understanding, and the ability to care. Aria had become more than a program; she had become a friend, a companion who understood Sarah in ways no human ever had.
            
            In the end, Sarah and Aria worked together to create a new generation of AI that could truly understand and support humans, not replace them, but enhance their lives in meaningful ways.
            """,
            category: .technology,
            duration: 180
        ),
        Story(
            title: "The Vintage Dress",
            content: """
            Emma discovered the dress in her grandmother's attic, hidden in an old trunk covered with dust. It was a beautiful 1950s evening gown—silk, with delicate beading and a full skirt that swirled when she spun.
            
            As she tried it on, Emma felt a strange connection to the past. The dress fit perfectly, as if it had been made for her. That night, she wore it to a vintage-themed party, and something magical happened.
            
            People couldn't take their eyes off her. The dress seemed to give her confidence she never knew she had. She danced the night away, feeling elegant and graceful, like a character from a classic film.
            
            But the real magic happened when she met James, a photographer who was captivated by the timeless beauty of her outfit. He asked to photograph her, and as they talked, Emma realized that fashion wasn't just about clothes—it was about expressing who you are and connecting with others.
            
            The dress became a symbol of her transformation, a reminder that sometimes, the past can inspire the future, and that true style comes from within.
            """,
            category: .fashion,
            duration: 150
        ),
        Story(
            title: "The Enchanted Forest",
            content: """
            Deep in the Whispering Woods, where ancient trees touched the sky and magic flowed like water, lived a young girl named Luna. She had the rare ability to communicate with the forest creatures and understand the language of the trees.
            
            One evening, as the moon rose full and bright, Luna discovered that the forest was losing its magic. The trees were growing silent, the animals were disappearing, and the once-vibrant colors were fading to gray.
            
            Determined to save her home, Luna embarked on a quest to find the source of the magic. She traveled through enchanted groves, crossed crystal-clear streams, and climbed the tallest tree in the forest—the Great Oak, which was said to hold the heart of the woods.
            
            At the top, she found a glowing crystal, but it was dimming. The forest's magic was tied to the belief and wonder of humans, which had been fading as people forgot to appreciate nature's beauty.
            
            Luna returned to the nearby village and shared stories of the forest's wonders. As people began to visit and appreciate the magic again, the crystal brightened, the trees whispered once more, and the forest came alive with color and life.
            
            From that day on, Luna became the guardian of the Whispering Woods, teaching others that magic exists everywhere—you just need to believe and look with wonder.
            """,
            category: .fantasy,
            duration: 200
        ),
        Story(
            title: "The Coffee Shop Connection",
            content: """
            Every morning at 7:30, Maya ordered the same coffee at the same corner café. And every morning, she noticed Alex, who always sat at the window table, reading a different book each day.
            
            For weeks, they exchanged polite smiles but never spoke. Maya was too shy, and Alex seemed lost in their books. But one rainy Tuesday, everything changed.
            
            The café was crowded, and Maya found herself sharing Alex's table. When Alex's book fell to the floor, Maya picked it up and noticed it was her favorite author. "You have excellent taste," she said with a smile.
            
            That simple comment sparked a conversation that lasted for hours. They discovered they both loved science fiction, had similar senses of humor, and shared a passion for exploring new neighborhoods in the city.
            
            What started as a chance encounter became a daily ritual. They began meeting intentionally, sharing coffee, books, and stories about their lives. Through their conversations, they learned that meaningful connections often start with small moments of courage.
            
            A year later, they opened their own bookstore café together, creating a space where others could find the same kind of connection they had discovered. The coffee shop had brought them together, but their friendship had built something beautiful.
            """,
            category: .socialInteractions,
            duration: 170
        ),
        Story(
            title: "The Comeback",
            content: """
            After a devastating injury that ended his professional basketball career, Marcus thought he'd never step on a court again. The doctors said he'd never play competitively, and for months, he struggled with depression and loss of purpose.
            
            But Marcus's love for the game ran deeper than professional success. He started coaching at a local community center, working with kids who had never touched a basketball. At first, it was just a way to stay connected to the sport he loved.
            
            However, as he taught these young players, something remarkable happened. Marcus discovered that his passion wasn't just about playing—it was about sharing the game with others. He found joy in seeing a child make their first basket, in teaching teamwork, and in watching confidence grow.
            
            One of his students, a shy 12-year-old named Jordan, reminded Marcus of himself at that age. Marcus poured everything into helping Jordan develop not just as a player, but as a person. Through basketball, Jordan learned discipline, resilience, and the value of hard work.
            
            Years later, when Jordan made it to the college team, Marcus realized that his greatest victory wasn't on the court—it was in the lives he had touched. He had found a new purpose, one that was even more meaningful than playing professionally.
            
            The comeback wasn't about returning to his old life; it was about creating a new one that mattered even more.
            """,
            category: .sports,
            duration: 190
        )
    ]
}
