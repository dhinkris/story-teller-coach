# Storytelling Practice iOS App

A comprehensive iOS app built with SwiftUI for practicing storytelling skills through three core modules.

## Features

### 1. Story Consumption
- Browse and read/listen to stories across 5 categories:
  - Technology
  - Fashion
  - Fantasy
  - Social Interactions
  - Sports
- Toggle between reading and listening modes
- Filter stories by category
- Sample stories included for each category

### 2. Story Retelling & Analysis
- Select a story to retell
- Record your retelling using the built-in microphone
- Automatic speech-to-text transcription
- AI-powered analysis comparing your retelling to the original story
- Comprehensive metrics:
  - Similarity Score: How closely your retelling matches the original
  - Fluency Score: How smoothly you speak
  - Coherence Score: How well your ideas connect
  - Vocabulary Score: Diversity of word choice
  - Overall Score: Combined performance metric
- Personalized suggestions for improvement

### 3. Free Practice Prompts
- Generate random storytelling prompts (with optional category filtering)
- Record responses to practice prompts
- Get detailed feedback on your storytelling:
  - Story Structure
  - Fluency
  - Coherence
  - Vocabulary
- Receive actionable suggestions for improvement
- Generate new prompts to continue practicing

## Technical Details

### Architecture
- **Framework**: SwiftUI
- **Language**: Swift 5.0
- **Minimum iOS Version**: iOS 17.0

### Key Services
- `AudioRecorderService`: Handles audio recording with AVAudioRecorder
- `SpeechRecognitionService`: Transcribes audio using Speech framework
- `AudioPlayerService`: Plays audio files for story listening
- `LLMService`: Analyzes recordings and generates prompts (currently uses mock implementation with basic algorithms)

### Permissions Required
- Microphone access for recording
- Speech recognition for transcription

## Project Structure

```
StorytellingPracticeApp/
├── Models/
│   ├── Story.swift
│   ├── StoryCategory.swift
│   ├── Recording.swift
│   └── Prompt.swift
├── Views/
│   ├── StoryConsumptionView.swift
│   ├── StoryRetellingView.swift
│   └── FreePracticeView.swift
├── Services/
│   ├── AudioRecorderService.swift
│   ├── SpeechRecognitionService.swift
│   ├── AudioPlayerService.swift
│   └── LLMService.swift
├── StorytellingPracticeApp.swift
└── ContentView.swift
```

## Setup Instructions

1. Open the project in Xcode
2. Ensure you have Xcode 15.0 or later
3. Select your development team in the project settings
4. Build and run on a physical device or simulator (iOS 17.0+)

## Notes

- The LLM service currently uses mock implementations with basic text analysis algorithms
- For production use, integrate with a real LLM API (OpenAI, Anthropic, etc.) or a local model
- Image generation for prompts is currently not implemented but the structure supports it
- Audio playback for stories requires audio files to be added to the project

## Future Enhancements

- Integration with real LLM APIs for more sophisticated analysis
- Local LLM integration for offline prompt generation
- Image generation for prompts using local models
- User progress tracking and history
- Social sharing features
- Custom story creation
