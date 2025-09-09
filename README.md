# FountainAI Tutorials

A comprehensive collection of tutorials demonstrating how to build applications using the **FountainAI ecosystem** with a consistent, template-driven approach. Each tutorial showcases the same powerful technology stack and scaffolding methodology, making it easy to learn and build upon established patterns.

## 🎯 Our Philosophy: Template-First Development

These tutorials follow a **template-first approach** that emphasizes rapid development through scaffolding and consistent architectural patterns. Rather than starting from scratch each time, you'll learn to:

- **Start with Templates**: Use FountainAI's scaffolding scripts to generate new applications with pre-configured components
- **Build Upon Patterns**: Customize and extend proven architectural patterns rather than reinventing the wheel
- **Leverage AI Assistance**: Integrate AI-driven code generation (Codex) within established frameworks
- **Maintain Consistency**: Use the same core technology stack across all projects for better learning transfer

## 🛠️ The Consistent Technology Stack

Every tutorial in this repository demonstrates applications built with the same foundational components:

- **[Teatro](https://github.com/Fountain-Coach/Teatro)** - A declarative view engine with its own DSL for rendering content and timeline animations
- **[FountainAI & FountainStore](https://github.com/Fountain-Coach/the-fountainai)** - Local AI-backed system and embedded database for content management and metadata
- **[MIDI2](https://github.com/Fountain-Coach/midi2)** - MIDI 2.0 library for coordinating audio tracks and multimedia playback
- **Swift/SwiftUI** - Modern Swift development with SwiftUI for native macOS applications
- **Codex Integration** - AI-assisted code generation for rapid development

## 🚀 Getting Started with the Template Approach

Each tutorial demonstrates two pathways to building applications:

### 1. Quick Scaffold Method (Recommended)
```bash
# Clone the FountainAI monorepo
git clone https://github.com/Fountain-Coach/the-fountainai.git
cd the-fountainai

# Generate a new app using the scaffold script
bash Scripts/new-gui-app.sh YourAppName

# Build and run
swift build --product YourAppName
bash Scripts/make_app.sh YourAppName
open dist/YourAppName.app
```

### 2. Manual Swift Package Setup
```bash
# Initialize a new Swift package
swift package init --type=executable

# Add the core dependencies to Package.swift
# - Teatro for UI rendering
# - FountainStore for persistence  
# - MIDI2 for multimedia
# - FountainAI components for AI integration
```

## 📚 Available Tutorials

### [Building a macOS Screenplay Editor](./Building-A-Mac-Screenplay-Editor/)
A comprehensive tutorial showing how to create a screenplay editor that combines text-based screenwriting with multimedia playback. This tutorial demonstrates:

- **Template Usage**: Starting with FountainAI's GUI scaffolding
- **UI Development**: Building interfaces with Teatro's declarative DSL
- **Data Persistence**: Managing screenplay content with FountainStore
- **Multimedia Integration**: Synchronizing audio playback with MIDI2
- **AI-Assisted Development**: Using Codex for code generation
- **From Scaffold to Customization**: Transforming template code into a specialized application

*Perfect for learning the complete development workflow from template to finished application.*

## 🎯 Learning Outcomes

By following these tutorials, you'll master:

- **Rapid Prototyping**: How to quickly bootstrap new applications using proven templates
- **Consistent Architecture**: Building applications that follow established patterns and conventions
- **AI-Enhanced Development**: Integrating AI assistance into your development workflow
- **Cross-Domain Applications**: Applying the same stack to different problem domains
- **Modern Swift Development**: Using SwiftPM, command-line tools, and avoiding Xcode dependency

## 🔄 The Template Development Cycle

1. **Scaffold**: Start with a generated template using FountainAI scripts
2. **Customize**: Adapt the template UI and logic for your specific use case  
3. **Enhance**: Add domain-specific features using the established patterns
4. **Iterate**: Use AI assistance (Codex) to accelerate development within the framework
5. **Deploy**: Build and package using SwiftPM and bundling scripts

## 🌟 Why This Approach Works

- **Faster Learning**: Focus on application logic rather than boilerplate setup
- **Consistency**: Every project uses familiar patterns and tools
- **Scalability**: Templates provide a solid foundation for complex applications
- **Community**: Shared patterns make it easier to collaborate and share knowledge
- **AI-Ready**: Templates are designed to work seamlessly with AI code generation

## 📖 Prerequisites

- Swift 6.1+ installed with Swift Package Manager
- macOS 14+ (required for Teatro's full SwiftUI support)
- Basic familiarity with Swift and SwiftUI concepts
- Optional: OpenAI API key for AI-assisted development features

## 🤝 Contributing

Each tutorial is designed to be self-contained while demonstrating the consistent template approach. When contributing new tutorials:

1. Use the FountainAI scaffold as your starting point
2. Document both the template usage and customization steps
3. Maintain consistency with the established technology stack
4. Include examples of AI-assisted development where appropriate

---

*Ready to start building? Choose a tutorial above and experience the power of template-driven development with the FountainAI ecosystem!*