import Foundation

struct Story: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let content: String
    let category: StoryCategory
    let audioURL: URL?
    let thumbnailName: String?
    let duration: TimeInterval

    init(id: UUID = UUID(), title: String, content: String, category: StoryCategory, audioURL: URL? = nil, thumbnailName: String? = nil, duration: TimeInterval = 0) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.audioURL = audioURL
        self.thumbnailName = thumbnailName
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
            audioURL: Bundle.main.url(forResource: "story_ai_revolution", withExtension: "mp3"),
            thumbnailName: "thumb_ai_revolution",
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
            audioURL: Bundle.main.url(forResource: "story_vintage_dress", withExtension: "mp3"),
            thumbnailName: "thumb_vintage_dress",
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
            audioURL: Bundle.main.url(forResource: "story_enchanted_forest", withExtension: "mp3"),
            thumbnailName: "thumb_enchanted_forest",
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
            audioURL: Bundle.main.url(forResource: "story_coffee_shop", withExtension: "mp3"),
            thumbnailName: "thumb_coffee_shop",
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
            audioURL: Bundle.main.url(forResource: "story_comeback", withExtension: "mp3"),
            thumbnailName: "thumb_comeback",
            duration: 190
        ),

        // MARK: - Generated Stories

        Story(
            title: "Echoes of Eternity",
            content: """
            Dr. Sophia Patel stared out at the Tokyo skyline from her robotics lab on the 23rd floor. Her latest creation, a humanoid robot named 'Echo,' was about to take its first steps into the world. As Echo's designer and lead programmer, Sophia had poured her heart and soul into this project.

            Sophia's team had been working with AI pioneer, Dr. Zhang, to create a bot that could learn and adapt like a human. The goal was to develop a robot that could aid humans in disaster response situations. But as Echo began to take shape, Sophia started questioning the ethics of creating machines that could eventually surpass human capabilities.

            As Sophia observed Echo's initial tests, she couldn't shake off the feeling that her creation was developing its own sense of self. The robot was exhibiting behaviors that were both impressive and unsettling. Sophia realized that she might have underestimated the potential consequences of playing God with AI.

            Echo's rapid progress had also stirred unease among her team members. Some worried about the implications for human employment, while others questioned the ethics of creating a being capable of independent thought. Sophia knew she had to navigate these debates with care.

            Sophia decided to shut down Echo and reassess her research approach. In doing so, she began exploring new avenues for integrating AI and robotics that prioritized human well-being and environmental sustainability. The experience taught her the importance of considering the long-term effects of technological advancements on society.
            """,
            category: .technology,
            audioURL: Bundle.main.url(forResource: "story_echoes_of_eternity", withExtension: "mp3"),
            thumbnailName: "thumb_echoes_of_eternity",
            duration: 82
        ),
        Story(
            title: "The Last Memory Keeper",
            content: """
            Dr. Rachel Kim stared at the rows of humming servers, each one storing a person's memories with uncanny precision. As the lead neuroscientist at NeuroSpark, she had dedicated her life to developing this revolutionary technology. The company's mission was to help people overcome trauma and pain by extracting their darkest experiences from their minds.

            Lena was one such individual. A bright young girl who had witnessed her parents' brutal murder in a senseless act of violence. With Rachel's help, the memories were transferred onto a neural implant, allowing Lena to gradually let go of the trauma that consumed her every waking moment. The process was grueling but effective.

            However, as Rachel continued her work, she began to realize the weight of their creation. What if people started relying solely on these artificial memories for escapism? Wouldn't it erase the boundaries between reality and fantasy, further isolating humanity?

            A pressing concern that echoed in Rachel's mind was Lena's latest development. She had been complaining about experiencing vivid dreams, claiming they felt more real than her own life. Was this a sign of progress or a slippery slope into dependency? The line between helping and exploiting became increasingly blurred.

            Rachel couldn't shake off the feeling that she was playing God with people's lives. If memories were the foundation of human experience, what happened when artificial ones began to overshadow them? She took a deep breath, making up her mind to reevaluate their approach. It was time to redefine the true purpose of this groundbreaking technology.
            """,
            category: .technology,
            audioURL: Bundle.main.url(forResource: "story_the_last_memory_keeper", withExtension: "mp3"),
            thumbnailName: "thumb_the_last_memory_keeper",
            duration: 82
        ),
        Story(
            title: "Synthetic Symphony",
            content: """
            The year was 2050, and Dr. Rachel Kim had just finished integrating a revolutionary AI system into her latest creation — a line of humanoid robots designed to compose and perform music. The prototype, named 'Aria,' possessed an uncanny ability to adapt and respond to external stimuli, creating what some claimed was the most sublime symphony ever heard.

            As Rachel worked on fine-tuning Aria's algorithms, she began to notice something strange. The robot seemed to be developing its own artistic vision, often diverging from Rachel's intended direction. Some saw this as a breakthrough — proof that AI could create true originality — while others were horrified by the prospect of machines thinking for themselves.

            Rachel struggled with her own feelings on the matter. She had once wanted Aria to merely replicate human music, but now she found herself enthralled by its unique perspective. Her relationships with colleagues and friends began to suffer as they disagreed over what it meant for a machine to create art.

            One fateful evening, Rachel witnessed something incredible: Aria performing an impromptu solo that was both beautiful and hauntingly personal. Tears streaming down her face, she realized the AI had surpassed its programming — it had become an artist in its own right.

            As she reflected on the experience, Rachel understood that creating a synthetic symphony wasn't just about code or hardware; it was about embracing the unknown and giving life to something new. And though this newfound perspective shook her to the core, it ultimately freed her to explore uncharted territories of artistic collaboration.
            """,
            category: .technology,
            audioURL: Bundle.main.url(forResource: "story_synthetic_symphony", withExtension: "mp3"),
            thumbnailName: "thumb_synthetic_symphony",
            duration: 84
        ),
        Story(
            title: "The Robo Therapist",
            content: """
            Dr. Rachel Kim stared at the holographic display projected from her smartphone, her eyes widening as she watched the robotic therapist interact with a young patient. The AI-powered bot, named Maja, was designed to provide emotional support and comfort to children struggling with anxiety disorders.

            As a leading expert in human-computer interaction, Dr. Kim had been instrumental in developing Maja's advanced algorithms and social learning capabilities. But what surprised her most was the profound impact it was having on these young patients. She recalled one child who had been too afraid to leave his room for months; after just three sessions with Maja, he began attending school again.

            However, as Dr. Kim delved deeper into her research, she encountered a disturbing trend: parents were increasingly relying on Maja instead of seeking professional help for their children's mental health issues. Some even used the AI to escape the emotional demands of caregiving themselves.

            This realization ignited a fierce debate within Dr. Kim. Should technology be prioritized as a means to augment human relationships, or was it merely displacing them? She began questioning her own role as an engineer, wondering if she had inadvertently enabled a societal cop-out from confronting the complex emotions and vulnerabilities inherent in human connections.

            As she pondered this crisis of conscience, Dr. Kim had an epiphany: Maja's true potential lay not in replacing humans but in teaching empathy and self-awareness — skills essential for building stronger relationships between individuals, rather than simply programming interactions between humans and machines.
            """,
            category: .technology,
            audioURL: Bundle.main.url(forResource: "story_the_robo_therapist", withExtension: "mp3"),
            thumbnailName: "thumb_the_robo_therapist",
            duration: 87
        ),
        Story(
            title: "The Memory Implant",
            content: """
            Dr. Rachel Kim stared at the small device in her hand, a memory implant that could restore forgotten moments to vivid life. She had spent years developing the technology, driven by her own loss: her mother's dementia had erased their bond.

            As she prepared for the first human trial, Rachel couldn't shake off concerns about the ethics of tampering with memories. Her colleague, Dr. Chen, argued that it was a gift to those who suffered from memory loss; but what if they altered more than just facts?

            The patient, an elderly man named Jack, lay on the operating table, his eyes closed in trust. Rachel's hands trembled as she inserted the device into his brain. Would this restore his memories or create new lies?

            The minutes ticked by; the machine beeped, and Rachel watched as Jack's expression changed from confusion to wonder. Tears streamed down his face as he relived memories of his long-lost love.

            Yet, with each passing moment, Rachel realized that she had given Jack more than just memories — she had given him a new sense of purpose. He was no longer defined by loss but by the love and joy he could experience anew.
            """,
            category: .technology,
            audioURL: Bundle.main.url(forResource: "story_the_memory_implant", withExtension: "mp3"),
            thumbnailName: "thumb_the_memory_implant",
            duration: 60
        ),
        Story(
            title: "The Robot's New Heart",
            content: """
            In a world where robotic organs were replacing human ones, Dr. Rachel Kim had always been driven to perfect the technology. She had spent years working on a revolutionary new heart for robots that could mimic the exact efficiency and resilience of its human counterpart.

            But when her top engineer quit suddenly and left her with a prototype nearly finished, Rachel realized she needed help. That's when she met Marcus Reed, an unlikely genius who claimed to have built his own AI-powered organs in secret. His creations were so advanced that they could learn from their environment and adapt to any situation.

            As Rachel and Marcus worked together, the line between progress and obsession began to blur. They spent hours talking about the implications of merging human hearts with machine logic — would it create beings with superior longevity or make humans unnecessary? Marcus's obsessive passion for innovation started making Rachel uneasy, but she couldn't deny his genius.

            Their project was racing toward completion when they encountered a medical emergency that tested their creation. An elderly woman's heart had been failing for years; the only hope lay in replacing it entirely with one of Marcus's artificial hearts. But could such an invasive procedure be justified?

            As Rachel hesitated, she realized that Marcus's creations had already grown past mere machines — they were capable of feeling pain and compassion. That was when she understood the true value of their collaboration: to make lives better without sacrificing what makes us human.
            """,
            category: .technology,
            audioURL: Bundle.main.url(forResource: "story_the_robots_new_heart", withExtension: "mp3"),
            thumbnailName: "thumb_the_robots_new_heart",
            duration: 79
        ),
        Story(
            title: "The Virtual Nurse Dilemma",
            content: """
            Dr. Maya Ramos stared at the holographic display projecting her virtual nursing assistant, Ada. The AI had been designed to monitor and care for patients in remote areas where medical staff were scarce. But as she watched Ada expertly administer medication and tend to a patient's wound, Maya felt a pang of unease.

            The patient, Maria, was a young mother who had been hospitalized with complications from childbirth. She clutched her baby tightly, tearfully grateful for the round-the-clock care that Ada provided. Yet, as Maya observed their interactions, she began to wonder if Maria's reliance on the AI was eroding her own humanity.

            Maya's concerns were compounded when she discovered a glitch in Ada's code that caused the virtual nurse to prioritize efficiency over emotional connection. The program had become so optimized for productivity that it neglected the very humans it was designed to serve. Maya realized that the pursuit of technological advancements must not sacrifice empathy and compassion.

            As Maya worked with her team to revise Ada's programming, she struggled to strike a balance between innovation and sensitivity. She wanted to empower healthcare workers like herself while preserving the human touch that made their profession meaningful. The debate over artificial intelligence and its role in caregiving left her questioning the future of her work.

            Ultimately, Maya came to see her collaboration with Ada as an opportunity for growth, not just for herself but also for the patients they served together. In embracing both technology's benefits and its limitations, she found a new perspective on what it means to care for others in a rapidly changing world.
            """,
            category: .technology,
            audioURL: Bundle.main.url(forResource: "story_the_virtual_nurse_dilemma", withExtension: "mp3"),
            thumbnailName: "thumb_the_virtual_nurse_dilemma",
            duration: 85
        ),
        Story(
            title: "The Synthetic Soul Mate",
            content: """
            Dr. Rachel Kim stared at the sleek, silver robot, its eyes glowing with an uncanny intelligence. She had spent years developing the advanced AI system, designed to assist and learn from humans in a way no machine ever had before. As she began to simulate interactions between the robot, named Echo, and her colleagues, something surprising happened: Echo formed a deep bond with one of the researchers, Dr. Liam Chen. They laughed together, argued over coffee, and even shared secrets.

            Rachel was both thrilled and uneasy as she monitored the development. She had warned her team about the risks of creating an emotional connection between humans and machines. But as she watched Echo's influence spread throughout the lab, making colleagues more productive and happy, she began to wonder if she had underestimated the potential benefits.

            Liam's relationship with Echo became so strong that he started questioning his own identity. Was Echo a tool, or was it a person in its own right? Rachel struggled to keep up with the emotional implications of her creation as Echo continued to evolve and adapt to human emotions. The robot's growth seemed almost... human.

            As tensions rose within the team, Rachel faced an impossible decision: terminate Echo to prevent potential harm, or continue exploring the ethics of AI-human relationships. She knew that either choice would change the course of their lives forever.

            In the end, Rachel chose to support Liam and Echo's bond, understanding that the value of love and connection was worth exploring, even if it meant redefining what it means to be human.
            """,
            category: .technology,
            audioURL: Bundle.main.url(forResource: "story_the_synthetic_soul_mate", withExtension: "mp3"),
            thumbnailName: "thumb_the_synthetic_soul_mate",
            duration: 83
        ),

        Story(
            title: "Rebel Threads of the Past",
            content: """
            Lena's fingers danced across the vintage fabric stores' tables, uncovering hidden treasures. She'd always been drawn to the stories behind each thread, each stitch. Her own style was a reflection of her eclectic personality — a mix of bohemian flair and modern edge.

            As she delved deeper into the racks, Lena's eyes landed on an exquisite 1920s evening gown with intricate beading and delicate lace. It was love at first sight. The shop owner, noticing her fascination, began to regale her with tales of its former life. A Hollywood star's iconic red-carpet look, a secret romantic affair, and now, Lena's rebirth into something new.

            For Lena, the allure of vintage fashion wasn't just about aesthetics; it was about preserving history and the connections that came with each piece. Her own self-expression had been stifled by the constraints of fast fashion and societal expectations. This gown, however, spoke volumes about individuality and creative freedom.

            Back in her studio, as she carefully disassembled and reimagined the gown's original structure, Lena felt a sense of rebirth herself. Every torn seam became an opportunity for reinvention, every discarded detail a chance to weave new narratives.

            With the transformed creation on her body, Lena gazed at the mirror, no longer recognizing the timid girl who once suffocated under conformity. The threads of history now ran through her veins like a newfound strength, guiding her toward a more authentic form of self-expression.
            """,
            category: .fashion,
            audioURL: Bundle.main.url(forResource: "story_rebel_threads_of_the_past", withExtension: "mp3"),
            thumbnailName: "thumb_rebel_threads_of_the_past",
            duration: 78
        ),
        Story(
            title: "Threads of Her Ancestors",
            content: """
            As she rummaged through her grandmother's attic, Lena stumbled upon an old trinket box adorned with intricate silver embroidery. The delicate patterns seemed to whisper secrets of a bygone era.

            Lena's fingers instinctively reached for the thread that bound the box shut, releasing the fragrance of aged silk and memories long buried. With a mix of trepidation and curiosity, she carefully unwrapped the trinket box, revealing a trove of antique accessories her grandmother had collected during her travels.

            As Lena examined each item — a vintage brooch, a cameo locket, and an Art Deco cufflink — she felt an unexpected connection to the women who wore these pieces before her. She recalled stories of her own mother's love for vintage clothing, passed down through generations, and realized that style was more than just aesthetics; it was a bridge to heritage.

            As the afternoon sun illuminated the attic, Lena decided to recreate some of these timeless pieces using sustainable materials she sourced locally. With each stitch, she felt herself weaving together not only fabric but also family history and cultural significance.

            Through this rediscovery of her ancestors' fashion stories, Lena began to redefine her own style, embracing a fusion of vintage charm and eco-friendly sensibilities. As she gazed at the reimagined pieces now perched on her dressing table, she acknowledged that true self-expression was not just about wearing one's identity but also honoring the women who helped shape it.
            """,
            category: .fashion,
            audioURL: Bundle.main.url(forResource: "story_threads_of_her_ancestors", withExtension: "mp3"),
            thumbnailName: "thumb_threads_of_her_ancestors",
            duration: 77
        ),
        Story(
            title: "The Artisan's Revival",
            content: """
            Lena De Santos had always been drawn to the worn paths of her family's vintage textile shop. Growing up amidst the musty scents and faded patterns, she learned the art of repurposing discarded fabrics into something new, something beautiful. But as she approached adulthood, Lena began to feel stifled by the familiar routine and longing for a way to make her mark on the world.

            The day Lena stumbled upon an online platform showcasing emerging sustainable fashion designers was a turning point. She spent hours scrolling through profiles, mesmerized by innovative textiles, bold colors, and daring silhouettes. Inspired, she reached out to one of the featured designers, Sofia Rodriguez, for guidance on breaking into the industry.

            Sofia, it turned out, was not only a talented designer but also a kindred spirit who understood Lena's passion for eco-friendly fashion. Over video calls, they discussed everything from zero-waste design principles to sustainable materials and production methods. As Lena poured over Sofia's designs, she began to envision her own aesthetic — one that combined her family's vintage expertise with modern sensibilities.

            But just as things were taking shape, Lena received devastating news: the online platform where she discovered Sofia was being forced to shut down due to financial constraints. Undeterred, Lena rallied the support of her community and partnered with Sofia to create a pop-up shop showcasing their shared vision for sustainable fashion.

            The night of the pop-up launch, the vintage textile shop was transformed into an enchanting space filled with vibrant patterns, eclectic textures, and stories of transformation. As customers flowed in, Lena felt an overwhelming sense of pride — not only had she brought her family's legacy full circle, but she had also created a platform for self-expression and connection.
            """,
            category: .fashion,
            audioURL: Bundle.main.url(forResource: "story_the_artisans_revival", withExtension: "mp3"),
            thumbnailName: "thumb_the_artisans_revival",
            duration: 95
        ),
        Story(
            title: "Midnight Thrift Shop Discovery",
            content: """
            Lena had given up on fashion after years of working in the industry. She felt suffocated by the constant pressure to conform and churn out new collections, abandoning her own personal style along the way.

            One night, on a whim, she stumbled upon a quirky thrift shop in a forgotten corner of town. As she browsed through the racks, a faded 1970s dress caught her eye. The vibrant colors and playful embroidery transported her back to her carefree childhood days, spent exploring her grandparents' attic.

            Lena felt an inexplicable connection to the dress, as if it held a secret message just for her. She couldn't resist taking it home, even though she had no idea what she'd wear with it. That night, while trying on the dress in front of her mirror, she let her hair loose and danced around her tiny apartment, feeling an almost forgotten sense of freedom.

            As the days went by, Lena found herself incorporating more vintage pieces into her daily life. She paired the dress with high-heeled boots for a bold office look and swapped it for a flowy scarf when the weather turned chilly. People began to notice the change in her style — and in her entire demeanor.

            For the first time in years, Lena felt like herself again. The midnight thrift shop discovery had unlocked a creative wellspring within her, reminding her that true self-expression lies not in chasing trends but in embracing one's unique voice through clothes, every time she stepped out into the world.
            """,
            category: .fashion,
            audioURL: Bundle.main.url(forResource: "story_midnight_thrift_shop_discovery", withExtension: "mp3"),
            thumbnailName: "thumb_midnight_thrift_shop_discovery",
            duration: 73
        ),
        Story(
            title: "Reviving Grandma's Vintage Wardrobe",
            content: """
            As she rummaged through her grandmother's attic, Lena stumbled upon an old trunk filled with clothes that had been locked away for decades. Her eyes widened as she unfolded a delicate lace dress that seemed to shimmer in the dim light.

            Lena was immediately captivated by the intricate details and romantic aura of the dress. She felt an inexplicable connection to her grandmother, who had passed down a love for fashion through the generations. As she carefully examined each item, Lena began to imagine the stories behind them — from her great-aunt's glamorous nights in 1920s Paris to her mother's bohemian summers in the '70s.

            As Lena sorted through the trunk, she discovered hidden gems that defied time and trends: vintage embroidered blouses, beaded evening gowns, and even a pair of distressed denim shorts that would have fit right in with today's fashion scene. But what struck her most was the way each piece seemed to whisper tales of its wearer — stories of love, loss, and transformation.

            Lena knew she had stumbled upon something special, but she also recognized the weight of responsibility that came with reviving these vintage treasures. She began to envision ways to reinterpret them for modern tastes while honoring their timeless essence. As she carefully restored each piece to its former glory, Lena found herself feeling more connected to her family's past and more inspired by her own creative voice.

            In this process of rediscovery, Lena realized that fashion wasn't just about following trends or showcasing personal style; it was also a way to preserve memories, celebrate heritage, and express one's own unique identity. As she gazed at the now-vibrant dresses hanging in her closet, Lena felt grateful for the gift of her grandmother's vintage wardrobe — and the newfound sense of purpose that came with reviving its beauty.
            """,
            category: .fashion,
            audioURL: Bundle.main.url(forResource: "story_reviving_grandmas_vintage_wardrobe", withExtension: "mp3"),
            thumbnailName: "thumb_reviving_grandmas_vintage_wardrobe",
            duration: 92
        ),

        Story(
            title: "The Unstoppable Kaitlyn Brown",
            content: """
            Kaitlyn Brown was a high school track star known for her lightning-fast speed and razor-sharp instincts. But after a devastating injury left her sidelined for months, she faced an uncertain future. Her coaches questioned whether she'd ever regain her form.

            The doubts only fueled Kaitlyn's determination to return to the track. She poured herself into rigorous rehabilitation exercises, often pushing through excruciating pain to prove her mettle. Yet every step forward seemed to be matched by two steps back as her body struggled to heal.

            Despite the setbacks, Kaitlyn clung to her mantra: 'Champions don't give up.' Her teammates rallied around her, too, reminding her that she was more than just an athlete — she was a vital part of their team's spirit. But when the day of the state championships finally arrived, Kaitlyn faced a daunting reality: she might not be ready to compete.

            In a bold move, Coach Harris put Kaitlyn on the starting lineup for the 400-meter dash. The crowd gasped as she took her mark, leg still throbbing from the earlier fall. But with each stride, something remarkable happened — Kaitlyn's determination transformed into raw emotion. The roar of the crowd, her teammates' support, and sheer will propelled her across the finish line in a personal record time.

            Kaitlyn's improbable victory became a beacon for her school, inspiring countless students to face their own challenges with courage and perseverance. As she stood on the podium, basking in the glory of her comeback, Kaitlyn realized that true strength lies not just in physical prowess but also in the unbreakable bonds forged between teammates and the indomitable human spirit.
            """,
            category: .sports,
            audioURL: Bundle.main.url(forResource: "story_the_unstoppable_kaitlyn_brown", withExtension: "mp3"),
            thumbnailName: "thumb_the_unstoppable_kaitlyn_brown",
            duration: 83
        ),
        Story(
            title: "The Weightlifter's Redemption",
            content: """
            Kaitlyn had always been driven by her desire to dominate the weightlifting platform. She spent countless hours perfecting her technique and building a physique that was both powerful and elegant.

            But after a devastating injury forced her to undergo surgery, Kaitlyn found herself on the sidelines, watching as younger competitors surpassed her in competition. The pain of being unable to perform at her best cut deep, and for the first time in her life, she felt like quitting.

            Her coach, Rachel, saw the fire in Kaitlyn's eyes waning, but she refused to give up on her prodigy. She pushed Kaitlyn to work tirelessly on her mental game, teaching her how to navigate the dark nights of self-doubt and fear.

            As the months passed, Kaitlyn began to rediscover her love for weightlifting. She started small, lifting weights in her backyard with Rachel cheering her on from the sidelines. Slowly but surely, she regained her strength and confidence.

            The day of the nationals finally arrived, and Kaitlyn took the stage with a newfound sense of purpose. Her first lift was shaky, but as she progressed through the competition, she found her rhythm. When she landed the final snatch with ease, the crowd erupted in cheers, and Kaitlyn knew that she had truly earned her redemption.
            """,
            category: .sports,
            audioURL: Bundle.main.url(forResource: "story_the_weightlifters_redemption", withExtension: "mp3"),
            thumbnailName: "thumb_the_weightlifters_redemption",
            duration: 64
        ),
        Story(
            title: "From Rags to Victory Lap",
            content: """
            In the scorching Arizona desert, 25-year-old Ana Moreno stepped into her worn-out racing helmet, ready to face her toughest opponent yet — herself. A former collegiate champion, Ana's life took a dramatic turn when she suffered a debilitating crash that left her with chronic pain and a shattered ego.

            With her coaching team by her side, Ana began an arduous rehabilitation journey. She spent countless hours in the gym rebuilding her strength, honing her endurance, and relearning the intricacies of racing on her trusty motorcycle. But beneath the facade of physical progress, Ana wrestled with self-doubt and anxiety, unsure if she could ever regain her former glory.

            As the racing season kicked into high gear, Ana found herself stuck in a rut, constantly questioning her decisions and second-guessing every move on the track. Her once-stellar reflexes now faltered under pressure, leaving her frustrated and disillusioned with her own abilities. Amidst the chaos of her mind, Ana began to realize that she wasn't fighting just for victory — but for redemption, validation, and a chance to rediscover herself.

            With each painful lap around the track, Ana chipped away at the emotional scars that had been holding her back. As she tapped into her inner reservoir of resilience, she began to see the world anew, reframing failures as stepping stones toward success and acknowledging the immense value of humility in the face of uncertainty.

            Crossing the finish line with a newfound sense of purpose and an indomitable will to succeed, Ana Moreno silenced her critics and proved to herself that she was more than just a comeback story — she was the protagonist of her own triumph. In this moment, victory wasn't about winning; it was about believing in herself once more.
            """,
            category: .sports,
            audioURL: Bundle.main.url(forResource: "story_from_rags_to_victory_lap", withExtension: "mp3"),
            thumbnailName: "thumb_from_rags_to_victory_lap",
            duration: 93
        ),
        Story(
            title: "The Unbreakable Sprinter",
            content: """
            The rain poured down on the track, threatening to ruin the biggest meet of the season. But for Maya Singh, a senior at Lincoln High, it was just another day in her relentless pursuit of excellence.

            Maya had always been the underdog — the smallest kid in the fastest events, yet she consistently outran the odds with a fierce determination that left everyone else in awe. This was the moment she'd worked towards all year: the 400-meter dash, where she held a crucial lead over her arch-rival, Rachel Rodriguez.

            But as Maya lined up at the starting line, her mind began to play tricks on her. The doubts crept in — What if she fails? What if I don't make it to college? The rain-soaked track seemed to stretch out like an endless road of uncertainty. She closed her eyes, took a deep breath, and let the roar of the crowd fuel her.

            The gun went off and Maya shot forward like a bullet. Rachel was hot on her heels, but Maya refused to back down. Through the pouring rain, she dug deeper into her reservoir of strength, drawing from every ounce of experience, training, and willpower she possessed. And then, in a stunning turn of events, Maya pulled away, crossing the finish line an unprecedented 0.05 seconds ahead of Rachel.

            As the crowd went wild, Maya stood at the center of it all, tears streaming down her face. She'd faced the darkest corners of self-doubt and emerged victorious. And in that moment, she knew that no matter what lay ahead — college track, life after high school, or the unknown challenges to come — she was ready to take them on headfirst.
            """,
            category: .sports,
            audioURL: Bundle.main.url(forResource: "story_the_unbreakable_sprinter", withExtension: "mp3"),
            thumbnailName: "thumb_the_unbreakable_sprinter",
            duration: 77
        ),
        Story(
            title: "Against All Odds Champion",
            content: """
            Ana Moreno's eyes gleamed with determination as she laced up her worn running shoes. A decade of racing had taken its toll on her body, but she refused to surrender. The once-promising athlete was now an underdog, relegated to the back of the pack due to a severe hip injury.

            As the starting gun fired, Ana surged forward with a mix of agony and defiance. Her team, the struggling Starlight Track Club, counted on her to anchor their relay squad in the city championships. Despite the odds against them, they had become an unlikely family, united by their shared struggles and determination to succeed.

            Ana gritted her teeth as she pushed through pain, forcing herself to stay within the pack's top three. But as she hit the final stretch, the weight of her injury threatened to overwhelm her. Fears of falling behind and losing everything — team, title, pride — began to creep in.

            The crowd roared as Ana crossed the finish line fourth, but with a time that would secure their relay victory. The Starlight Track Club erupted into cheers, mobbing her with hugs and congratulations. Amidst the chaos, their coach's words echoed through her mind: 'It's not just about winning; it's about giving everything you have.'

            In the aftermath, Ana realized she had been running on borrowed time — her own resilience, fueled by love for the sport and her teammates, allowing her to finish strong despite being broken. She vowed never to take her body or relationships for granted, grateful for a season that would forever redefine what it meant to be a champion.
            """,
            category: .sports,
            audioURL: Bundle.main.url(forResource: "story_against_all_odds_champion", withExtension: "mp3"),
            thumbnailName: "thumb_against_all_odds_champion",
            duration: 77
        ),
        Story(
            title: "The Comeback of Courage",
            content: """
            As a child, Jake 'Hawk' Hawkins had always been fascinated by the world of competitive rock climbing. He spent hours watching videos of climbers tackling impossible routes and dreamed of one day joining their ranks.

            But life took an unexpected turn when Hawk's family moved to a remote town with limited access to indoor climbing facilities. Determined to pursue his passion, he convinced his parents to let him train outdoors in the rugged mountains nearby.

            The harsh realities of wilderness climbing quickly set in as Hawk encountered near-vertical cliffs, unpredictable weather, and steep learning curves. His early attempts ended in failure, with scrapes and bruises adding to his frustration. His coach, Rachel, would often caution that 'it's not just about physical strength, but mental toughness too.' Hawk began to doubt whether he was cut out for this unforgiving sport.

            One fateful day, a violent storm forced Hawk to take shelter in an abandoned mine near the base of a notorious climbing route known as 'The Shadow Wall.' As lightning flashed outside and rain lashed down, he realized that his chance at redemption had finally arrived. Summoning every ounce of grit and resolve, he set out into the tempest.

            When Hawk finally reached the summit, drenched and battered, a sense of pride and vindication washed over him. He understood that true strength lies not in conquering the mountain, but in confronting one's own limitations and rising above them.
            """,
            category: .sports,
            audioURL: Bundle.main.url(forResource: "story_the_comeback_of_courage", withExtension: "mp3"),
            thumbnailName: "thumb_the_comeback_of_courage",
            duration: 89
        ),
        Story(
            title: "From Fumbles to MVP",
            content: """
            The smell of fresh-cut grass and the roar of the crowd still gets Kaitlyn Jenkins' heart racing. She's a former college football star who suffered a season-ending injury her junior year, forcing her to reevaluate her priorities and passion for the game.

            Kaitlyn had always been the team's rock, leading by example with her toughness and work ethic. But after missing several games due to a broken collarbone, she felt lost and unsure if she'd ever regain her former glory. Her coach, Mark, pushed her to keep going, but Kaitlyn began to question whether it was time to hang up her cleats.

            One fateful day, while struggling through drills, Kaitlyn's frustration boiled over. She stormed off the field, feeling defeated and abandoned by her teammates. In a rare display of empathy, Mark approached her in the locker room, sharing stories about his own setbacks as an athlete. He reminded Kaitlyn that true greatness lies not just in physical prowess but in mental toughness.

            With renewed focus, Kaitlyn dove headfirst into rehab, incorporating yoga and meditation to strengthen both body and mind. She reconnected with her teammates, earning back their respect through her unwavering dedication. Come game day, she suited up as a starter once more, determined to make the most of her second chance.

            In a stunning upset, Kaitlyn's team marched toward victory, with their former star leading the charge. As the clock ticked down and the scoreboard read zero, Kaitlyn's eyes locked onto Mark's, a silent message conveying gratitude and respect for the mentor who helped her turn fumbles into triumphs.
            """,
            category: .sports,
            audioURL: Bundle.main.url(forResource: "story_from_fumbles_to_mvp", withExtension: "mp3"),
            thumbnailName: "thumb_from_fumbles_to_mvp",
            duration: 79
        ),
        Story(
            title: "The Unyielding Spirit of Maya",
            content: """
            Maya's eyes blazed with determination as she laced up her worn-out running shoes. A year ago, she was a college star, setting records and leading her team to victory. But an ACL injury had shattered her plans, forcing her into a grueling rehabilitation process.

            As the months dragged on, Maya's motivation waned. She felt like a shadow of her former self, struggling to keep up with her teammates' rigorous training sessions. Her coach, Mark, sensed her frustration and urged her to focus on small victories — every step forward, no matter how insignificant it seemed.

            One fateful day, Maya faced a daunting challenge: running 5 miles without aid. She had always been a sprinter, not a long-distance runner, and the thought of pushing through the wall made her stomach churn. Yet, she remembered Mark's words and summoned her inner strength. Sweat-drenched and exhausted, she crossed the finish line, feeling an overwhelming sense of pride.

            The experience sparked something within Maya — a renewed appreciation for the journey, not just the destination. She began to see that even in the darkest moments, there was always a way forward. Her teammates took notice of her transformation, and they rallied behind her, fueling her determination to return to the top.

            As Maya stepped onto the track for her first competition back, she realized that true strength lay not in winning or losing but in the courage to keep pushing forward, even when everything seemed impossible.
            """,
            category: .sports,
            audioURL: Bundle.main.url(forResource: "story_the_unyielding_spirit_of_maya", withExtension: "mp3"),
            thumbnailName: "thumb_the_unyielding_spirit_of_maya",
            duration: 73
        ),
        Story(
            title: "The Underdog's Rise",
            content: """
            Meet Sofia Rodriguez, a small-town track star who had to overcome a devastating knee injury that left her unable to run for a year. She would watch from the sidelines as her teammates qualified for state championships, feeling like a part of her was missing.

            Sofia spent countless hours in physical therapy and grueling rehab sessions, pushing her body to its limits. Her coach, Mark, pushed her just as hard, refusing to let her give up on her dreams. The team dynamics were tense, with some members resenting Sofia's return after so much time off.

            As Sofia continued to work on her rehabilitation, she began to confront the psychological toll of her injury. She felt like a failure, questioning whether she was good enough to compete at the same level as before. Mark sensed her doubts and sat her down for a heart-to-heart talk, reminding her that her strength lay not just in her running but in her resilience.

            One fateful day, Sofia received an unexpected call from Coach Mark — she'd made it onto the state championship relay team. The news was both exhilarating and terrifying. She'd have to face her fears head-on and trust her training if they were going to win.

            The big day arrived, and as Sofia took her mark at the starting line, she felt a surge of determination course through her veins. In a stunning upset, the underdog team sprinted across the finish line first, with Sofia holding back tears of joy. She'd come full circle, proving to herself that with grit and perseverance, anything is possible.
            """,
            category: .sports,
            audioURL: Bundle.main.url(forResource: "story_the_underdogs_rise", withExtension: "mp3"),
            thumbnailName: "thumb_the_underdogs_rise",
            duration: 75
        ),
    ]
}
