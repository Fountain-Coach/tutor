# 01 – Hello Csound

Template-first workflow: `setup.sh` scaffolds a minimal Swift package from the FountainAI monorepo; build and run locally to explore the concept. This tutorial introduces a tiny `.csd` score and a `CsoundPlayer` utility to simulate synthesized audio.

> **No Binary Assets:** only the text-based `hello.csd` file is bundled. Generated audio samples remain in memory and are not committed.

## Before You Begin
- Install the Tutor CLI and add to PATH (see docs/tutor-cli.md and docs/shells-and-git.md):
  - `Scripts/install-tutor.sh`
  - `export PATH=$HOME/.local/bin:$PATH` (add via `~/.zshrc` on macOS)
- Run all commands from `tutorials/01-hello-csound/`.
- If needed, make the script executable:
  ```bash
  chmod +x setup.sh
  ```

## 1. Scaffold the Project
Run the setup script, which generates a minimal local Swift package in this folder and copies the `hello.csd` score:

```bash
./setup.sh
```

Expected: `Sources/HelloCsound/hello.csd`, `CsoundPlayer.swift`, and `main.swift` appear. Open the folder in Xcode with `xed .` (macOS) or your editor of choice.

## 2. Generate a Tone
`CsoundPlayer` loads the bundled `hello.csd` and produces a short sine wave:

```swift
let samples = try CsoundPlayer().play()
print("Generated sample count: \(samples.count)")
```

## 3. Build and Run
Compile the project and launch the program:

```bash
tutor build
tutor run
```

Expected: The console prints the generated sample count.

## 4. Run Tests
Execute the unit tests:

```bash
tutor test
```

Expected: Tests pass, confirming `CsoundPlayer` loads `hello.csd` without error.

## Synthesized Playback Diagram
```
hello.csd ──▶ CsoundPlayer.play() ──▶ [sine wave samples]
```

## Troubleshooting
- Permission denied: `chmod +x setup.sh` and re-run.
- `hello.csd not found`: re-run `./setup.sh` to restore the score file.
- Build errors: ensure Swift 6.1+ is installed and re-check with `swift --version`.

## Next Steps
Continue to [02 – Hello FountainAI](../01-hello-fountainai/README.md) to explore a SwiftUI greeting.

## See Also
- [Dependency Management Deep Dive](../../docs/dependency-management-deep-dive.md)
