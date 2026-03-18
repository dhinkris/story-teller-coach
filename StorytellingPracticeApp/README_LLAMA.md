# Llama.cpp Integration Guide

This document describes how to integrate llama.cpp for language model capabilities in the Storytelling Practice App.

## Overview

The app uses llama.cpp to provide:
- **Storytelling prompt generation** - Generate creative, engaging prompts using LLM
- **Advanced feedback** - LLM-powered suggestions for story improvement
- **Text analysis** - Sophisticated analysis of storytelling quality

## Current Status

✅ **Service Layer Created**
- `LlamaService.swift` - Swift wrapper for llama.cpp
- `LlamaBridge.h` - C/C++ bridging header
- `LLMService.swift` - Updated to use LlamaService

⚠️ **Pending Integration**
- llama.cpp library needs to be built for iOS
- Model file needs to be added to the project
- Build settings need to be configured

## Architecture

```
LLMService (High-level API)
    ↓
LlamaService (llama.cpp wrapper)
    ↓
LlamaBridge.h (C/C++ interface)
    ↓
llama.cpp (C++ library)
```

## Setup Instructions

### 1. Build llama.cpp for iOS

You'll need to build llama.cpp as a static library or framework for iOS:

```bash
# Clone llama.cpp (if not already available)
git clone https://github.com/ggerganov/llama.cpp.git

# Build for iOS (example - adjust paths as needed)
cd llama.cpp
mkdir build-ios
cd build-ios
cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/ios.toolchain.cmake \
         -DPLATFORM=OS64 \
         -DENABLE_BITCODE=NO
make
```

### 2. Add llama.cpp to Xcode Project

1. Add the built library to your Xcode project
2. Link the library in Build Phases → Link Binary With Libraries
3. Add header search paths to Build Settings:
   - `Header Search Paths`: Path to llama.cpp/include
   - `Library Search Paths`: Path to built library

### 3. Configure Bridging Header

The bridging header (`LlamaBridge.h`) is already configured in the project. Ensure:
- `SWIFT_OBJC_BRIDGING_HEADER` is set to `StorytellingPracticeApp/LlamaBridge.h`
- The header file is included in the project

### 4. Add Model File

Download a compatible GGUF model (e.g., Llama 2 7B Chat):
- Place in app bundle or Documents directory
- Update `LlamaService.init()` with the correct path
- Recommended: Use a quantized model (Q4_K_M or Q5_K_M) for better performance

## Usage

### Generate Storytelling Prompts

```swift
let llmService = LLMService()
let prompt = try await llmService.generatePrompt(category: .fantasy)
```

### Analyze Story Retelling

```swift
let metrics = try await llmService.analyzeStoryRetelling(
    originalStory: original,
    userRetelling: retelling
)
// Metrics include LLM-powered suggestions
```

### Direct LlamaService Usage

```swift
let llamaService = LlamaService()
try await llamaService.loadModel()
let response = try await llamaService.generate(
    prompt: "Tell me a story",
    maxTokens: 256,
    temperature: 0.7
)
```

## Model Recommendations

For iOS devices, consider these quantized models:

| Model | Size | Quality | Speed |
|-------|------|---------|-------|
| Llama 2 7B Q4_K_M | ~4.5 GB | Good | Fast |
| Llama 2 7B Q5_K_M | ~5.2 GB | Better | Medium |
| Mistral 7B Q4_K_M | ~4.5 GB | Excellent | Fast |
| Phi-2 Q4_K_M | ~1.6 GB | Good | Very Fast |

**Note**: Larger models provide better quality but require more memory and processing time.

## Performance Considerations

- **Memory**: Models can use 2-8 GB RAM depending on size
- **Speed**: Generation speed varies (1-10 tokens/second on modern iPhones)
- **Battery**: LLM inference is CPU/GPU intensive
- **Heat**: Extended use may cause device heating

## Debug Mode

The service includes mock implementations for testing without the full library:

- In DEBUG builds, `LlamaService` returns mock responses
- Allows UI testing and development without model files
- Real implementation activates when library is linked

## Troubleshooting

### "Cannot find llama functions"
- Ensure llama.cpp library is linked
- Check bridging header is configured correctly
- Verify header search paths include llama.cpp headers

### "Model file not found"
- Check model path in `LlamaService.init()`
- Ensure model file is included in app bundle or accessible in Documents

### "Out of memory"
- Use a smaller quantized model
- Reduce context size in `llama_context_params`
- Close other apps to free memory

## Next Steps

1. Build llama.cpp for iOS
2. Add model file to project
3. Test with small prompts first
4. Optimize model size and parameters for your use case
5. Consider implementing streaming for better UX

## References

- [llama.cpp GitHub](https://github.com/ggerganov/llama.cpp)
- [GGUF Model Format](https://github.com/ggerganov/llama.cpp/blob/master/docs/GGUF.md)
- [iOS Build Guide](https://github.com/ggerganov/llama.cpp/tree/master/examples/whisper.swiftui)
