# Storytelling Practice App — CLAUDE.md

## Project Overview

An iOS SwiftUI app that helps users build storytelling and public-speaking skills through:
- **Library**: Read/listen to curated stories across 5 genres
- **Retell**: Record a story retelling and receive AI-powered craft feedback
- **Practice**: Generate random prompts for open-ended storytelling sessions
- **Journey**: Track skill progress over time with charts and session history

**Bundle ID:** `com.storytellingpractice.app`
**Deployment Target:** iOS 16.0+
**Language:** Swift 5.0+
**Build:** Xcode only — open `StorytellingPracticeApp.xcodeproj`

---

## Architecture

**Pattern:** MVVM + layered services

```
Views (SwiftUI)
  └── Services (ObservableObject + async/await)
        ├── LLMService         — text analysis & prompt generation (NaturalLanguage.framework)
        ├── LlamaService       — llama.cpp wrapper (MOCK mode; real integration pending)
        ├── AudioRecorderService  — AVAudioRecorder, saves M4A to Documents/
        ├── SpeechRecognitionService — Apple Speech.framework, en-US only
        ├── AudioPlayerService — AVAudioPlayer
        └── ProgressDataService — UserDefaults persistence
```

**No external package manager** — zero CocoaPods/SPM dependencies. All frameworks are native iOS.

---

## Key Files

| Path | Purpose |
|------|---------|
| `StorytellingPracticeApp/ContentView.swift` | Root TabView (Library · Retell · Practice · Journey) |
| `StorytellingPracticeApp/Utilities/ClaymorphismStyle.swift` | **Design system** — all colors, modifiers, score helpers, category theme colors |
| `StorytellingPracticeApp/Models/` | `Story`, `StoryCategory`, `Recording`, `StoryMetrics`, `ProgressRecord`, `StoryPrompt` |
| `StorytellingPracticeApp/Services/LLMService.swift` | Core analysis: similarity, fluency, coherence, vocabulary scoring |
| `StorytellingPracticeApp/Services/LlamaService.swift` | llama.cpp wrapper — currently in mock mode |
| `StorytellingPracticeApp/LlamaBridge.h` | ObjC bridging header for llama.cpp C functions |
| `StorytellingPracticeApp/README_LLAMA.md` | Integration guide for llama.cpp |
| `whisper.cpp/` | OpenAI Whisper C++ library — present but **not linked** to the Xcode project |

---

## Design System

All UI styling lives in `ClaymorphismStyle.swift`. Do not inline colors or shadow values elsewhere.

**Color tokens:**
- `Color.clayBackground` — warm cream app background
- `Color.clayCard` — white card surface
- `Color.claySurface` — subtle off-white for inner containers
- `Color.clayAccent` / `Color.clayAccentLight` — deep indigo primary
- `Color.clayGold` / `Color.clayGoldLight` — amber for achievements
- `Color.claySuccess` / `Color.clayDanger` — semantic green/red

**Per-category colors:** Access via `category.themeColor` and `category.themeGradient` (defined as an extension on `StoryCategory` in `ClaymorphismStyle.swift`).

**Shared modifiers:**
- `.clayCard(cornerRadius:padding:)` — white card with dual neuomorphic shadows
- `.clayButton(isSelected:cornerRadius:)` — gradient when selected, plain card when not
- `.claySurface(cornerRadius:)` — subtle surface fill

**Score display:**
- `performanceLabel(for: Double) -> String` — "Masterful / Polished / Compelling / Developing / Keep Going"
- `performanceColor(for: Double) -> Color` — matching color for the label
- Use these everywhere scores are shown; do not hardcode `"green"/"orange"/"red"` logic.

**Shared button style:** `ScaleButtonStyle` (press shrinks to 0.97×) — defined in `ClaymorphismStyle.swift`.

---

## Metric Terminology

When displaying analysis results, use these storytelling-specific names (not generic labels):

| Underlying field | Display name (Retell tab) | Display name (Practice tab) |
|---|---|---|
| `similarityScore` | Story Fidelity | Narrative Arc |
| `fluencyScore` | Delivery | Delivery |
| `coherenceScore` | Narrative Flow | Story Flow |
| `vocabularyScore` | Expression | Word Choice |

---

## Pending / Incomplete

- **LlamaService** — mock mode only; real llama.cpp not compiled or linked
- **whisper.cpp** — present in repo root but not integrated; app uses Apple `Speech.framework` instead
- **Audio files** — `Resources/Audio/` placeholder only; stories have no real audio yet (listen mode shows "unavailable")
- **Image prompts** — `StoryPrompt.imageData` field exists but no image-capture UI
- **Cross-tab navigation** — no shared app state for "Start Retelling" CTA from Library → Retell tab

---

## Coding Conventions

- All async work uses `async/await`; no completion handlers
- Services are `ObservableObject`; views hold them with `@StateObject`
- Prefer `@MainActor.run { }` for UI updates inside async tasks
- Do not add mocks or test data outside of `DEBUG` guards
- Keep views thin — logic belongs in the service layer
- Tab names: **Library, Retell, Practice, Journey** (not Stories/Retelling/Free Practice/Progress)
