# 02 – Basic UI with Teatro

Template-first workflow: `setup.sh` scaffolds a minimal Swift package from the FountainAI monorepo; build and run locally to explore the concept. This tutorial uses the `ai` profile by default to include FountainAI client libraries.

Modify the scaffolded user interface using FountainAI’s Teatro DSL. This tutorial operates on a minimal SPM app; `setup.sh` wraps the upstream FountainAI scripts and copies generated files locally. You don’t need to run the full Gateway/services for this lesson.

## Before you begin
- Install the Tutor CLI and add to PATH (see docs/tutor-cli.md and docs/shells-and-git.md):
  - `Scripts/install-tutor.sh`
  - `export PATH=$HOME/.local/bin:$PATH` (add via `~/.zshrc` on macOS)
- Run all commands from `tutorials/02-basic-ui-teatro/`.
- If needed, make the script executable:
  ```bash
  chmod +x setup.sh
  ```

## 1. Scaffold the project
Run the setup script, which generates a minimal local Swift package in this folder:

```bash
./setup.sh
```

Advanced: `./setup.sh --upstream` (or `SETUP_MODE=upstream ./setup.sh`) attempts to scaffold via the upstream monorepo and copy its generated files here; falls back to local if it fails.

Expected: `MainScene.teatro` appears alongside Swift sources. Open the folder in Xcode with `xed .` (macOS) or your editor of choice.

## 2. Define the interface
Open `MainScene.teatro` and add components. Teatro uses a declarative syntax:

```teatro
Stage {
  Scene {
    Text("Welcome to Teatro")
    Button("Tap Me") { emit("tapped") }
  }
}
```

## 3. Respond to user interaction
Handlers listen for events emitted from the interface:

```teatro
on("tapped") {
  print("Button was tapped")
}
```

When you press the button, the handler runs and prints to the console.

## 4. Build and run
Compile the project and launch the generated SwiftUI app:

```bash
../../tools/tutor-cli/.build/release/tutor-cli build
../../tools/tutor-cli/.build/release/tutor-cli run
```

Expected: A window appears with “Welcome to Teatro” and a “Tap Me” button. Tapping the button prints “Button was tapped” in the console.

## 5. Run tests
Execute the unit tests:

```bash
../../tools/tutor-cli/.build/release/tutor-cli test
```
Expected: Tests pass. Add tests for any helpers you extract from the UI logic.

Tip (macOS app bundle): If you’re working inside the FountainAI monorepo, you can bundle a GUI target with `Scripts/make_app.sh <Name>` and open `dist/<Name>.app`.

## Troubleshooting
- Permission denied: `chmod +x setup.sh` and re-run.
- No `MainScene.teatro`: re-run `./setup.sh` to regenerate files.
- Build errors: ensure Swift 6.1+ is installed and re-check with `swift --version`.

## Next steps
Continue to [03 – Data Persistence with FountainStore](../03-data-persistence-fountainstore/README.md) to save and load data from disk.

## See also
- [Deep dive: Dependency management with SwiftPM and profiles](../../docs/dependency-management-deep-dive.md)
