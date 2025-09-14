# 06 – Screenplay Editor Capstone

Template-first workflow: `setup.sh` scaffolds a minimal Swift package from the FountainAI monorepo; build and run locally to explore the concept.

Combine UI (Teatro), persistence (FountainStore), multimedia (MIDI2), and AI (OpenAPI) into a simple screenplay editor. This capstone still uses the template-driven SPM workflow; no full platform services are required, though AI calls can target a local or hosted gateway.

## Before you begin
- Install Tutor CLI and add to PATH (see docs/tutor-cli.md and docs/shells-and-git.md).
- Run all commands from `tutorials/06-screenplay-editor-capstone/`.
- If needed, make the script executable:
  ```bash
  chmod +x setup.sh
  ```

## Setup
By default this tutorial uses the `ai` profile. To include AI + persistence + MIDI2 libraries all together, use the `capstone` profile:

```bash
./setup.sh --profile capstone --upstream
```

Advanced: `./setup.sh --upstream` (or `SETUP_MODE=upstream ./setup.sh`) attempts to scaffold via the upstream monorepo and copy its generated files here; falls back to local if it fails.

## UI with Teatro
The interface layout is defined in [MainScene.teatro](./MainScene.teatro). Buttons emit events that trigger saving notes, playing cues, and requesting AI help.

## Persistence with FountainStore
[NoteStore.swift](./NoteStore.swift) stores notes on disk using `FountainStore`. The UI calls `save` when the `save-note` event fires.

## Multimedia with MIDI2
[CuePlayer.ts](./CuePlayer.ts) loads [cue.mid](./cue.mid) and plays it back. During playback it can publish position updates for the UI.

## AI Assistance via OpenAPI
[AIClient.swift](./AIClient.swift) wraps the FountainAI `/v1/generate` endpoint. The `ask-ai` event sends a prompt and returns generated text.

## Integration Points
- `MainScene.teatro` emits `save-note`, `play-cue`, and `ask-ai` events.
- `NoteStore.swift` persists text when `save-note` occurs.
- `CuePlayer.ts` handles `play-cue` and updates the interface with timing data.
- `AIClient.swift` processes `ask-ai` and its results can be stored via the note store.

For a detailed end-to-end build, consult the [PDF guide](./Building%20a%20macOS%20Screenplay%20Editor%20with%20Teatro%2C%20FountainAI%2C%20and%20MIDI2.pdf).

## Build and run
Compile and launch the project:

```bash
tutor build
tutor run
```

Expected: The GUI shows a main scene with buttons to save notes, play a cue, and request AI help. Console logs reflect events and actions.

Tip (macOS app bundle): Inside the FountainAI monorepo, you can bundle with `Scripts/make_app.sh ScreenplayEditor` and open `dist/ScreenplayEditor.app`.

## Troubleshooting
- Permission denied: `chmod +x setup.sh` and re-run.
- MIDI not playing: verify `cue.mid` path and audio permissions.
- AI errors: confirm `FOUNTAIN_AI_KEY`/`LLM_GATEWAY_URL` are set and reachable.

## Run tests
```bash
tutor test
```
Add tests for persistence helpers, cue timing calculations, and any model-formatting logic.

## Next steps
Explore deeper integration in the upstream monorepo (Gateway plugins, persistence services) or extend the editor with scenes, formatting, and export.

## See also
- [Deep dive: Dependency management with SwiftPM and profiles](../../docs/dependency-management-deep-dive.md)
