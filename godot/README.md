# DotAI - AI-Powered Game Development Platform

**DotAI** is an AI-native game engine built on Godot Engine, enabling developers to create complete games through natural language conversations with Claude AI. Think of it as "Cursor for Game Engines" - an intelligent development environment where AI is a first-class collaborator.

## 🎮 What is DotAI?

DotAI transforms Godot Engine into an AI-powered game development platform where you can:

- **Build games by describing them** - "Create a 2D platformer with jumping and enemies"
- **Generate complete, production-ready code** - Not just snippets, but full game systems
- **Automatic file creation** - AI generates and saves files directly to your project
- **Codebase awareness** - AI understands your entire project structure and context
- **Conversational development** - Have a dialogue with AI about your game design

## ✨ Key Features

### 🤖 AI-Powered Code Generation
- Natural language to GDScript conversion
- Multi-file generation (scripts, scenes, resources)
- Production-ready code with proper structure
- Automatic file saving and project integration

### 📚 Codebase Awareness
- Full project scanning and indexing
- Context-aware code generation
- Dependency tracking
- Style consistency with existing code

### 💬 Conversational Interface
- Multi-turn conversations with AI
- Context memory across requests
- AI-initiated questions for clarification
- Cursor-like chat interface

### 🚀 Automatic Project Setup
- Zero-configuration installation
- Automatic file copying to new projects
- Seamless integration with Godot Editor

## 📋 Requirements

