# FountainAI Tutorials Repository

**Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

## Repository Overview
This is a **documentation and tutorials repository** for the FountainAI ecosystem. It contains tutorials, guides, and examples for building Swift/SwiftUI applications using FountainAI's template-driven approach with Teatro, FountainStore, MIDI2, and other components.

**CRITICAL**: This repository does NOT contain buildable applications itself - it documents how to build applications using external FountainAI tools and templates.

## Working Effectively

### Prerequisites and Environment Setup
- Swift 6.1+ is already installed and available at `/usr/local/bin/swift`
- Swift Package Manager is included with Swift toolchain
- macOS 14+ is referenced in docs but Linux environment works for basic Swift operations
- No additional SDK downloads required for basic Swift development

### What You CAN Do in This Repository
- Read and edit documentation files (README.md, tutorials)
- Create and test basic Swift packages for experimentation: 
  ```bash
  swift package init --type=executable --name TestProject
  swift build  # Takes 2 seconds. NEVER CANCEL.
  swift run    # Takes 1 second. NEVER CANCEL.
  ```
- Edit and validate Markdown documentation
- Test Swift syntax and basic functionality

### What You CANNOT Do in This Repository
- Build actual FountainAI applications (requires external repositories)
- Run the scaffolding scripts mentioned in README (they exist in external repo with build issues)
- Test complete Teatro/FountainAI workflows (external dependencies have compatibility issues)
- Run GUI applications (would require macOS environment)

### External Dependencies and Limitations
- **Main FountainAI Repository**: `https://github.com/Fountain-Coach/the-fountainai.git`
  - Contains the actual scaffolding scripts and buildable components
  - **LIMITATION**: Currently has URLSession compatibility issues on Linux
  - **BUILD FAILURE**: `swift build` fails with "type 'URLSession' has no member 'shared'" error
  - **TIMEOUT WARNING**: If attempting builds, expect 10+ minutes before failure. NEVER CANCEL during dependency resolution.

### Repository Structure

Tutorial content lives under the `tutorials/` directory.
PDF resources, such as comprehensive guides, reside at the repository root.
Run `ls` or `find` to discover current tutorials.

## Validation and Testing

### Basic Swift Validation (Always Works)
Test basic Swift functionality with these validated commands:
```bash
# Create test package (1 second)
swift package init --type=executable --name ValidationTest

# Build test package (2 seconds, NEVER CANCEL)
swift build

# Run test package (1 second)  
swift run

# Clean up
rm -rf ValidationTest Package.swift Sources/
```

### Documentation Validation
- Always validate Markdown syntax in README.md after changes
- Verify all links in documentation are accessible
- Check that tutorial references match actual file locations

### What to Test After Making Changes
1. **Documentation Changes**: Verify Markdown renders correctly and links work
2. **Tutorial Updates**: Ensure referenced external repositories and commands are still valid
3. **Code Examples**: Test any Swift code snippets in documentation with basic `swift build` validation

## Common Tasks and Patterns

### Adding New Tutorial Content
- Follow the template-driven approach documented in README.md
- Reference external FountainAI repositories for actual implementation
- Include validation steps and limitations clearly
- Document build times and timeout requirements

### Updating Instructions
- Test any new commands thoroughly before documenting
- Include explicit timeout warnings for operations taking >2 minutes
- Document both working and non-working scenarios clearly
- Maintain imperative tone: "Run this", "Do not do that"

### Working with External Examples
- Always note that examples require external repository setup
- Document current limitation with URLSession compatibility
- Provide alternative approaches when main workflow fails

## Frequently Encountered Issues

### "URLSession compatibility error"
- **Issue**: External FountainAI repo fails to build on Linux
- **Workaround**: Document the limitation; focus on tutorial content rather than actual builds
- **Do NOT**: Attempt to fix external repository issues

### "Scaffolding script syntax errors"  
- **Issue**: awk syntax errors in `new-gui-app.sh` script
- **Workaround**: Document manual package creation as alternative
- **Do NOT**: Modify external repository scripts

### "Long dependency resolution"
- **Expected**: Swift package dependency resolution takes 5-15 minutes
- **Action**: Set timeout to 20+ minutes, NEVER CANCEL
- **Documentation**: Always warn about expected duration

## Quick Reference Commands

### Repository Exploration
```bash
# List all documentation files
find . -name "*.md" -o -name "*.pdf" | head -10

# Check repository status
git status

# View repository structure  
ls -la
```

### Swift Development (When Applicable)
```bash
# Swift version check
swift --version

# Create minimal package for testing
swift package init --type=executable --name Test

# Basic build (2 seconds max, NEVER CANCEL)
swift build

# Run executable (1 second max)
swift run
```

### External Repository Reference (Use with Caution)
```bash
# Clone external repo to /tmp for reference only (2 seconds)
cd /tmp && git clone https://github.com/Fountain-Coach/the-fountainai.git

# View external scripts (but expect build failures)
ls /tmp/the-fountainai/Scripts/

# Attempting swift build will fail after ~60 seconds with URLSession errors
```

**Remember**: This repository is about documenting and teaching FountainAI development workflows, not implementing them directly. Focus on clear, accurate documentation that acknowledges current limitations while providing practical guidance for developers wanting to learn the FountainAI ecosystem.