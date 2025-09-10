# Screenplay Editor Capstone

This capstone combines UI, persistence, multimedia, and AI features to form a simple screenplay editor.

## Setup
Run the setup script, which uses the FountainAI app-creation template from the [the-fountainai](https://github.com/Fountain-Coach/the-fountainai) repo:

```bash
./setup.sh
```

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
swift build
swift run
```