- **Godot Engine 4.x** (source code)
- **Claude API Key** from Anthropic (https://console.anthropic.com/)
- **Python 3.x** (for SCons build system)
- **C++ Compiler** (MSVC on Windows, GCC/Clang on Linux/macOS)
- **SCons** build system (`pip install scons`)

## 🛠️ Building DotAI

### Windows

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/dotai.git
   cd dotai
   ```

2. **Install dependencies:**
   ```bash
   pip install scons
   ```

3. **Build the editor:**
   ```bash
   scons platform=windows target=editor -j8
   ```
   
   The `-j8` flag uses 8 parallel jobs (adjust based on your CPU cores).

4. **Run the editor:**
   ```bash
   bin\godot.windows.editor.x86_64.exe
   ```

### Linux

```bash
scons platform=linuxbsd target=editor -j8
bin/godot.linuxbsd.editor.x86_64
```

### macOS

```bash
scons platform=macos target=editor -j8
bin/godot.macos.editor.universal
```

## 🚀 Quick Start

### 1. Build DotAI

Follow the build instructions above for your platform.

### 2. Open/Create a Godot Project

- Open an existing project or create a new one
- DotAI will automatically set up required files on first launch

### 3. Access DotAI Panel

- In the Godot Editor, look for the **"DotAI"** dock panel (usually on the right side)
- If not visible, go to **Editor → Editor Layout → Default** or check **View → Docks**

### 4. Configure API Key

**API key is required!** Enter your Claude API key in the DotAI panel:
- Open the DotAI dock panel
- Enter your API key in the "API Key" field
- Get your API key from: https://console.anthropic.com/

### 5. Start Building!

Type a prompt like:
```
Create a 2D platformer game with a player that can jump and move left/right
```

The AI will:
1. Generate complete, production-ready code
2. Create all necessary files (scripts, scenes, resources)
3. Automatically save them to your project
4. Display the generated code in the conversation

## 📁 Project Structure

```
godot/
├── modules/
│   └── claude_ai/              # DotAI module
│       ├── editor/             # C++ Editor Plugin
│       │   ├── claude_ai_editor_plugin.cpp
│       │   ├── claude_ai_editor_plugin.h
│       │   └── ai_studio_main_ui.*
│       ├── claude_api_handler.gd      # API communication
│       ├── codebase_scanner.gd        # Project scanning
│       ├── file_writer.gd             # File creation
│       ├── conversation_manager.gd     # Conversation history
│       ├── dependency_graph.gd        # Dependency analysis
│       ├── multi_model_handler.gd     # Multi-provider support
│       ├── resource_generator.gd      # Resource file generation
│       ├── code_analyzer.gd           # Code analysis & refactoring
│       ├── visual_scripting.gd        # Visual scripting support
│       ├── template_library.gd         # Template system
│       ├── ai_debugger.gd             # AI-powered debugging
│       ├── image_to_code.gd           # Image to code conversion
│       ├── code_reviewer.gd           # Code review system
│       ├── smart_refactorer.gd        # Smart refactoring
│       ├── test_generator.gd          # Test generation
│       ├── documentation_generator.gd # Documentation generation
│       ├── performance_profiler.gd    # Performance profiling
│       ├── multi_language_support.gd  # Multi-language support
│       ├── plugin_system.gd           # Plugin architecture
│       ├── version_control.gd         # Git integration
│       ├── collaboration.gd           # Real-time collaboration
│       ├── model_training.gd          # Model training
│       ├── scene_analyzer.gd          # Advanced scene analysis
│       ├── shader_generator.gd        # Shader generation
│       ├── animation_generator.gd     # Animation generation
│       ├── register_types.*           # Module registration
│       ├── SCsub                       # Build script
│       └── README.md                   # Detailed documentation
├── bin/                        # Built executables
└── README.md                   # This file
```

## 🎯 How It Works

### Architecture Overview

1. **C++ Editor Plugin** - Integrates DotAI into Godot Editor, provides UI dock panel
2. **API Handler** - Communicates with Claude AI API, builds prompts with codebase context
3. **Codebase Scanner** - Scans project files, extracts code structure and dependencies
4. **File Writer** - Parses AI responses, extracts code blocks, creates files
5. **Conversation Manager** - Maintains conversation history and context

### Workflow

```
User Prompt → API Handler → Claude AI API
                ↓
         AI Response (code + explanation)
                ↓
         File Writer (parse & extract)
                ↓
         File System (create files)
                ↓
         Editor Refresh (show in project)
```

## 📝 Usage Examples

### Example 1: Create a Player Character

**Prompt:**
```
Create a 2D player character that can move left/right with arrow keys and jump with spacebar
```

**Result:**
- `scripts/player.gd` - Player movement script
- `scenes/player.tscn` - Player scene with sprite and collision
- Complete, production-ready code with proper physics

### Example 2: Build a Complete Game System

**Prompt:**
```
Create a complete inventory system with items, UI display, and drag-and-drop functionality
```

**Result:**
- `scripts/inventory/inventory.gd` - Core inventory logic
- `scripts/inventory/item.gd` - Item data structure
- `scripts/ui/inventory_ui.gd` - UI controller
- `scenes/ui/inventory_panel.tscn` - UI scene
- All files properly connected and ready to use

### Example 3: Use Templates

**GDScript:**
```gdscript
# Apply a template
var result = TemplateLibrary.apply_template("2d_platformer", "res://")
print("Created files: ", result.files_created)
```

### Example 4: Analyze Code Quality

**GDScript:**
```gdscript
# Analyze a file
var analysis = CodeAnalyzer.analyze_file("res://scripts/player.gd")
print("Code quality score: ", analysis.score)
print("Suggestions: ", analysis.suggestions)

# Analyze entire project
var project_analysis = CodeAnalyzer.analyze_project()
print("Average code quality: ", project_analysis.average_score)
```

### Example 5: Use Dependency Graph

**GDScript:**
```gdscript
# Build dependency graph
DependencyGraph.build_graph("res://")

# Get affected files
var affected = DependencyGraph.get_affected_files("res://scripts/player.gd")

# Visualize graph
var visualization = DependencyGraph.get_graph_visualization()
print(visualization)
```

### Example 6: Switch AI Providers

**GDScript:**
```gdscript
# Use GPT-4 instead of Claude
multi_model_handler.set_provider(MultiModelHandler.Provider.OPENAI_GPT4, api_key)
multi_model_handler.send_request(params)

# Use local Ollama model
multi_model_handler.set_provider(MultiModelHandler.Provider.OLLAMA_LOCAL)
multi_model_handler.send_request(params)
```

### Example 3: Use Templates

**GDScript:**
```gdscript
# Apply a template
var result = TemplateLibrary.apply_template("2d_platformer", "res://")
print("Created files: ", result.files_created)
```

### Example 4: Analyze Code Quality

**GDScript:**
```gdscript
# Analyze a file
var analysis = CodeAnalyzer.analyze_file("res://scripts/player.gd")
print("Code quality score: ", analysis.score)
print("Suggestions: ", analysis.suggestions)

# Analyze entire project
var project_analysis = CodeAnalyzer.analyze_project()
print("Average code quality: ", project_analysis.average_score)
```

### Example 5: Use Dependency Graph

**GDScript:**
```gdscript
# Build dependency graph
DependencyGraph.build_graph("res://")

# Get affected files
var affected = DependencyGraph.get_affected_files("res://scripts/player.gd")

# Visualize graph
var visualization = DependencyGraph.get_graph_visualization()
print(visualization)
```

### Example 6: Switch AI Providers

**GDScript:**
```gdscript
# Use GPT-4 instead of Claude
multi_model_handler.set_provider(MultiModelHandler.Provider.OPENAI_GPT4, api_key)
multi_model_handler.send_request(params)

# Use local Ollama model
multi_model_handler.set_provider(MultiModelHandler.Provider.OLLAMA_LOCAL)
multi_model_handler.send_request(params)
```

## 🐛 Troubleshooting

### "API handler script not found"

**Solution:** DotAI automatically copies required files to `res://addons/claude_ai/` on first launch. If this fails, manually create the directory and copy files from `modules/claude_ai/`.

### "No code to save" error

**Solution:** 
1. Check the Output panel (View → Output) for debug messages
2. Ensure your prompt includes code generation requests
3. Try being more specific: "Create a script that..." instead of just "How do I..."

### Build Errors

**Common issues:**
- **Missing SCons:** `pip install scons`
- **Wrong directory:** Run build from Godot source root (where `SConstruct` is)
- **Compiler not found:** Install Visual Studio Build Tools (Windows) or build-essential (Linux)

## 📖 Documentation

For detailed documentation, see:
- **[modules/claude_ai/README.md](modules/claude_ai/README.md)** - Complete DotAI documentation
- **[Godot Engine Documentation](https://docs.godotengine.org/)** - Godot Engine reference

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is built on Godot Engine, which is licensed under the MIT License. DotAI-specific code follows the same license.

## 🙏 Acknowledgments

- **Godot Engine** - The amazing open-source game engine
- **Anthropic** - Claude AI API
- **Godot Community** - For inspiration and support

## 🗺️ Roadmap

### ✅ Completed Features

- [x] Enhanced codebase understanding with dependency graphs
- [x] Scene file generation (.tscn) support improvements
- [x] Resource file generation (.tres) support improvements
- [x] Multi-model support (GPT-4, GPT-3.5, Claude, Ollama)
- [x] Offline mode with local models (Ollama integration)
- [x] Code refactoring and optimization suggestions
- [x] Visual scripting integration
- [x] Template library for common game patterns

### 🚀 Recently Completed Features

- [x] **AI-Powered Debugging**: Automatic bug detection and fix suggestions
- [x] **Code Generation from Images**: Convert screenshots/mockups to code
- [x] **Interactive Code Reviews**: AI reviews code changes and suggests improvements
- [x] **Smart Refactoring**: Automated refactoring with AI assistance
- [x] **Test Generation**: Auto-generate unit tests for your code
- [x] **Documentation Generator**: Auto-generate API documentation from code
- [x] **Performance Profiling**: AI-powered performance analysis and optimization
- [x] **Multi-language Support**: Support for C# and other Godot-supported languages
- [x] **Plugin System**: Extensible plugin architecture for custom AI features
- [x] **Version Control Integration**: AI-assisted git operations and commit messages
- [x] **Real-time Collaboration**: Multi-user AI-assisted development
- [x] **Custom Model Training**: Train models on your specific codebase patterns
- [x] **Advanced Scene Analysis**: Deep analysis of scene structure and optimization
- [x] **Shader Generation**: AI-powered shader code generation
- [x] **Animation System**: AI-assisted animation and tween creation

### 🔮 Future Features

### 💡 Future Ideas

- [ ] **Voice Commands**: Control DotAI with voice input
- [ ] **AR/VR Support**: AI assistance for AR/VR game development
- [ ] **Mobile Development**: Enhanced mobile game development features
- [ ] **Export Optimization**: AI-powered export settings optimization
- [ ] **Asset Generation**: AI-generated sprites, sounds, and other assets
- [ ] **Game Design Assistant**: AI helps with game design and mechanics
- [ ] **Localization Tools**: AI-powered translation and localization
- [ ] **Accessibility Features**: AI-assisted accessibility improvements

## ✨ Recently Completed Features

### 🔗 Enhanced Dependency Graph Analysis
- **Dependency Visualization**: Visualize code dependencies across your entire project
- **Circular Dependency Detection**: Automatically detect and warn about circular dependencies
- **Impact Analysis**: See which files are affected when you modify a file
- **Graph Statistics**: Get insights into your project's dependency structure

### 🎨 Improved Scene & Resource Generation
- **Enhanced .tscn Parsing**: Better scene file generation with proper node hierarchies
- **Resource File Support**: Full support for .tres resource file generation
- **Automatic Resource Creation**: Generate resources directly from AI responses

### 🤖 Multi-Model Support
- **Multiple AI Providers**: Support for Claude (Anthropic), GPT-4, GPT-3.5, and local models
- **Easy Provider Switching**: Switch between AI providers without changing code
- **Unified API**: Same interface for all providers

### 🏠 Offline Mode with Local Models
- **Ollama Integration**: Use local models via Ollama for offline development
- **Privacy-First**: Keep your code private with local model inference
- **No API Costs**: Develop without API usage when using local models

### 🔍 Code Analysis & Refactoring
- **Code Quality Analysis**: Automatic code quality scoring and issue detection
- **Performance Suggestions**: Get optimization recommendations for your code
- **Refactoring Opportunities**: Identify code that can be improved
- **Best Practices**: Suggestions for following Godot and GDScript best practices

### 📊 Visual Scripting Integration
- **Visual Script Analysis**: Analyze and understand visual scripts
- **Conversion Tools**: Convert between visual scripts and GDScript
- **Integration Support**: Work seamlessly with Godot's visual scripting system

### 📚 Template Library
- **Pre-built Templates**: Common game patterns ready to use
- **2D Platformer**: Complete platformer template with player, enemies, and mechanics
- **Top-Down Shooter**: Shooter template with movement and shooting
- **Inventory System**: Full inventory system with UI support
- **State Machine**: Generic state machine pattern
- **Game Manager**: Singleton game manager template
- **Easy Application**: Apply templates with a single function call

---

**Built with ❤️ for game developers who want to focus on creativity, not syntax.**

For more information, visit the [DotAI module documentation](modules/claude_ai/README.md).
