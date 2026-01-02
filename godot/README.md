# DotAI

An AI assistant for Godot that actually writes your game code. Tell it what you want, and it generates complete, working games.

## What is DotAI?

DotAI is a Godot editor plugin that connects to AI models (Claude, GPT-4, Ollama) to generate game code from natural language. Instead of writing GDScript yourself, you describe what you want and DotAI creates the files for you.

Key capabilities:
- Generate complete game systems from descriptions
- Automatically create and save files to your project
- Understands your existing codebase and maintains consistency
- Supports multiple AI providers (Claude, OpenAI, local models)
- Works directly in the Godot editor

## Features

- **Code generation**: Converts natural language to GDScript, scenes, and resources
- **File management**: Automatically creates and saves files to your project
- **Codebase awareness**: Scans your project to understand context and maintain style
- **Multi-provider support**: Works with Claude, GPT-4, GPT-3.5, or local Ollama models
- **Conversation history**: Maintains context across multiple requests
- **Dependency tracking**: Understands relationships between files

## Requirements

- **Godot Engine 4.x** (source code)
- **Claude API Key** from Anthropic (https://console.anthropic.com/)
- **Python 3.x** (for SCons build system)
- **C++ Compiler** (MSVC on Windows, GCC/Clang on Linux/macOS)
- **SCons** build system (`pip install scons`)

## Building DotAI

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

## Quick Start

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

## How It Works

DotAI consists of a C++ editor plugin that provides the UI, and GDScript modules that handle:
- API communication with AI providers
- Project scanning and codebase analysis
- Parsing AI responses and extracting code
- File creation and project integration
- Conversation history management

When you send a prompt, DotAI scans your project for context, sends an enhanced prompt to the AI, then parses the response to extract and save generated files.

## Usage Examples

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

## Troubleshooting

**"API handler script not found"**: DotAI copies required files to `res://addons/claude_ai/` on first launch. If this fails, manually create the directory and copy files from `modules/claude_ai/`.

**"No code to save" error**: Check the Output panel for debug messages. Make sure your prompt requests code generation (e.g., "Create a script that...").

**Build errors**: 
- Missing SCons: `pip install scons`
- Wrong directory: Run build from Godot source root (where `SConstruct` is)
- Compiler not found: Install Visual Studio Build Tools (Windows) or build-essential (Linux)

## Documentation

See [modules/claude_ai/README.md](modules/claude_ai/README.md) for detailed documentation.

## Contributing

Contributions welcome. Fork, create a feature branch, and open a pull request.

## License

MIT License (same as Godot Engine).

## Roadmap

### Completed Features

- Enhanced codebase understanding with dependency graphs
- Scene (.tscn) and resource (.tres) file generation
- Multi-model support (GPT-4, GPT-3.5, Claude, Ollama)
- Offline mode with local models
- Code refactoring and optimization suggestions
- Visual scripting integration
- Template library for common game patterns
- AI-powered debugging
- Code generation from images
- Interactive code reviews
- Smart refactoring
- Test generation
- Documentation generation
- Performance profiling
- Multi-language support (C#, GDScript)
- Plugin system architecture
- Version control integration
- Real-time collaboration
- Custom model training
- Advanced scene analysis
- Shader generation
- Animation system assistance

### Future Ideas

- Voice commands for controlling DotAI
- AR/VR development assistance
- Mobile game development features
- Export settings optimization
- AI-generated assets (sprites, sounds)
- Game design assistance
- Localization tools
- Accessibility improvements

## Completed Features

- Dependency graph analysis and visualization
- Scene (.tscn) and resource (.tres) file generation
- Multi-model support (Claude, GPT-4, GPT-3.5, Ollama)
- Offline mode with local models
- Code analysis and refactoring suggestions
- Visual scripting integration
- Template library for common game patterns
- AI-powered debugging
- Code generation from images
- Interactive code reviews
- Smart refactoring
- Test generation
- Documentation generation
- Performance profiling
- Multi-language support (C#, GDScript)
- Plugin system architecture
- Version control integration
- Real-time collaboration
- Custom model training
- Advanced scene analysis
- Shader generation
- Animation system assistance

For detailed documentation, see [modules/claude_ai/README.md](modules/claude_ai/README.md).
