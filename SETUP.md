# Setup Guide

## Opening the Project in Xcode

1. **Open Xcode** (version 14.0 or later required, iOS 16.0+ simulators needed)

2. **Open the Project**
   - File → Open
   - Navigate to `/Users/dhinesh/Documents/app1`
   - Select `StorytellingPracticeApp.xcodeproj`
   - Click Open

3. **Add Files to Project** (if needed)
   - If Xcode doesn't automatically detect all Swift files:
     - Right-click on the project in the navigator
     - Select "Add Files to StorytellingPracticeApp..."
     - Select all Swift files in the Models, Views, and Services folders
     - Make sure "Copy items if needed" is unchecked
     - Make sure "Add to targets: StorytellingPracticeApp" is checked
     - Click Add

4. **Configure Signing**
   - Select the project in the navigator
   - Go to "Signing & Capabilities" tab
   - Select your development team
   - Xcode will automatically manage provisioning

5. **Select a Simulator or Device**
   - In the toolbar at the top of Xcode, click on the device selector (next to the Play/Stop buttons)
   - If you see "No devices", click on it and select:
     - **"Add Additional Simulators..."** if no simulators are listed
     - Or choose an existing simulator like "iPhone 15" or "iPhone 15 Pro"
   - If you need to download simulators:
     - Xcode → Settings → Platforms (or Components)
     - Download iOS 16.0+ simulator runtime
   - Alternatively, connect a physical iPhone/iPad running iOS 16.0+

6. **Build and Run**
   - With a simulator/device selected, press Cmd+R or click the Play button
   - The app should build and launch

## Troubleshooting: "No supported iOS devices are available"

If you see this error:

1. **Check Device Selector**
   - Look at the top toolbar in Xcode
   - Click the device selector dropdown (shows current device/simulator)
   - Select any available iPhone or iPad simulator

2. **Download Simulators** (if none are available)
   - Xcode → Settings (or Preferences) → Platforms tab
   - Click the "+" button
   - Download iOS 16.0 or later simulator runtime
   - Wait for download to complete

3. **Create a New Simulator**
   - Xcode → Window → Devices and Simulators
   - Click the "+" button in the bottom left
   - Choose Device Type: iPhone 15 or iPhone 15 Pro
   - Choose OS Version: iOS 16.0 or later
   - Click Create

4. **Lower Deployment Target** (if needed)
   - Select the project in navigator
   - Select the target "StorytellingPracticeApp"
   - Go to "General" tab
   - Under "Deployment Info", change "Minimum Deployments" to iOS 15.0 or 16.0
   - This allows running on older simulators

## Testing the App

### Story Consumption
- Browse stories by category
- Tap a story to read it
- Toggle between read/listen modes (audio files need to be added for listening)

### Story Retelling
- Select a story from the list
- Tap the microphone button to start recording
- Retell the story in your own words
- Tap stop to finish
- View your analysis results and suggestions

### Free Practice
- Tap "Generate Prompt" to get a random storytelling prompt
- Optionally select a category first
- Record your response
- View metrics and improvement suggestions

## Permissions

The app will request:
- **Microphone Permission**: Required for recording your storytelling
- **Speech Recognition Permission**: Required for transcribing your recordings

Make sure to grant these permissions when prompted.

## Notes

- The LLM service uses mock implementations with basic text analysis
- For production, integrate with a real LLM API (OpenAI, Anthropic, etc.)
- Audio files for stories need to be added to the project for the listen feature
- Image generation for prompts is not yet implemented
