# 04 – Multimedia with MIDI2

Template-first workflow: `setup.sh` scaffolds a minimal Swift package from the FountainAI monorepo; build and run locally to explore the concept.

Play audio and synchronize your UI using MIDI 2.0 timing. This lesson shows TypeScript snippets for a browser/Node context; your minimal Swift package scaffolding is for project structure only and does not execute the TS directly.

## Before you begin
- Run all commands from `tutorials/04-multimedia-midi2/`.
- If needed, make the script executable:
  ```bash
  chmod +x setup.sh
  ```

## Scaffold the project
Run the setup script, which generates a minimal local Swift package in this folder:

```bash
./setup.sh
```

Advanced: `./setup.sh --upstream` (or `SETUP_MODE=upstream ./setup.sh`) attempts to scaffold via the upstream monorepo and copy its generated files here; falls back to local if it fails.

## Playing audio (TypeScript)

Load a MIDI file and route it into an `AudioContext`. The player will handle decoding and playback once `play()` is called:

```ts
import { Midi2Player } from '@fountainlabs/midi2';

const context = new AudioContext();
const player = new Midi2Player({ context });

await player.load('/assets/cue.mid');
player.play();
```

## Synchronizing UI via MIDI2 (TypeScript)

During playback, the player emits timing information that can drive interface updates. Listen for `position` events to keep the UI in sync with the audio:

```ts
player.on('position', (seconds) => {
  document.querySelector('#time').textContent = seconds.toFixed(1);
});
```

## Play/Pause controls (HTML + TypeScript)

Hook simple controls into the player with standard DOM events:

```html
<button id="play">Play</button>
<button id="pause">Pause</button>
<script type="module">
  import { Midi2Player } from '@fountainlabs/midi2';

  const context = new AudioContext();
  const player = new Midi2Player({ context });
  await player.load('/assets/cue.mid');

  document.getElementById('play').addEventListener('click', () => player.play());
  document.getElementById('pause').addEventListener('click', () => player.pause());
</script>
```

These snippets demonstrate how audio playback and UI synchronization can be achieved using MIDI 2.0. Use a simple static server or bundler to run them.

## Build and run (Swift package)
Compile and launch the minimal Swift package (for structure only):

```bash
swift build
swift run
```

Expected: Swift package builds successfully. The MIDI2 examples run in a browser or Node environment.

## Run tests
```bash
swift test
```
Keep Swift tests focused on any local helpers; test TS code with your chosen runner (e.g., Vitest) in a separate step.

## Troubleshooting
- AudioContext blocked: user gesture may be required before playback in some browsers.
- Asset path: ensure `cue.mid` resolves (serve from `/assets/` or adjust `load()` path).
- TypeScript types: install `@types/node` or browser typings if bundling for the web.

## Next steps
Proceed to [05 – AI Integration with OpenAPI](../05-ai-integration-openapi/README.md) to call AI endpoints.
