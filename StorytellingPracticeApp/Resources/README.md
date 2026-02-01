# Resources Folder Structure

This folder contains all media assets for the Storytelling Practice app.

## Complete Folder Structure

```
Resources/
├── Images/
│   ├── Stories/          # Story illustrations and covers
│   ├── Prompts/          # Images for storytelling prompts
│   └── Icons/            # Custom icon images
├── Audio/
│   ├── Stories/          # Audio narrations for stories
│   └── Background/       # Background music and ambient sounds
├── Video/
│   └── Tutorials/        # Video tutorials and guides
└── GIFs/
    ├── Animations/        # Animated GIFs for UI elements
    └── Loading/          # Loading indicators and spinners
```

## Folder Organization

### 📁 Images
- **Location**: `Resources/Images/`
- **Supported formats**: PNG, JPEG, HEIC, SVG (via SF Symbols)
- **Usage**: 
  - Add images to Xcode project
  - Reference in code: `Image("imageName")` or `UIImage(named: "imageName")`
  - For story illustrations, prompt images, icons, etc.

**Subfolders:**
- `Images/Stories/` - Story-related images (covers, illustrations)
- `Images/Prompts/` - Images generated for storytelling prompts
- `Images/Icons/` - Custom icon images (if not using SF Symbols)

### 🎵 Audio
- **Location**: `Resources/Audio/`
- **Supported formats**: M4A, MP3, WAV, CAF
- **Usage**:
  ```swift
  let url = Bundle.main.url(forResource: "audioName", withExtension: "m4a")
  ```
  - For story narrations, background music, sound effects

**Subfolders:**
- `Audio/Stories/` - Audio narrations for each story
- `Audio/Background/` - Background music and ambient sounds

### 🎬 Video
- **Location**: `Resources/Video/`
- **Supported formats**: MP4, MOV, M4V
- **Usage**:
  ```swift
  let url = Bundle.main.url(forResource: "videoName", withExtension: "mp4")
  ```
  - For video tutorials, demonstrations, etc.

**Subfolders:**
- `Video/Tutorials/` - Tutorial videos and guides

### 🎞️ GIFs
- **Location**: `Resources/GIFs/`
- **Supported formats**: GIF
- **Usage**: 
  - May require third-party library for display
  - Consider converting to video for better performance
  - For animations, loading indicators, etc.

**Subfolders:**
- `GIFs/Animations/` - Animated GIFs for UI elements
- `GIFs/Loading/` - Loading indicators and spinners

## Adding Files to Xcode

1. **Drag and drop** files into the appropriate folder in Xcode
2. **Ensure** "Copy items if needed" is checked
3. **Verify** the target membership (StorytellingPracticeApp should be checked)
4. **For images**: Consider adding to Assets.xcassets for better organization

## Best Practices

- **Naming**: Use descriptive, lowercase names with underscores (e.g., `story_ai_revolution.m4a`)
- **Organization**: Group related files by feature or category
- **Size**: Optimize files for mobile (compress images, use appropriate audio/video bitrates)
- **Assets Catalog**: For frequently used images, add them to `Assets.xcassets` instead

## File Size Considerations

- **Images**: Keep under 2MB each, use compressed formats
- **Audio**: Use M4A (AAC) for best compression/quality ratio
- **Video**: Compress videos appropriately for mobile viewing
- **GIFs**: Consider converting large GIFs to video format
